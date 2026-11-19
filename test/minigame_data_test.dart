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

  // Levels 1-10 use the same mix, easy to harder.
  for (final number in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
    test('Level $number is full: 3 quizzes, 2 fill, 2 fix, 3 write', () {
      final challenges = minigameLevels[number - 1].challenges;
      expect(challenges.map((c) => c.type), [
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
      final fills = challenges.where((c) => c.type == ChallengeType.fillBlank);
      expect(fills.map((c) => c.choices.isNotEmpty), [true, false]);
    });
  }

  // What each level may use: the functions and ideas its lessons teach.
  // Anything not listed (math, lists, loops, functions, and/or/not,
  // input()...) is not allowed yet.
  const allowed = {
    // Lesson 1 (variables) + print()
    1: (calls: {'print'}, ideas: <String>{}),
    // + Lesson 2 (data types): type()
    2: (calls: {'print', 'type'}, ideas: <String>{}),
    // + Lesson 3 (if statements): if / elif / else and comparisons
    // (==, !=, <, >, <=, >=). No new functions.
    3: (
      calls: {'print', 'type'},
      ideas: {'if', 'elif', 'else', '<', '>', '=='},
    ),
    // + Lesson 4 (loops): range(), for, while, break, and `- 1` to change
    // the value a while loop checks.
    4: (
      calls: {'print', 'type', 'range'},
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
      },
    ),
    // + Lesson 5 (functions): def, return, and `a + b`. Calling a function
    // the code defines is allowed too (see below).
    5: (
      calls: {'print', 'type', 'range'},
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
      },
    ),
    // + Lesson 6 (math operators): * / // % ** (and += -=). No new
    // functions.
    6: (
      calls: {'print', 'type', 'range'},
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
        '*',
        '/',
        '%',
      },
    ),
    // + Lesson 7 (strings): len(), str(), .upper(), .lower(), and [ ] to
    // pick a letter.
    7: (
      calls: {'print', 'type', 'range', 'len', 'str', 'upper', 'lower'},
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
        '*',
        '/',
        '%',
        '[',
      },
    ),
    // + Lesson 8 (lists): .append(). Lists use [ ] (already allowed), and
    // `in` asks if an item is in a list.
    8: (
      calls: {
        'print',
        'type',
        'range',
        'len',
        'str',
        'upper',
        'lower',
        'append',
      },
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
        '*',
        '/',
        '%',
        '[',
      },
    ),
    // + Lesson 9 (input and output): input(), int() and float().
    9: (
      calls: {
        'print',
        'type',
        'range',
        'len',
        'str',
        'upper',
        'lower',
        'append',
        'input',
        'int',
        'float',
      },
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
        '*',
        '/',
        '%',
        '[',
        'input',
      },
    ),
    // + Lesson 10 (logic): and, or, not (and "between": 1 <= n <= 10,
    // which uses signs already allowed). No new functions.
    10: (
      calls: {
        'print',
        'type',
        'range',
        'len',
        'str',
        'upper',
        'lower',
        'append',
        'input',
        'int',
        'float',
      },
      ideas: {
        'if',
        'elif',
        'else',
        '<',
        '>',
        '==',
        'for',
        'while',
        'break',
        '-',
        'def',
        'return',
        '+',
        '*',
        '/',
        '%',
        '[',
        'input',
        'and',
        'or',
        'not',
      },
    ),
  };
  const laterSymbols = ['+', '-', '*', '/', '%', '[', '{', '<', '>', '=='];
  const laterWords = [
    'if',
    'elif',
    'else',
    'for',
    'while',
    'break',
    'continue',
    'def',
    'return',
    'and',
    'or',
    'not',
    'input',
  ];
  for (final MapEntry(key: number, value: (:calls, :ideas))
      in allowed.entries) {
    test('Level $number uses only Lessons 1-$number: $calls $ideas', () {
      for (final c in minigameLevels[number - 1].challenges) {
        final code = [
          for (final line in c.code) line.code,
          c.template,
          c.starter,
          c.solutionProgram,
          ...c.choices,
        ].join('\n');
        // Quiz answers are outputs (e.g. <class 'int'>), so they are only
        // checked for function calls.
        final answers = c.answers.map((a) => a.label(en)).join('\n');
        final used = RegExp(r'(\w+)\(')
            .allMatches('$code\n$answers')
            .map((m) => m[1]!);
        // Functions the code makes with def may be called too.
        final defined = RegExp(r'def (\w+)\(')
            .allMatches(code)
            .map((m) => m[1]!);
        expect(
          // A blank before `(` (like `___(score)`) is not a call.
          used.toSet().difference({...calls, ...defined, blankMarker}),
          isEmpty,
          reason: c.id,
        );
        for (final later in laterSymbols.where((s) => !ideas.contains(s))) {
          expect(code, isNot(contains(later)), reason: '${c.id}: $later');
        }
        for (final word in laterWords.where((w) => !ideas.contains(w))) {
          expect(
            RegExp('\\b$word\\b').hasMatch(code),
            isFalse,
            reason: '${c.id}: $word',
          );
        }
      }
    });
  }

  test('a challenge with input() says the exact question in both texts', () {
    for (final c in allChallenges) {
      final questions = RegExp(r'input\(("[^"]*")\)')
          .allMatches(c.solutionProgram)
          .map((m) => m[1]!);
      for (final q in questions) {
        for (final l10n in [en, tl]) {
          // Inside a `code span`, alone or in a line like
          // `name = input("Name? ")`.
          final parts = c.prompt(l10n).split('`');
          final spans = [for (var i = 1; i < parts.length; i += 2) parts[i]];
          expect(
            spans.any((span) => span.contains('input($q)')),
            isTrue,
            reason: '${c.id} must show input($q) as code in its text',
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

  test('required code only uses names the problem text shows as code', () {
    final word = RegExp(r'[A-Za-z_]\w*');
    for (final c in allChallenges.where((c) => c.requiredCode.isNotEmpty)) {
      final names = {
        for (final piece in c.requiredFirst)
          ...word.allMatches(piece).map((m) => m[0]!),
      }..remove('print');
      for (final l10n in [en, tl]) {
        // The words inside `code spans` of the text.
        final parts = c.prompt(l10n).split('`');
        final shown = {
          for (var i = 1; i < parts.length; i += 2)
            ...word.allMatches(parts[i]).map((m) => m[0]!),
        };
        for (final name in names) {
          expect(
            shown,
            contains(name),
            reason: '${c.id}: the text must show `$name` as code',
          );
        }
      }
    }
  });

  test('every fix and write challenge without input() has required code', () {
    for (final c in allChallenges.where(
      (c) =>
          (c.type == ChallengeType.fixBug ||
              c.type == ChallengeType.writeCode) &&
          !c.solutionProgram.contains('input('),
    )) {
      expect(c.requiredCode, isNotEmpty, reason: c.id);
    }
  });

  test('Level 1 fix the bug: printing the fixed answer does not pass', () {
    final level1 = {for (final c in minigameLevels.first.challenges) c.id: c};
    expect(missingCode('print("Cog")', level1['mgL1C6']!.requiredCode), [
      'robot_name =',
      'print(robot_name)',
    ]);
    expect(missingCode('print(5)', level1['mgL1C8']!.requiredCode), [
      'speed =',
      'print(speed)',
    ]);
    // The starting code is still missing a piece, so it never passes.
    for (final id in ['mgL1C6', 'mgL1C8']) {
      final c = level1[id]!;
      expect(missingCode(c.starter, c.requiredCode), isNotEmpty, reason: id);
    }
  });

  test('required code: printing the answer does not pass', () {
    for (final c in allChallenges.where((c) => c.requiredCode.isNotEmpty)) {
      // e.g. print(5) for "5", print("<class 'int'>") for <class 'int'>.
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

  // A solution that compares must have the comparison in its pieces, so a
  // wrong comparison can't pass: Level 3 write-it challenges, and from
  // Level 4 on every fix and write challenge.
  final comparison = RegExp(r'==|!=|<=|>=|<|>');
  test('pieces include the comparison when the solution compares', () {
    for (final (i, level) in minigameLevels.indexed.skip(2)) {
      for (final c in level.challenges.where(
        (c) =>
            c.type == ChallengeType.writeCode ||
            (i >= 3 && c.type == ChallengeType.fixBug),
      )) {
        if (!comparison.hasMatch(c.solutionProgram)) continue;
        // With input(), the hidden tests (different typed answers, edges
        // included) check the comparison instead of pieces.
        if (c.solutionProgram.contains('input(')) continue;
        expect(
          c.requiredFirst.any(comparison.hasMatch),
          isTrue,
          reason: '${c.id}: no piece has the comparison',
        );
      }
    }
  });

  test('from Level 4 on, a solution with a loop has the loop line in its '
      'pieces', () {
    for (final level in minigameLevels.skip(3)) {
      for (final c in level.challenges.where(
        (c) => c.requiredCode.isNotEmpty,
      )) {
        for (final loop in ['for ', 'while ']) {
          if (!c.solutionProgram.contains(loop)) continue;
          expect(
            c.requiredFirst.any((p) => p.startsWith(loop)),
            isTrue,
            reason: '${c.id}: no piece has the $loop line',
          );
        }
      }
    }
  });

  test('from Level 5 on, a solution with def has the function name in its '
      'pieces', () {
    for (final level in minigameLevels.skip(4)) {
      for (final c in level.challenges.where(
        (c) => c.requiredCode.isNotEmpty,
      )) {
        for (final m in RegExp(r'def (\w+)\(').allMatches(c.solutionProgram)) {
          expect(
            c.requiredFirst.any((p) => p.contains('${m[1]}(')),
            isTrue,
            reason: '${c.id}: no piece has ${m[1]}(',
          );
        }
      }
    }
  });

  test('from Level 6 on, a solution that does math has the sign in its '
      'pieces', () {
    final math = RegExp(r'\*\*|//|\*|/|%|\+|-');
    for (final level in minigameLevels.skip(5)) {
      for (final c in level.challenges.where(
        (c) => c.requiredCode.isNotEmpty,
      )) {
        if (!math.hasMatch(c.solutionProgram)) continue;
        expect(
          c.requiredFirst.any(math.hasMatch),
          isTrue,
          reason: '${c.id}: no piece has the math sign',
        );
      }
    }
  });

  test('Levels 3-6: a wrong comparison, range or sign is caught by the '
      'pieces', () {
    final level3 = {
      for (final level in minigameLevels.take(6))
        for (final c in level.challenges) c.id: c,
    };
    for (final (id, from, to) in [
      ('mgL3C3', 'lives > 0', 'lives >= 0'),
      ('mgL3C3', 'lives > 0', 'lives > 1'),
      ('mgL3C9', 'battery < 20', 'battery <= 20'),
      ('mgL3C9', 'battery < 20', 'battery < 100'),
      ('mgL3C10', 'score >= 90', 'score > 90'),
      ('mgL3C10', 'score >= 70', 'score >= 80'),
      ('mgL4C6', 'battery - 1', 'battery + 1'),
      ('mgL4C6', 'battery - 1', 'battery - 2'),
      ('mgL4C8', 'range(1, 6)', 'range(0, 6)'),
      ('mgL4C8', 'range(1, 6)', 'range(1, 7)'),
      ('mgL4C9', 'battery - 1', 'battery // 1'),
      ('mgL4C10', 'range(1, 6)', 'range(6)'),
      ('mgL4C10', 'range(1, 6)', 'range(1, 9)'),
      ('mgL6C3', 'score += 5', 'score += 6'),
      ('mgL6C6', '(red + blue) * 4', 'red * 4 + blue * 4'),
      ('mgL6C8', 'robots // 4', 'robots / 4'),
      ('mgL6C9', 'side ** 2', 'side ** 3'),
      ('mgL6C9', 'side * 4', 'side * 5'),
      ('mgL6C10', 'coins // 5', 'coins / 5'),
      ('mgL6C10', 'coins % 5', 'coins - 15'),
      ('mgL6C10', 'coins / 2', 'coins // 2'),
    ]) {
      final c = level3[id]!;
      expect(c.solutionProgram, contains(from), reason: id);
      final wrong = c.solutionProgram.replaceFirst(from, to);
      expect(
        missingCode(wrong, c.requiredCode),
        isNotEmpty,
        reason: '$id: "$to" must not pass',
      );
    }
  });

  test('AnyOf pieces have 2+ options, and each option works in the '
      'solution', () {
    for (final c in allChallenges) {
      for (final piece in c.requiredCode.whereType<AnyOf>()) {
        expect(piece.options.length, greaterThanOrEqualTo(2), reason: c.id);
        final first = piece.options.first;
        expect(c.solutionProgram, contains(first), reason: c.id);
        for (final other in piece.options.skip(1)) {
          final alt = c.solutionProgram.replaceFirst(first, other);
          expect(
            missingCode(alt, c.requiredCode),
            isEmpty,
            reason: '${c.id}: "$other" must count',
          );
        }
      }
    }
  });

  test('Level 6: the equal other ways count, wrong ones do not', () {
    final level6 = {for (final c in minigameLevels[5].challenges) c.id: c};
    for (final (id, from, to, counts) in [
      ('mgL6C3', 'score += 5', 'score = score + 5', true),
      ('mgL6C3', 'score += 5', 'score = score - 5', false),
      ('mgL6C3', 'score += 5', 'score = 15', false),
      ('mgL6C6', '(red + blue) * 4', '4 * (red + blue)', true),
      ('mgL6C6', '(red + blue) * 4', 'red * 4 + blue * 4', false),
      ('mgL6C9', 'side ** 2', 'side * side', true),
      ('mgL6C9', 'side ** 2', 'side * 2', false),
      ('mgL6C9', 'side * 4', '4 * side', true),
      ('mgL6C10', 'left += 3', 'left = left + 3', true),
      ('mgL6C10', 'left += 3', 'left = 5', false),
    ]) {
      final c = level6[id]!;
      expect(c.solutionProgram, contains(from), reason: id);
      final other = c.solutionProgram.replaceFirst(from, to);
      expect(
        missingCode(other, c.requiredCode).isEmpty,
        counts,
        reason: '$id: "$to" ${counts ? 'must' : 'must not'} count',
      );
    }
  });

  test('a solution split over lines inside brackets still has its pieces', () {
    for (final c in allChallenges.where((c) => c.requiredCode.isNotEmpty)) {
      final split = splitInsideBrackets(c.solutionProgram);
      expect(
        missingCode(split, c.requiredCode),
        isEmpty,
        reason: '${c.id}:\n$split',
      );
    }
    // The helper really splits.
    expect(
      splitInsideBrackets('print(add(2, 3))'),
      'print(add(2,\n        3))',
    );
  });

  test('a quiz whose code uses input() says what is typed', () {
    for (final c in allChallenges.where((c) => c.type == ChallengeType.quiz)) {
      final code = c.code.map((line) => line.code).join('\n');
      final asks = 'input('.allMatches(code).length;
      expect(
        c.typed.length,
        asks,
        reason: '${c.id}: one typed answer per input()',
      );
      for (final answer in c.typed) {
        for (final l10n in [en, tl]) {
          expect(
            c.prompt(l10n),
            contains('`$answer`'),
            reason: '${c.id}: the text must say `$answer` is typed',
          );
        }
      }
    }
  });

  test('every Level 10 challenge practices logic: and, or, not or a '
      '"between" check', () {
    final logic = RegExp(r'\b(and|or|not)\b|<=?\s*\w+\s*<=?');
    for (final c in minigameLevels[9].challenges) {
      final code = [
        for (final line in c.code) line.code,
        c.template,
        c.solutionProgram,
      ].join('\n');
      expect(logic.hasMatch(code), isTrue, reason: c.id);
    }
  });

  test('code challenges with input() have 2+ tests with different answers', () {
    for (final c in allChallenges.where(
      (c) => c.runsCode && c.solutionProgram.contains('input('),
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

/// [code] with a line break and 8 spaces after every comma that is inside
/// brackets (not inside quotes), e.g. `print(add(2,\n        3))`. Still
/// valid Python, like a list written over several lines.
String splitInsideBrackets(String code) {
  final out = StringBuffer();
  String? quote;
  var depth = 0;
  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (quote != null) {
      out.write(c);
      if (c == r'\' && i + 1 < code.length) {
        out.write(code[++i]);
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == '"' || c == "'") {
      quote = c;
      out.write(c);
    } else if (c == ',' && depth > 0) {
      out.write(',\n        ');
      while (i + 1 < code.length && code[i + 1] == ' ') {
        i++;
      }
    } else {
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
      if (c == '\n') quote = null;
      out.write(c);
    }
  }
  return out.toString();
}
