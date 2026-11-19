import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/minigame/output_checker.dart';
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

  test('Level 1 is full: 10 challenges, 3 quizzes, 2 fill, 2 fix, 3 write', () {
    final level1 = minigameLevels.first.challenges;
    expect(level1.map((c) => c.type), [
      ChallengeType.quiz,
      ChallengeType.fillBlank,
      ChallengeType.writeCode,
      ChallengeType.quiz,
      ChallengeType.fillBlank,
      ChallengeType.fixBug,
      ChallengeType.quiz,
      ChallengeType.fixBug,
      ChallengeType.writeCode,
      ChallengeType.writeCode,
    ]);
    // One fill the blank is picked, the other is typed.
    final fills = level1.where((c) => c.type == ChallengeType.fillBlank);
    expect(fills.map((c) => c.choices.isNotEmpty), [true, false]);
  });

  test('Level 1 uses only Lesson 1 (variables), plus print()', () {
    for (final c in minigameLevels.first.challenges) {
      final code = [
        for (final line in c.code) line.code,
        for (final a in c.answers) a.label(en).replaceAll('`', ''),
        c.template,
        c.starter,
        c.solutionProgram,
        ...c.choices,
      ].join('\n');
      // print() is the only function.
      final calls = RegExp(r'(\w+)\(').allMatches(code).map((m) => m[1]);
      expect(calls.toSet().difference({'print'}), isEmpty, reason: c.id);
      // No math, lists, comparisons or later keywords.
      for (final later in ['+', '-', '*', '/', '[', '{', '<', '>', '==']) {
        expect(code, isNot(contains(later)), reason: '${c.id}: $later');
      }
      for (final word in ['if', 'else', 'for', 'while', 'def', 'and', 'or']) {
        expect(
          RegExp('\\b$word\\b').hasMatch(code),
          isFalse,
          reason: '${c.id}: $word',
        );
      }
    }
  });

  test('a challenge with input() says the exact question in both texts', () {
    for (final c in allChallenges) {
      final questions = RegExp(r'input\(("[^"]*")\)')
          .allMatches(c.solutionProgram)
          .map((m) => m[1]!);
      for (final q in questions) {
        for (final l10n in [en, tl]) {
          expect(
            c.prompt(l10n),
            contains('`input($q)`'),
            reason: '${c.id} must show `input($q)` in its text',
          );
        }
      }
    }
  });

  test('required code: only on fix/write, and the solution has it all', () {
    for (final c in allChallenges.where((c) => c.requiredCode.isNotEmpty)) {
      expect(c.type, isIn([ChallengeType.fixBug, ChallengeType.writeCode]));
      expect(
        missingCode(c.solutionProgram, c.requiredCode),
        isEmpty,
        reason: c.id,
      );
    }
  });

  test('required code only uses names the problem text gives', () {
    for (final c in allChallenges.where((c) => c.requiredCode.isNotEmpty)) {
      final names = {
        for (final piece in c.requiredCode)
          ...RegExp(r'[A-Za-z_]\w*').allMatches(piece).map((m) => m[0]!),
      }..remove('print');
      for (final name in names) {
        for (final l10n in [en, tl]) {
          expect(
            c.prompt(l10n),
            contains('`$name'),
            reason: '${c.id}: the text must name `$name`',
          );
        }
      }
    }
  });

  test('Level 1 write-it challenges: printing the answer does not pass', () {
    final writes = minigameLevels.first.challenges.where(
      (c) => c.type == ChallengeType.writeCode,
    );
    expect(writes.map((c) => c.id), ['mgL1C3', 'mgL1C9', 'mgL1C10']);
    for (final c in writes) {
      expect(c.requiredCode, isNotEmpty, reason: c.id);
      // e.g. print(5) for "5", print("Cog") for "Cog".
      final fixedAnswer = [
        for (final line in c.tests.first.output)
          int.tryParse(line) != null || line == 'True' || line == 'False'
              ? 'print($line)'
              : 'print("$line")',
      ].join('\n');
      expect(
        missingCode(fixedAnswer, c.requiredCode),
        isNotEmpty,
        reason: '${c.id}: $fixedAnswer must not pass',
      );
    }
  });

  test('fix and write challenges with input() have 2+ different tests', () {
    for (final c in allChallenges.where(
      (c) =>
          (c.type == ChallengeType.fixBug ||
              c.type == ChallengeType.writeCode) &&
          c.solutionProgram.contains('input('),
    )) {
      expect(c.tests.length, greaterThanOrEqualTo(2), reason: c.id);
      final inputs = c.tests.map((t) => t.inputs.join('\n')).toSet();
      expect(inputs.length, c.tests.length, reason: '${c.id}: same inputs');
    }
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
