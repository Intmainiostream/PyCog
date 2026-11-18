import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/models/minigame.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// Longest code line that fits a 360px phone.
const maxCodeLine = 28;

/// Longest fill-the-blank choice (a chip).
const maxChoice = 24;

final allChallenges = [for (final level in minigameLevels) ...level.challenges];

void main() {
  test('10 levels, numbered 1 to 10, at most 10 challenges each', () {
    expect(minigameLevels.map((l) => l.number), [
      for (var n = 1; n <= 10; n++) n,
    ]);
    for (final level in minigameLevels) {
      expect(level.challenges.length, lessThanOrEqualTo(challengesPerLevel));
    }
  });

  test('ids are mgL<level>C<number> and never repeat', () {
    for (final level in minigameLevels) {
      for (final (i, challenge) in level.challenges.indexed) {
        expect(challenge.id, 'mgL${level.number}C${i + 1}');
      }
    }
    final ids = allChallenges.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Level 1 has the 3 samples: a quiz, a fill the blank, a write it', () {
    expect(minigameLevels.first.challenges.map((c) => c.type), [
      ChallengeType.quiz,
      ChallengeType.fillBlank,
      ChallengeType.writeCode,
    ]);
  });

  test('every text exists in English and Tagalog', () {
    for (final c in allChallenges) {
      for (final l10n in [en, tl]) {
        expect(c.title(l10n).trim(), isNotEmpty, reason: c.id);
        expect(c.prompt(l10n).trim(), isNotEmpty, reason: c.id);
        // Quizzes have no hints; the other types have exactly 2.
        expect(
          c.hints,
          hasLength(c.type == ChallengeType.quiz ? 0 : hintsPerChallenge),
          reason: c.id,
        );
        for (final hint in c.hints) {
          expect(hint(l10n).trim(), isNotEmpty, reason: c.id);
        }
      }
      // A translation, not a copy (titles may share code words, so only
      // prompts are compared).
      expect(c.prompt(en), isNot(c.prompt(tl)), reason: c.id);
    }
  });

  test('quizzes have exactly one right answer', () {
    for (final c in allChallenges.where((c) => c.type == ChallengeType.quiz)) {
      expect(c.answers.where((a) => a.correct), hasLength(1), reason: c.id);
      expect(c.tests, isEmpty, reason: c.id);
    }
  });

  test('code challenges have hidden tests and a solution', () {
    for (final c in allChallenges.where((c) => c.runsCode)) {
      expect(c.tests, isNotEmpty, reason: c.id);
      expect(c.solution.trim(), isNotEmpty, reason: c.id);
      for (final t in c.tests) {
        expect(t.output, isNotEmpty, reason: c.id);
        // Every typed answer appears in the expected output (the output
        // shows it like a terminal).
        for (final answer in t.inputs) {
          expect(
            t.output.any((line) => line.endsWith(answer)),
            isTrue,
            reason: '${c.id}: typed "$answer" is missing from the output',
          );
        }
      }
    }
  });

  test('fill the blank: one blank, and the solution is a choice', () {
    for (final c in allChallenges.where(
      (c) => c.type == ChallengeType.fillBlank,
    )) {
      expect(blankMarker.allMatches(c.template), hasLength(1), reason: c.id);
      if (c.choices.isNotEmpty) {
        expect(c.choices, contains(c.solution), reason: c.id);
        expect(c.choices.toSet(), hasLength(c.choices.length), reason: c.id);
      }
      expect(c.solutionProgram, isNot(contains(blankMarker)), reason: c.id);
    }
  });

  test('fix the bug starts with code that is not the solution', () {
    for (final c in allChallenges.where(
      (c) => c.type == ChallengeType.fixBug,
    )) {
      expect(c.starter.trim(), isNotEmpty, reason: c.id);
      expect(c.starter, isNot(c.solution), reason: c.id);
    }
  });

  test('code, outputs and choices fit a 360px phone', () {
    for (final c in allChallenges) {
      final code = [
        for (final line in c.code) line.code,
        ...c.template.split('\n'),
        ...c.starter.split('\n'),
        ...c.solutionProgram.split('\n'),
        for (final t in c.tests) ...t.output,
      ];
      for (final line in code) {
        expect(
          line.length,
          lessThanOrEqualTo(maxCodeLine),
          reason: '${c.id}: "$line" is too wide',
        );
      }
      for (final choice in c.choices) {
        expect(choice.length, lessThanOrEqualTo(maxChoice), reason: c.id);
      }
    }
  });
}
