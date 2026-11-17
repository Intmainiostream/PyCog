import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/theme/app_theme.dart';

import 'test_helpers.dart';

final variables = lessons.first;
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));

/// Text inside a given box (e.g. the value that snapped in).
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

Future<(SettingsController, ProgressController)> pumpGame(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  await tester.pumpWidget(
    ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: GameScreen(
          lesson: variables,
          lessonNumber: 1,
          settings: settings,
          progress: progress,
          random: math.Random(3),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, progress);
}

/// Drags a chip onto a box with a real finger gesture.
Future<void> dragChipToBox(WidgetTester tester, Finder from, Finder to) async {
  await tester.ensureVisible(to);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -20)); // start the drag
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
  await tester.tap(box(round, to));
  await tester.pumpAndSettle();
}

/// Plays every round by tapping, making [wrongDrops] wrong tries first.
Future<void> playWholeGame(WidgetTester tester, {int wrongDrops = 0}) async {
  var wrongLeft = wrongDrops;
  for (var r = 0; r < variables.game.length; r++) {
    final round = variables.game[r];
    // Wrong tries first, while every box is still empty (a filled box
    // ignores taps, which would leave the chip selected).
    for (final c in round.chips) {
      if (wrongLeft == 0) break;
      final wrongBox = round.boxes.firstWhere((b) => b.name != c.box);
      await tapPlace(tester, r, c.value, wrongBox.name);
      wrongLeft--;
    }
    for (final c in round.chips) {
      await tapPlace(tester, r, c.value, c.box);
    }
    final last = r == variables.game.length - 1;
    await tester.tap(find.text(last ? en.gameSeeResults : en.gameNextRound));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('Correct drop snaps in, turns green, Cog cheers', (tester) async {
    await pumpGame(tester);

    await dragChipToBox(tester, chip(0, '80'), box(0, 'battery'));

    expect(textInBox(0, 'battery', '80'), findsOneWidget);
    expect(
      find.descendant(
        of: box(0, 'battery'),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(chip(0, '80'), findsNothing); // left the tray
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop bounces back and Cog gives a hint', (tester) async {
    await pumpGame(tester);

    await dragChipToBox(tester, chip(0, '"Cog"'), box(0, 'battery'));

    expect(chip(0, '"Cog"'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'battery', '?'), findsOneWidget); // box still empty
    expect(find.text(en.game1R1HintCog), findsOneWidget);
  });

  testWidgets('Tap a chip, then tap a box (backup for dragging)', (
    tester,
  ) async {
    await pumpGame(tester);

    // Tapping a box first just reminds the student what to do.
    await tester.tap(box(0, 'wheels'));
    await tester.pumpAndSettle();
    expect(find.text(en.gameTapValueFirst), findsOneWidget);

    await tapPlace(tester, 0, '4', 'wheels');
    expect(textInBox(0, 'wheels', '4'), findsOneWidget);
    expect(chip(0, '4'), findsNothing);

    // Wrong tap-placement counts the same as a wrong drop.
    await tapPlace(tester, 0, '"teal"', 'battery');
    expect(find.text(en.game1R1HintTeal), findsOneWidget);
    expect(chip(0, '"teal"'), findsOneWidget);
  });

  testWidgets('Round 3 twist: dropping 60 updates battery from 100', (
    tester,
  ) async {
    await pumpGame(tester);
    // Finish rounds 1 and 2.
    for (var r = 0; r < 2; r++) {
      for (final c in variables.game[r].chips) {
        await tapPlace(tester, r, c.value, c.box);
      }
      await tester.tap(find.text(en.gameNextRound));
      await tester.pumpAndSettle();
    }
    expect(textInBox(2, 'battery', '100'), findsOneWidget); // old value

    await dragChipToBox(tester, chip(2, '60'), box(2, 'battery'));

    expect(textInBox(2, 'battery', '60'), findsOneWidget);
    expect(textInBox(2, 'battery', '100'), findsOneWidget); // crossed out
  });

  testWidgets('Language switch updates the game immediately', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, '"Cog"', 'battery'); // wrong: hint shows

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();

    expect(find.text(tl.game1R1HintCog), findsOneWidget);
    expect(find.text(tl.gameInstructions), findsOneWidget);
    expect(chip(0, '"Cog"'), findsOneWidget); // same game state
  });

  group('Saved bonus stars', () {
    testWidgets('perfect game saves 3 bonus stars; unlocking unchanged', (
      tester,
    ) async {
      final (_, progress) = await pumpGame(tester);
      await playWholeGame(tester);

      expect(find.text(en.gameResultsTitle), findsOneWidget);
      expect(find.bySemanticsLabel(en.gameBonusStars(3)), findsOneWidget);
      expect(find.text(en.gameResults3Stars), findsOneWidget);
      expect(progress.bestBonusStars('variables'), 3);
      expect(progress.totalStars(lessons), 3);
      // Bonus stars never unlock lessons (no quiz stars yet -> only Lesson 1).
      expect(progress.unlockedCount(lessons), 1);

      final reloaded = await ProgressController.load();
      expect(reloaded.bestBonusStars('variables'), 3);
    });

    testWidgets('more wrong drops = fewer stars; the best is kept', (
      tester,
    ) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.variables': 2},
      );
      await playWholeGame(tester, wrongDrops: 3);

      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(find.text(en.gameResults1Star), findsOneWidget);
      expect(find.text(en.resultsNewBest), findsNothing);
      expect(progress.bestBonusStars('variables'), 2); // kept
    });

    testWidgets('home star counter adds quiz stars and bonus stars', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'progress.stars.variables': 2,
        'progress.bonus.variables': 3,
      });
      await tester.pumpWidget(
        PyCogApp(
          settings: await SettingsController.load(),
          progress: await ProgressController.load(),
        ),
      );
      await tester.pumpAndSettle();
      await openTrail(tester); // app opens on the home screen
      expect(find.bySemanticsLabel(en.starsCount(5)), findsOneWidget);
    });
  });
}
