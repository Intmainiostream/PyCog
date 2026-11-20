import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/data/minigame_progress.dart';
import 'package:pycog/screens/minigame_map_screen.dart';

import 'minigame_screen_test.dart' as mg;

/// Lesson [n]'s quiz finished (1 star).
Map<String, Object> lessonDone(int n) => {
  'progress.stars.${lessons[n - 1].id}': 1,
};

/// 7 challenges of Level [n] with a star.
Map<String, Object> sevenStars(int n) => {
  for (var c = 1; c <= 7; c++) 'minigame.stars.mgL${n}C$c': 1,
};

Future<MinigameProgress> load(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return MinigameProgress.load();
}

void main() {
  test('Level N goes with Lesson N', () {
    for (final level in minigameLevels) {
      expect(MinigameProgress.lessonIdFor(level), lessons[level.number - 1].id);
    }
    expect(MinigameProgress.lessonIdFor(minigameLevels.first), 'variables');
    expect(MinigameProgress.lessonIdFor(minigameLevels.last), 'logic');
  });

  group('A level needs BOTH its lesson and the stars', () {
    test('Level 1 needs Lesson 1 finished', () async {
      expect((await load({})).unlockedCount(minigameLevels), 0);
      expect((await load(lessonDone(1))).unlockedCount(minigameLevels), 1);
    });

    test('stars but no lesson: still locked', () async {
      final p = await load({...lessonDone(1), ...sevenStars(1)});
      expect(p.unlockedCount(minigameLevels), 1); // Level 2 locked
      final why = p.whyLocked(minigameLevels, 1);
      expect(why.needsLesson, isTrue);
      expect(why.needsStars, isFalse);
    });

    test('lesson but no stars: still locked', () async {
      final p = await load({...lessonDone(1), ...lessonDone(2)});
      expect(p.unlockedCount(minigameLevels), 1);
      final why = p.whyLocked(minigameLevels, 1);
      expect(why.needsLesson, isFalse);
      expect(why.needsStars, isTrue);
    });

    test('both: it opens', () async {
      final p = await load({
        ...lessonDone(1),
        ...lessonDone(2),
        ...sevenStars(1),
      });
      expect(p.unlockedCount(minigameLevels), 2);
    });

    test('neither: both reasons', () async {
      final p = await load(lessonDone(1));
      final why = p.whyLocked(minigameLevels, 2); // Level 3
      expect(why.needsLesson, isTrue);
      expect(why.needsStars, isTrue);
    });

    test('a level that was open before locks again without its lesson, '
        'and its saved stars stay', () async {
      // An older version: Levels 1 and 2 open, stars in both, but only
      // Lesson 1 finished in Play mode.
      final p = await load({
        ...lessonDone(1),
        ...sevenStars(1),
        'minigame.stars.mgL2C1': 3,
      });
      expect(p.unlockedCount(minigameLevels), 1);
      expect(p.bestStars('mgL2C1'), 3);
      expect(p.levelStars(minigameLevels[1]), 3);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame.stars.mgL2C1'), 3);
    });
  });

  group('The map says why', () {
    for (final lang in ['en', 'tl']) {
      testWidgets('$lang: a locked level shows which lesson to finish, and '
          'tapping it shows every reason without opening it', (tester) async {
        final l10n = lang == 'en' ? mg.en : mg.tl;
        await mg.pumpMap(
          tester,
          lang: lang,
          lessonsDone: false,
          saved: lessonDone(1),
        );
        expect(find.text(l10n.mgNeedLesson(2)), findsOneWidget);
        await mg.tapAndSettle(tester, mg.key('mg-level-2'));
        expect(find.byType(MinigameLevelScreen), findsNothing);
        expect(
          find.text('${l10n.mgNeedLesson(2)}\n${l10n.mgLevelLocked(1)}'),
          findsOneWidget,
        );
      });
    }

    testWidgets('a locked Level 1 says to finish Lesson 1 (no crash)', (
      tester,
    ) async {
      await mg.pumpMap(tester, lessonsDone: false);
      await mg.tapAndSettle(tester, mg.key('mg-level-1'));
      expect(find.byType(MinigameLevelScreen), findsNothing);
      expect(find.text(mg.en.mgNeedLesson(1)), findsWidgets);
    });

    testWidgets('only the stars missing: the star message only', (
      tester,
    ) async {
      await mg.pumpMap(
        tester,
        lessonsDone: false,
        saved: {...lessonDone(1), ...lessonDone(2)},
      );
      await mg.tapAndSettle(tester, mg.key('mg-level-2'));
      expect(find.text(mg.en.mgLevelLocked(1)), findsOneWidget);
      expect(find.text(mg.en.mgNeedLesson(2)), findsNothing);
    });

    testWidgets('with both, the level opens', (tester) async {
      await mg.pumpMap(
        tester,
        lessonsDone: false,
        saved: {...lessonDone(1), ...lessonDone(2), ...sevenStars(1)},
      );
      await mg.tapAndSettle(tester, mg.key('mg-level-2'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
    });

    testWidgets('360x640, Tagalog, big text: the locked reasons fit', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await mg.pumpMap(
        tester,
        lang: 'tl',
        size: const Size(360, 640),
        lessonsDone: false,
        saved: {...lessonDone(1), 'settings.textSize': 'large'},
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        mg.key('mg-level-2'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await mg.tapAndSettle(tester, mg.key('mg-level-2'));
      expect(tester.takeException(), isNull);
    });
  });
}
