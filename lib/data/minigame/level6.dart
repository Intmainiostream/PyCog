import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 6: Lesson 6 (Math Operators), plus Lessons 1-5. `+ - * /`,
/// `/` always gives a decimal, `//` (full teams) and `%` (left over), `**`
/// (power), the order of math (`*` before `+`, `( )` first), and `+=`.
/// There is no input(), so each code challenge has one hidden test, and
/// every fix and write challenge lists required code with the full math
/// line in it, so printing the answer (or a different sign) can't pass.
/// Where an equal way exists (`score = score + 5` for `score += 5`,
/// `side * side` for `side ** 2`), it is an [AnyOf] option.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
final level6 = MinigameLevel(
  number: 6,
  challenges: [
    // 1. `/` always gives a decimal.
    Challenge.quiz(
      id: 'mgL6C1',
      title: (l10n) => l10n.mgL6C1Title,
      prompt: (l10n) => l10n.mgL6C1Prompt,
      code: const [CodeLine('print(9 / 3)')],
      answers: [
        QuizAnswer(label: (_) => '`3.0`', correct: true),
        QuizAnswer(label: (_) => '`3`'),
        QuizAnswer(label: (_) => '`27`'),
      ],
    ),

    // 2. `%` gives what is left over.
    Challenge.fillBlank(
      id: 'mgL6C2',
      title: (l10n) => l10n.mgL6C2Title,
      prompt: (l10n) => l10n.mgL6C2Prompt,
      hints: [(l10n) => l10n.mgL6C2Hint1, (l10n) => l10n.mgL6C2Hint2],
      template: 'print(7 $blankMarker 2)',
      choices: const ['%', '//', '/'],
      solution: '%',
      tests: const [
        TestCase(output: ['1']),
      ],
    ),

    // 3. `+=` adds to the old value.
    Challenge.writeCode(
      id: 'mgL6C3',
      title: (l10n) => l10n.mgL6C3Title,
      prompt: (l10n) => l10n.mgL6C3Prompt,
      hints: [(l10n) => l10n.mgL6C3Hint1, (l10n) => l10n.mgL6C3Hint2],
      solution: 'score = 10\nscore += 5\nprint(score)',
      requiredCode: const [
        'score = 10',
        AnyOf(['score += 5', 'score = score + 5']),
        'print(score)',
      ],
      tests: const [
        TestCase(output: ['15']),
      ],
    ),

    // 4. `*` goes before `-`.
    Challenge.quiz(
      id: 'mgL6C4',
      title: (l10n) => l10n.mgL6C4Title,
      prompt: (l10n) => l10n.mgL6C4Prompt,
      code: const [CodeLine('print(10 - 2 * 3)')],
      answers: [
        QuizAnswer(label: (_) => '`4`', correct: true),
        QuizAnswer(label: (_) => '`24`'),
        QuizAnswer(label: (_) => '`4.0`'),
      ],
    ),

    // 5. `**` is power (typed); `*` gives 6 and `^` gives 1.
    Challenge.fillBlank(
      id: 'mgL6C5',
      title: (l10n) => l10n.mgL6C5Title,
      prompt: (l10n) => l10n.mgL6C5Prompt,
      hints: [(l10n) => l10n.mgL6C5Hint1, (l10n) => l10n.mgL6C5Hint2],
      template: 'print(3 $blankMarker 2)',
      solution: '**',
      tests: const [
        TestCase(output: ['9']),
      ],
    ),

    // 6. Brackets go first.
    Challenge.fixBug(
      id: 'mgL6C6',
      title: (l10n) => l10n.mgL6C6Title,
      prompt: (l10n) => l10n.mgL6C6Prompt,
      hints: [(l10n) => l10n.mgL6C6Hint1, (l10n) => l10n.mgL6C6Hint2],
      starter:
          'red = 2\n'
          'blue = 3\n'
          'wheels = red + blue * 4\n'
          'print(wheels)',
      solution:
          'red = 2\n'
          'blue = 3\n'
          'wheels = (red + blue) * 4\n'
          'print(wheels)',
      requiredCode: const [
        AnyOf(['wheels = (red + blue) * 4', 'wheels = 4 * (red + blue)']),
        'print(wheels)',
      ],
      tests: const [
        TestCase(output: ['20']),
      ],
    ),

    // 7. `//` counts full teams, `%` the ones left over.
    Challenge.quiz(
      id: 'mgL6C7',
      title: (l10n) => l10n.mgL6C7Title,
      prompt: (l10n) => l10n.mgL6C7Prompt,
      code: const [
        CodeLine('robots = 11'),
        CodeLine('print(robots // 3)'),
        CodeLine('print(robots % 3)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`3, 2`', correct: true),
        QuizAnswer(label: (_) => '`2, 3`'),
        QuizAnswer(label: (_) => '`3, 1`'),
      ],
    ),

    // 8. `/` gives 3.0; whole teams need `//`.
    Challenge.fixBug(
      id: 'mgL6C8',
      title: (l10n) => l10n.mgL6C8Title,
      prompt: (l10n) => l10n.mgL6C8Prompt,
      hints: [(l10n) => l10n.mgL6C8Hint1, (l10n) => l10n.mgL6C8Hint2],
      starter:
          'robots = 12\n'
          'teams = robots / 4\n'
          'print(teams)',
      solution:
          'robots = 12\n'
          'teams = robots // 4\n'
          'print(teams)',
      requiredCode: const ['teams = robots // 4', 'print(teams)'],
      tests: const [
        TestCase(output: ['3']),
      ],
    ),

    // 9. `**` is not `*`.
    Challenge.writeCode(
      id: 'mgL6C9',
      title: (l10n) => l10n.mgL6C9Title,
      prompt: (l10n) => l10n.mgL6C9Prompt,
      hints: [(l10n) => l10n.mgL6C9Hint1, (l10n) => l10n.mgL6C9Hint2],
      solution: 'side = 5\nprint(side ** 2)\nprint(side * 4)',
      requiredCode: const [
        'side = 5',
        AnyOf(['print(side ** 2)', 'print(side * side)']),
        AnyOf(['print(side * 4)', 'print(4 * side)']),
      ],
      tests: const [
        TestCase(output: ['25', '20']),
      ],
    ),

    // 10. The whole lesson: //, %, += and / in one program.
    Challenge.writeCode(
      id: 'mgL6C10',
      title: (l10n) => l10n.mgL6C10Title,
      prompt: (l10n) => l10n.mgL6C10Prompt,
      hints: [(l10n) => l10n.mgL6C10Hint1, (l10n) => l10n.mgL6C10Hint2],
      solution:
          'coins = 17\n'
          'teams = coins // 5\n'
          'left = coins % 5\n'
          'left += 3\n'
          'print(teams)\n'
          'print(left)\n'
          'print(coins / 2)',
      requiredCode: const [
        'coins = 17',
        'teams = coins // 5',
        'left = coins % 5',
        AnyOf(['left += 3', 'left = left + 3']),
        'print(teams)',
        'print(left)',
        'print(coins / 2)',
      ],
      tests: const [
        TestCase(output: ['3', '5', '8.5']),
      ],
    ),
  ],
);
