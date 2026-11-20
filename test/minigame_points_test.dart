import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/data/minigame_progress.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/screens/shop_screen.dart';

import 'minigame_screen_test.dart' as mg;

final en = mg.en;

/// One challenge of each of the 4 types, with code the test's pretend
/// Python knows.
final quiz = mg.quiz('pq');
final fill = Challenge.fillBlank(
  id: 'pf',
  title: (_) => 'Fill',
  prompt: (_) => 'Make it print 2',
  hints: [(_) => 'h1', (_) => 'h2'],
  template: 'print(1 $blankMarker 1)',
  solution: '+',
  tests: const [
    TestCase(output: ['2']),
  ],
);
final fix = Challenge.fixBug(
  id: 'px',
  title: (_) => 'Fix',
  prompt: (_) => 'Fix it so it prints 5.',
  hints: [(_) => 'h1', (_) => 'h2'],
  starter: 'speed = 5\nprint(Speed)',
  solution: 'speed = 5\nprint(speed)',
  tests: const [
    TestCase(output: ['5']),
  ],
);
final write = Challenge.writeCode(
  id: 'pw',
  title: (_) => 'Write',
  prompt: (_) => 'Print 1 + 1.',
  hints: [(_) => 'h1', (_) => 'h2'],
  solution: 'print(1 + 1)',
  tests: const [
    TestCase(output: ['2']),
  ],
);
final testLevel = [
  MinigameLevel(number: 1, challenges: [quiz, fill, fix, write]),
];

Future<int> points() async => (await SettingsController.load()).shop.points;

Future<void> solve(WidgetTester tester, Challenge c) async {
  switch (c.type) {
    case ChallengeType.quiz:
      await mg.tapAndSettle(tester, mg.answer('yes'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
    case ChallengeType.fillBlank:
      await tester.enterText(mg.key('mg-blank'), '+');
      await tester.pumpAndSettle();
      await mg.tapAndSettle(tester, mg.key('mg-run'));
    case ChallengeType.fixBug || ChallengeType.writeCode:
      await tester.enterText(mg.key('mg-code'), c.solution);
      await tester.pumpAndSettle();
      await mg.tapAndSettle(tester, mg.key('mg-run'));
  }
}

void main() {
  group('Every challenge type earns Star Points', () {
    for (final c in [quiz, fill, fix, write]) {
      testWidgets('${c.type.name}: first solve doubled, replay normal, the '
          'record stays', (tester) async {
        final (progress, _) = await mg.pumpMap(tester, levels: testLevel);
        await mg.openChallenge(tester, c.id);
        await solve(tester, c);
        expect(progress.bestStars(c.id), 3);
        expect(await points(), 6); // 3 stars, doubled
        expect(find.text(en.mgPlusPoints(6)), findsOneWidget);
        expect(find.text(en.pointsDoubled), findsOneWidget);

        await mg.goBack(tester); // back to the level
        await mg.tapAndSettle(tester, mg.key('mg-challenge-${c.id}'));
        await solve(tester, c);
        expect(await points(), 9); // + 3, not doubled
        expect(find.text(en.mgPlusPoints(3)), findsOneWidget);
        expect(find.text(en.pointsDoubled), findsNothing);
        expect(
          find.textContaining('${en.recordKept} ${en.pointsEarned(3)}'),
          findsOneWidget,
        );
        expect(progress.bestStars(c.id), 3);
      });
    }

    testWidgets('hints lower the stars, so the points too (1 star = 2 '
        'points the first time)', (tester) async {
      final (progress, _) = await mg.pumpMap(tester, levels: testLevel);
      await mg.openChallenge(tester, 'pw');
      await mg.tapAndSettle(tester, mg.key('mg-hint'));
      await mg.tapAndSettle(tester, mg.key('mg-hint'));
      await solve(tester, write);
      expect(progress.bestStars('pw'), 1);
      expect(await points(), 2);
    });

    testWidgets('a wrong run or a quit challenge earns nothing', (
      tester,
    ) async {
      await mg.pumpMap(tester, levels: testLevel);
      await mg.openChallenge(tester, 'px');
      await mg.tapAndSettle(tester, mg.key('mg-run')); // the buggy code
      expect(find.byKey(const ValueKey('mg-points')), findsNothing);
      await mg.goBack(tester); // quit
      expect(await points(), 0);
    });

    test('a 0-star run is worth 0 points', () async {
      SharedPreferences.setMockInitialValues({});
      final shop = (await SettingsController.load()).shop;
      expect(shop.earnRun(0, first: true), 0);
      expect(shop.points, 0);
    });
  });

  group('Level bonus', () {
    /// Level 1 with challenges 2 to 10 already solved.
    final nineSolved = <String, Object>{
      for (var c = 2; c <= 10; c++) 'minigame.stars.mgL1C$c': 1,
    };

    testWidgets('finishing all 10 challenges of a level gives +10 once', (
      tester,
    ) async {
      final (progress, _) = await mg.pumpMap(tester, saved: nineSolved);
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(await points(), 6 + MinigameProgress.levelBonusPoints);
      expect(find.text(en.mgLevelBonus(1, 10)), findsOneWidget);
      expect(progress.levelBonusGiven(minigameLevels.first), isTrue);

      // A replay: points again, but never the bonus again.
      await mg.goBack(tester);
      await mg.tapAndSettle(tester, mg.key('mg-challenge-mgL1C1'));
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(await points(), 16 + 3);
      expect(find.byKey(const ValueKey('mg-level-bonus')), findsNothing);
    });

    test('the bonus is saved and can never be given twice', () async {
      SharedPreferences.setMockInitialValues({
        ...mg.allLessonsDone,
        for (var c = 1; c <= 10; c++) 'minigame.stars.mgL1C$c': 1,
      });
      final progress = await MinigameProgress.load();
      final level = minigameLevels.first;
      expect(progress.levelComplete(level), isTrue);
      expect(await progress.claimLevelBonus(level), isTrue);
      expect(await progress.claimLevelBonus(level), isFalse);
      final again = await MinigameProgress.load();
      expect(again.levelBonusGiven(level), isTrue);
      expect(await again.claimLevelBonus(level), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('minigame.levelBonus.L1'), isTrue);
    });

    test(
      'no bonus while a challenge has no star, or for a short level',
      () async {
        SharedPreferences.setMockInitialValues({
          for (var c = 1; c <= 9; c++) 'minigame.stars.mgL1C$c': 3,
        });
        final progress = await MinigameProgress.load();
        expect(await progress.claimLevelBonus(minigameLevels.first), isFalse);
        expect(await progress.claimLevelBonus(testLevel.first), isFalse);
      },
    );

    test('the bonus never changes stars or records', () async {
      SharedPreferences.setMockInitialValues({
        for (var c = 1; c <= 10; c++) 'minigame.stars.mgL1C$c': 2,
      });
      final progress = await MinigameProgress.load();
      await progress.claimLevelBonus(minigameLevels.first);
      expect(progress.levelStars(minigameLevels.first), 20);
    });
  });

  group('The map shows the points', () {
    for (final lang in ['en', 'tl']) {
      testWidgets('$lang: a points counter on the MINIGAME map', (
        tester,
      ) async {
        final l10n = lang == 'en' ? mg.en : mg.tl;
        await mg.pumpMap(tester, lang: lang, saved: {'shop.points': 12});
        expect(find.byType(PointsChip), findsOneWidget);
        expect(find.text(l10n.shopPoints(12)), findsOneWidget);
      });
    }

    testWidgets('the counter goes up after a solve', (tester) async {
      await mg.pumpMap(tester);
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      await mg.goBack(tester); // level
      await mg.goBack(tester); // map
      expect(find.text(en.shopPoints(6)), findsOneWidget);
    });

    testWidgets('360x640, Tagalog, big text: the result with points and '
        'bonus fits', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await mg.pumpMap(
        tester,
        lang: 'tl',
        size: const Size(360, 640),
        saved: {
          for (var c = 2; c <= 10; c++) 'minigame.stars.mgL1C$c': 1,
          'settings.textSize': 'large',
        },
      );
      expect(tester.takeException(), isNull);
      for (final k in ['mg-level-1', 'mg-challenge-mgL1C1']) {
        await tester.scrollUntilVisible(
          mg.key(k),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await mg.tapAndSettle(tester, mg.key(k));
      }
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      await tester.ensureVisible(find.byKey(const ValueKey('mg-level-bonus')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
