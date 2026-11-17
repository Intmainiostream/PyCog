import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/models/match_game.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

final ifs = lessons[2];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

/// Works out what a chip like "battery < 20" really evaluates to, using the
/// round's setup lines like "battery = 10".
bool evaluate(GameRound round, String condition) {
  final values = {
    for (final line in round.setup)
      line.code.split('=').first.trim(): int.parse(line.code.split('=').last),
  };
  final m = RegExp(r'^(\w+) (==|!=|>=|<=|<|>) (\d+)$').firstMatch(condition)!;
  final left = values[m[1]]!;
  final right = int.parse(m[3]!);
  return switch (m[2]) {
    '==' => left == right,
    '!=' => left != right,
    '>=' => left >= right,
    '<=' => left <= right,
    '<' => left < right,
    _ => left > right,
  };
}

Widget app(SettingsController settings, Widget home) => ListenableBuilder(
  listenable: settings,
  builder: (context, _) => MaterialApp(
    theme: AppTheme.light,
    locale: settings.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ),
);

Future<(SettingsController, ProgressController)> pumpGame(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  Size size = const Size(800, 1000),
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues(saved);
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  await tester.pumpWidget(
    app(
      settings,
      GameScreen(
        lesson: ifs,
        lessonNumber: 3,
        settings: settings,
        progress: progress,
        random: math.Random(2),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, progress);
}

Future<void> dragChipToBox(WidgetTester tester, Finder from, Finder to) async {
  await tester.ensureVisible(to);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> tapPlace(
  WidgetTester tester,
  int round,
  String value,
  String to,
) async {
  await tester.ensureVisible(chip(round, value));
  await tester.tap(chip(round, value));
  await tester.pump();
  await tester.ensureVisible(box(round, to));
  await tester.pumpAndSettle();
  await tester.tap(box(round, to));
  await tester.pumpAndSettle();
}

/// Places every remaining chip of a round correctly, then taps Next.
Future<void> finishRound(WidgetTester tester, int r) async {
  for (final c in ifs.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == ifs.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 3 game data', () {
    test('3 rounds of True/False boxes, 4 chips, 2 per box, with setup', () {
      expect(ifs.game, hasLength(3));
      for (final round in ifs.game) {
        expect(round.boxes.map((b) => b.name), ['True', 'False']);
        expect(round.chips, hasLength(4));
        expect(round.chips.where((c) => c.box == 'True'), hasLength(2));
        expect(round.chips.where((c) => c.box == 'False'), hasLength(2));
        expect(round.setup, isNotEmpty);
        expect(round.chips.map((c) => c.value).toSet(), hasLength(4));
      }
    });

    test('every chip is in the box it really evaluates to', () {
      for (final round in ifs.game) {
        for (final c in round.chips) {
          expect(
            evaluate(round, c.value) ? 'True' : 'False',
            c.box,
            reason: '"${c.value}" with ${round.setup.map((l) => l.code)}',
          );
        }
      }
    });

    test('each round uses the operators asked for', () {
      String ops(GameRound r) => r.chips
          .map((c) => RegExp(r'(==|!=|>=|<=|<|>)').firstMatch(c.value)![0])
          .join(' ');
      expect(ops(ifs.game[0]).split(' ').toSet(), {'<', '>'});
      expect(ops(ifs.game[1]).split(' ').toSet(), {'==', '!='});
      final r3 = ifs.game[2];
      expect(ops(r3), allOf(contains('>='), contains('<='), contains('==')));
      // The edge case: >= and <= where the values are equal, both True.
      expect(r3.chips.firstWhere((c) => c.value == 'lives >= 3').box, 'True');
      expect(r3.chips.firstWhere((c) => c.value == 'score <= 100').box, 'True');
      // The close-looking == is False.
      final eq = r3.chips.firstWhere((c) => c.value.contains('=='));
      expect(eq.box, 'False');
    });

    test('Lessons 1 and 2 games have no setup and one value per box', () {
      for (final lesson in [lessons[0], lessons[1]]) {
        for (final round in lesson.game) {
          expect(round.setup, isEmpty);
          for (final b in round.boxes) {
            expect(round.chips.where((c) => c.box == b.name), hasLength(1));
          }
        }
      }
    });
  });

  testWidgets('Setup values show in a code box above the boxes', (
    tester,
  ) async {
    await pumpGame(tester);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('battery = 10', findRichText: true),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(CodeBox)).dy,
      lessThan(tester.getTopLeft(box(0, 'True')).dy),
    );
  });

  testWidgets('Correct drop: battery < 20 snaps into True', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'battery < 20'), box(0, 'True'));

    expect(textInBox(0, 'True', 'battery < 20'), findsOneWidget);
    expect(chip(0, 'battery < 20'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('A True box takes both of its chips, then is full', (
    tester,
  ) async {
    await pumpGame(tester);
    await tapPlace(tester, 0, 'battery < 20', 'True');
    await tapPlace(tester, 0, 'lives < 4', 'True');
    expect(textInBox(0, 'True', 'battery < 20'), findsOneWidget);
    expect(textInBox(0, 'True', 'lives < 4'), findsOneWidget);

    // Full now: dropping a False chip on it does nothing (no hint, no count).
    await dragChipToBox(tester, chip(0, 'lives > 5'), box(0, 'True'));
    expect(chip(0, 'lives > 5'), findsOneWidget);
    expect(find.text(en.game3R1Hint2), findsNothing);
  });

  testWidgets('Wrong drop bounces back; Cog explains why in one line', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'lives > 5'), box(0, 'True'));

    expect(chip(0, 'lives > 5'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'True', '?'), findsOneWidget); // still empty
    expect(find.text(en.game3R1Hint2), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, 'battery > 50', 'False');
    expect(textInBox(0, 'False', 'battery > 50'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game3R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('score = 100', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, 'lives > 5', 'True'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Hindi mas malaki', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(tl.game3R1Intro), findsOneWidget);
  });

  group('Stars', () {
    testWidgets('perfect: 3 bonus stars saved; unlocking unchanged', (
      tester,
    ) async {
      final (_, progress) = await pumpGame(tester);
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(3)), findsOneWidget);
      expect(progress.bestBonusStars('if_statements'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.if_statements': 2},
      );
      await tapPlace(tester, 0, 'battery < 20', 'False');
      await tapPlace(tester, 0, 'lives > 5', 'True');
      await tapPlace(tester, 0, 'battery > 50', 'True');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('if_statements'), 2);
    });
  });

  testWidgets('Lesson 3 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: ifs,
          lessonNumber: 3,
          stars: 3,
          isNewBest: true,
          unlockedLessonNumber: null,
          settings: settings,
          progress: await ProgressController.load(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.resultsPlayGame));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text(en.game3R1Intro), findsOneWidget);
  });

  // Small phones with the biggest text, both languages: no overflow, and
  // chips and boxes at least 48px tall.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('Round 3 fits | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await pumpGame(
          tester,
          size: size,
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var r = 0; r < 2; r++) {
          for (final c in ifs.game[r].chips) {
            await tapPlace(tester, r, c.value, c.box);
          }
          final next = find.text(l10n.gameNextRound);
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        for (final c in ifs.game[2].chips) {
          expect(
            tester.getSize(chip(2, c.value)).height,
            greaterThanOrEqualTo(48),
          );
        }
        for (final b in ['True', 'False']) {
          expect(tester.getSize(box(2, b)).height, greaterThanOrEqualTo(48));
        }
        // Fill round 3 (both boxes get 2 values) without overflow.
        for (final c in ifs.game[2].chips) {
          await tapPlace(tester, 2, c.value, c.box);
        }
        expect(find.text(l10n.gameSeeResults), findsOneWidget);
      });
    }
  }
}
