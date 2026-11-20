import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/minigame_progress.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/models/quiz.dart';

/// A pretend challenge (only its id matters here).
Challenge fake(String id) => Challenge.writeCode(
  id: id,
  title: (_) => id,
  prompt: (_) => id,
  hints: [(_) => '', (_) => ''],
  solution: 'print(1)',
  tests: const [
    TestCase(output: ['1']),
  ],
);

/// Three full levels of 10 pretend challenges: L1C1 ... L3C10.
final levels = [
  for (var l = 1; l <= 3; l++)
    MinigameLevel(
      number: l,
      challenges: [for (var c = 1; c <= 10; c++) fake('L${l}C$c')],
    ),
];

/// Saved stars for the first [count] challenges of level [level].
Map<String, Object> solved(int level, int count, {int stars = 1}) => {
  for (var c = 1; c <= count; c++) 'minigame.stars.L${level}C$c': stars,
};

/// Saved data for: every Play lesson finished (each level also needs its
/// lesson; these tests are about the star rule).
final allLessonsDone = <String, Object>{
  for (final lesson in lessons) 'progress.stars.${lesson.id}': 1,
};

Future<MinigameProgress> loadWith(
  Map<String, Object> saved, {
  bool lessonsDone = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (lessonsDone) ...allLessonsDone,
    ...saved,
  });
  return MinigameProgress.load();
}

void main() {
  group('Star rules', () {
    test('no hints = 3 stars, one hint = 2, two or more = 1', () {
      expect(starsForHints(0), 3);
      expect(starsForHints(1), 2);
      expect(starsForHints(2), 1);
      expect(starsForHints(5), 1);
    });

    test('every code challenge has exactly 2 hints', () {
      expect(hintsPerChallenge, 2);
      // Using all the hints still earns a star.
      expect(starsForHints(hintsPerChallenge), 1);
    });

    test('quiz: first try = 3, second = 2, any later try = 1', () {
      expect(starsForWrongPicks(0), 3);
      expect(starsForWrongPicks(1), 2);
      expect(starsForWrongPicks(2), 1);
      expect(starsForWrongPicks(3), 1);
      expect(starsForWrongPicks(9), 1);
    });

    test('a quiz counts wrong picks; the other types count hints', () {
      final quiz = Challenge.quiz(
        id: 'q',
        title: (_) => '',
        prompt: (_) => '',
        answers: [
          QuizAnswer(label: (_) => 'a', correct: true),
          QuizAnswer(label: (_) => 'b'),
        ],
      );
      expect(quiz.hints, isEmpty);
      expect(starsFor(quiz, wrongPicks: 1), 2);
      expect(starsFor(quiz, hintsUsed: 2), 3); // hints don't count
      final code = fake('c');
      expect(starsFor(code, hintsUsed: 1), 2);
      expect(starsFor(code, wrongPicks: 2), 3); // wrong picks don't count
    });
  });

  group('Saved hints and wrong picks', () {
    test('opened hints are saved on the phone and never go down', () async {
      final progress = await loadWith({});
      expect(progress.hintsUsed('L1C1'), 0);
      await progress.saveHintsUsed('L1C1', 1);
      expect(progress.hintsUsed('L1C1'), 1);
      await progress.saveHintsUsed('L1C1', 0);
      expect(progress.hintsUsed('L1C1'), 1);
      await progress.saveHintsUsed('L1C1', 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame.hints.L1C1'), 2);
    });

    test(
      'saved hints and wrong picks are there after the app opens again',
      () async {
        final progress = await loadWith({
          'minigame.hints.L1C2': 1,
          'minigame.wrong.L1C1': ['0', '2'],
        });
        expect(progress.hintsUsed('L1C2'), 1);
        expect(progress.wrongPicks('L1C1'), {0, 2});
      },
    );

    test('each wrong quiz pick is added to the saved ones', () async {
      final progress = await loadWith({});
      expect(progress.wrongPicks('L1C1'), isEmpty);
      await progress.saveWrongPick('L1C1', 2);
      await progress.saveWrongPick('L1C1', 0);
      await progress.saveWrongPick('L1C1', 2); // same pick again
      expect(progress.wrongPicks('L1C1'), {0, 2});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('minigame.wrong.L1C1'), ['0', '2']);
    });

    test(
      'finishing clears hints and wrong picks, but keeps the stars',
      () async {
        final progress = await loadWith({
          'minigame.stars.L1C1': 3,
          'minigame.hints.L1C1': 2,
          'minigame.wrong.L1C1': ['1'],
        });
        await progress.clearAttempt('L1C1');
        expect(progress.hintsUsed('L1C1'), 0);
        expect(progress.wrongPicks('L1C1'), isEmpty);
        expect(progress.bestStars('L1C1'), 3);
      },
    );

    test('opened hints never change the best stars', () async {
      final progress = await loadWith({'minigame.stars.L1C1': 3});
      await progress.saveHintsUsed('L1C1', 2);
      expect(progress.bestStars('L1C1'), 3);
      // Solving now is worth 1 star: the best stays 3.
      expect(await progress.saveStars('L1C1', starsForHints(2)), isFalse);
      expect(progress.bestStars('L1C1'), 3);
    });

    test('one challenge does not touch another', () async {
      final progress = await loadWith({});
      await progress.saveHintsUsed('L1C1', 1);
      await progress.saveWrongPick('L1C2', 0);
      await progress.clearAttempt('L1C3');
      expect(progress.hintsUsed('L1C1'), 1);
      expect(progress.wrongPicks('L1C2'), {0});
      expect(progress.hintsUsed('L1C2'), 0);
    });
  });

  group('Level unlock rule', () {
    test('at the start only Level 1 is open', () async {
      final progress = await loadWith({});
      expect(progress.unlockedCount(levels), 1);
    });

    test('7 of 10 challenges with a star open the next level', () async {
      final progress = await loadWith(solved(1, 7));
      expect(progress.solvedCount(levels[0]), 7);
      expect(progress.unlockedCount(levels), 2);
    });

    test('6 of 10 is not enough', () async {
      final progress = await loadWith(solved(1, 6, stars: 3));
      expect(progress.unlockedCount(levels), 1);
    });

    test('1 star each is enough; 3 stars each also works', () async {
      expect((await loadWith(solved(1, 7))).unlockedCount(levels), 2);
      expect((await loadWith(solved(1, 7, stars: 3))).unlockedCount(levels), 2);
    });

    test('levels open one after another', () async {
      final progress = await loadWith({...solved(1, 10), ...solved(2, 7)});
      expect(progress.unlockedCount(levels), 3);
    });

    test('stars in a later level never skip a locked one', () async {
      // Level 2 is full of stars, but Level 1 has only 6: Level 2 and 3
      // stay locked.
      final progress = await loadWith({...solved(1, 6), ...solved(2, 10)});
      expect(progress.unlockedCount(levels), 1);
    });

    test('a level with fewer than 7 challenges cannot open the next', () async {
      final short = [
        MinigameLevel(number: 1, challenges: [fake('a'), fake('b')]),
        MinigameLevel(number: 2, challenges: [fake('c')]),
      ];
      final progress = await loadWith({
        'minigame.stars.a': 3,
        'minigame.stars.b': 3,
      });
      expect(progress.unlockedCount(short), 1);
    });

    test('the unlock rule numbers are 7 of 10', () {
      expect(challengesToUnlockNext, 7);
      expect(challengesPerLevel, 10);
    });
  });

  group('Saved progress', () {
    test('stars are saved on the phone, one key per challenge', () async {
      final progress = await loadWith({});
      expect(progress.bestStars('L1C1'), 0);
      expect(await progress.saveStars('L1C1', 2), isTrue);
      expect(progress.bestStars('L1C1'), 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame.stars.L1C1'), 2);
    });

    test('saved stars are there after the app opens again', () async {
      // As if the app was closed and opened: a fresh load reads the phone.
      final progress = await loadWith({'minigame.stars.L1C3': 3});
      expect(progress.bestStars('L1C3'), 3);
      expect(progress.levelStars(levels[0]), 3);
      expect(progress.solvedCount(levels[0]), 1);
    });

    test('the first solve is the permanent record: replays never change '
        'it', () async {
      final progress = await loadWith({'minigame.stars.L1C1': 2});
      expect(await progress.saveStars('L1C1', 1), isFalse); // worse
      expect(await progress.saveStars('L1C1', 3), isFalse); // better
      expect(progress.bestStars('L1C1'), 2);
    });

    test('saving tells listeners (the map redraws)', () async {
      final progress = await loadWith({});
      var calls = 0;
      progress.addListener(() => calls++);
      await progress.saveStars('L1C1', 1);
      await progress.saveStars('L1C1', 1); // not better: no redraw
      expect(calls, 1);
    });

    test('level stars add up the best stars of its challenges', () async {
      final progress = await loadWith({
        'minigame.stars.L1C1': 3,
        'minigame.stars.L1C2': 1,
        'minigame.stars.L2C1': 2,
      });
      expect(progress.levelStars(levels[0]), 4);
      expect(progress.levelStars(levels[1]), 2);
    });

    test('MINIGAME keys do not touch lesson progress keys', () async {
      final progress = await loadWith({'progress.stars.variables': 3});
      await progress.saveStars('L1C1', 3);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('progress.stars.variables'), 3);
    });
  });
}
