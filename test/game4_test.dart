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

final loops = lessons[3];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

/// What Python's range really gives, e.g. "range(1, 4)" -> "1, 2, 3".
/// (Same rule as Python: start defaults to 0, stops BEFORE the end.)
String pythonRange(String box) {
  final nums = RegExp(r'\d+')
      .allMatches(box)
      .map((m) => int.parse(m[0]!))
      .toList();
  final (start, stop) = nums.length == 1 ? (0, nums[0]) : (nums[0], nums[1]);
  return [for (var n = start; n < stop; n++) n].join(', ');
}

/// How many numbers are inside range(...): 1 or 2.
int argCount(String box) => RegExp(r'\d+').allMatches(box).length;

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
        lesson: loops,
        lessonNumber: 4,
        settings: settings,
        progress: progress,
        random: math.Random(5),
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
  for (final c in loops.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == loops.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 4 game data', () {
    test('3 rounds of 4 boxes, one chip per box, no setup line', () {
      expect(loops.game, hasLength(3));
      for (final round in loops.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup, isEmpty);
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('every chip is exactly what Python\'s range gives for its box', () {
      for (final round in loops.game) {
        for (final c in round.chips) {
          expect(c.value, pythonRange(c.box), reason: c.box);
        }
        // No two boxes in a round give the same numbers (no ambiguity).
        final results = round.boxes.map((b) => pythonRange(b.name)).toSet();
        expect(results, hasLength(round.boxes.length));
      }
    });

    test('round rules: 1 number, then 2 numbers, then mixed', () {
      Set<int> args(GameRound r) =>
          r.boxes.map((b) => argCount(b.name)).toSet();
      expect(args(loops.game[0]), {1});
      expect(args(loops.game[1]), {2});
      expect(args(loops.game[2]), {1, 2});
      // The look-alike pair: range(3) and range(1, 4) are both in round 3,
      // both make 3 numbers, but different ones.
      final r3 = loops.game[2].boxes.map((b) => b.name);
      expect(r3, containsAll(['range(3)', 'range(1, 4)']));
      expect(pythonRange('range(3)').split(', '), hasLength(3));
      expect(pythonRange('range(1, 4)').split(', '), hasLength(3));
      expect(pythonRange('range(3)'), isNot(pythonRange('range(1, 4)')));
    });

    test('each hint\'s "starts at / ends at" is true for its chip', () {
      final starts = RegExp(r'starts at (\d+)');
      final ends = RegExp(r'ends at (\d+)');
      for (final round in loops.game) {
        for (final c in round.chips) {
          final hint = c.hint(en);
          final nums = c.value.split(', ').map(int.parse).toList();
          final s = starts.firstMatch(hint);
          final e = ends.firstMatch(hint);
          if (s != null) expect(int.parse(s[1]!), nums.first, reason: hint);
          if (e != null) expect(int.parse(e[1]!), nums.last, reason: hint);
          // The hint never names the answer box.
          expect(hint.contains(c.box), isFalse, reason: hint);
        }
      }
    });
  });

  testWidgets('Correct drop: 0, 1, 2 snaps into range(3)', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '0, 1, 2'), box(0, 'range(3)'));

    expect(textInBox(0, 'range(3)', '0, 1, 2'), findsOneWidget);
    expect(chip(0, '0, 1, 2'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop bounces back; Cog says range stops BEFORE', (
    tester,
  ) async {
    await pumpGame(tester);
    // The classic mistake: thinking range(4) gives 0, 1, 2, 3, 4.
    await dragChipToBox(tester, chip(0, '0, 1, 2, 3, 4'), box(0, 'range(4)'));

    expect(chip(0, '0, 1, 2, 3, 4'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'range(4)', '?'), findsOneWidget); // still empty
    expect(find.text(en.game4R1Hint2), findsOneWidget);
    expect(en.game4R1Hint2, contains('BEFORE'));
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, '0, 1', 'range(2)');
    expect(textInBox(0, 'range(2)', '0, 1'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game4R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game4R3Intro), findsOneWidget);
  });

  testWidgets('Look-alike pair: 1, 2, 3 in range(3) gets the start hint', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);

    await tapPlace(tester, 2, '1, 2, 3', 'range(3)');
    expect(find.text(en.game4R3Hint2), findsOneWidget); // "starts at 1, not 0"
    expect(chip(2, '1, 2, 3'), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, '0, 1, 2', 'range(5)'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.game4R1Hint1), findsOneWidget);
    expect(find.text(tl.game4R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('loops'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.loops': 2},
      );
      await tapPlace(tester, 0, '0, 1, 2', 'range(5)');
      await tapPlace(tester, 0, '0, 1, 2, 3, 4', 'range(4)');
      await tapPlace(tester, 0, '0, 1', 'range(3)');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('loops'), 2);
    });
  });

  testWidgets('Lesson 4 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: loops,
          lessonNumber: 4,
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
    expect(find.text(en.game4R1Intro), findsOneWidget);
  });

  // Small phones with the biggest text, both languages: no overflow, and
  // chips and boxes at least 48px tall (round 1 has the longest chip).
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All rounds fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await pumpGame(
          tester,
          size: size,
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var r = 0; r < 3; r++) {
          for (final c in loops.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in loops.game[r].chips) {
            await tapPlace(tester, r, c.value, c.box);
          }
          final button = find.text(
            r == 2 ? l10n.gameSeeResults : l10n.gameNextRound,
          );
          expect(button, findsOneWidget);
          if (r < 2) {
            await tester.ensureVisible(button);
            await tester.tap(button);
            await tester.pumpAndSettle();
          }
        }
      });
    }
  }
}
