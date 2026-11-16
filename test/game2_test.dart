import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';

final dataTypes = lessons[1];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

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
        lesson: dataTypes,
        lessonNumber: 2,
        settings: settings,
        progress: progress,
        random: math.Random(9),
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

/// Fills every remaining box of a round correctly (skipping chips already
/// placed), then taps Next / See results.
Future<void> finishRound(WidgetTester tester, int r) async {
  for (final c in dataTypes.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already in its box
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == dataTypes.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 2 game data', () {
    test('3 rounds; each has int, float, str, bool and one value per box', () {
      expect(dataTypes.game, hasLength(3));
      for (final round in dataTypes.game) {
        expect(round.boxes.map((b) => b.name), ['int', 'float', 'str', 'bool']);
        expect(round.chips, hasLength(4));
        expect(round.chips.map((c) => c.box).toSet(), {
          'int',
          'float',
          'str',
          'bool',
        });
        // Values are unique within a round (they're also the chip ids).
        expect(round.chips.map((c) => c.value).toSet(), hasLength(4));
      }
    });

    test('includes the tricky ones', () {
      final all = [for (final r in dataTypes.game) ...r.chips];
      String boxOf(String value) => all.firstWhere((c) => c.value == value).box;
      expect(boxOf('"5"'), 'str'); // quotes make it text
      expect(boxOf('0.5'), 'float'); // decimal point
      expect(boxOf('10.0'), 'float'); // .0 is still a float
      // Look-alikes in the same round: "True" is text, True is a bool.
      final r3 = dataTypes.game[2].chips;
      expect(r3.firstWhere((c) => c.value == '"True"').box, 'str');
      expect(r3.firstWhere((c) => c.value == 'True').box, 'bool');
    });

    test('Lesson 1 game is untouched', () {
      expect(lessons.first.game, hasLength(3));
      expect(lessons.first.game.first.boxes.first.name, 'robot_name');
    });
  });

  testWidgets('Correct label: 2.5 snaps into float, Cog cheers', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '2.5'), box(0, 'float'));

    expect(textInBox(0, 'float', '2.5'), findsOneWidget);
    expect(chip(0, '2.5'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong label: "5" in the int box bounces back with a hint', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0); // to round 2

    await dragChipToBox(tester, chip(1, '"5"'), box(1, 'int'));

    expect(chip(1, '"5"'), findsOneWidget); // back in the tray
    expect(textInBox(1, 'int', '?'), findsOneWidget); // still empty
    expect(find.text(en.game2R2HintStr), findsOneWidget);
  });

  testWidgets('Tap backup works, and round progress moves 1 → 2 → 3', (
    tester,
  ) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, '"Cog"', 'str');
    expect(textInBox(0, 'str', '"Cog"'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game2R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game2R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates the game text right away', (
    tester,
  ) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, '7', 'float'); // wrong: hint shows

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.game2R1HintInt), findsOneWidget);
    expect(find.text(tl.game2R1Intro), findsOneWidget);
  });

  group('Stars', () {
    testWidgets('perfect game: 3 bonus stars saved for Lesson 2 only', (
      tester,
    ) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.variables': 1},
      );
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }

      expect(find.bySemanticsLabel(en.gameBonusStars(3)), findsOneWidget);
      expect(progress.bestBonusStars('data_types'), 3);
      expect(progress.bestBonusStars('variables'), 1); // Lesson 1 unchanged
      expect(progress.totalStars(lessons), 4);
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.data_types': 2},
      );
      // Three wrong tries in round 1 while all boxes are empty.
      await tapPlace(tester, 0, '7', 'float');
      await tapPlace(tester, 0, '2.5', 'int');
      await tapPlace(tester, 0, '"Cog"', 'bool');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }

      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(find.text(en.resultsNewBest), findsNothing);
      expect(progress.bestBonusStars('data_types'), 2);
    });
  });

  testWidgets('Lesson 2 quiz results show "Play the game", which opens it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    final progress = await ProgressController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: dataTypes,
          lessonNumber: 2,
          stars: 2,
          isNewBest: true,
          unlockedLessonNumber: null,
          settings: settings,
          progress: progress,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.resultsPlayGame));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text(en.game2R1Intro), findsOneWidget);
  });

  // Small phones with the biggest text, both languages: no overflow, and
  // chips and boxes stay at least 48px tall.
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
          for (final c in dataTypes.game[r].chips) {
            await tapPlace(tester, r, c.value, c.box);
          }
          final next = find.text(l10n.gameNextRound);
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        for (final c in dataTypes.game[2].chips) {
          final size = tester.getSize(chip(2, c.value));
          expect(size.height, greaterThanOrEqualTo(48), reason: c.value);
          expect(
            tester.getSize(box(2, c.box)).height,
            greaterThanOrEqualTo(48),
          );
        }
      });
    }
  }
}
