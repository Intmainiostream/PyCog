import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 3: Lesson 3 (If Statements), plus Lessons 1-2. `if`,
/// `elif` and `else`, the six comparisons, `=` vs `==`, the colon, the
/// 4-space indent, and "the first True one runs, then Python stops". There
/// is no input(), so each code challenge has one hidden test, and every fix
/// and write challenge lists required code so printing the answer can't
/// pass. The write-it challenges' pieces include the comparison (e.g.
/// `if lives > 0`); spaces around the signs don't matter.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
final level3 = MinigameLevel(
  number: 3,
  challenges: [
    // 1. A comparison gives True or False.
    Challenge.quiz(
      id: 'mgL3C1',
      title: (l10n) => l10n.mgL3C1Title,
      prompt: (l10n) => l10n.mgL3C1Prompt,
      code: const [CodeLine('print(5 >= 5)')],
      answers: [
        QuizAnswer(label: (_) => '`True`', correct: true),
        QuizAnswer(label: (_) => '`False`'),
        QuizAnswer(label: (_) => '`5`'),
      ],
    ),

    // 2. Pick the comparison; one `=` is an error.
    Challenge.fillBlank(
      id: 'mgL3C2',
      title: (l10n) => l10n.mgL3C2Title,
      prompt: (l10n) => l10n.mgL3C2Prompt,
      hints: [(l10n) => l10n.mgL3C2Hint1, (l10n) => l10n.mgL3C2Hint2],
      template:
          'battery = 10\n'
          'if battery $blankMarker 20:\n'
          '    print("Low battery!")',
      choices: const ['<', '>', '='],
      solution: '<',
      tests: const [
        TestCase(output: ['Low battery!']),
      ],
    ),

    // 3. The shape of an if: question, colon, indent.
    Challenge.writeCode(
      id: 'mgL3C3',
      title: (l10n) => l10n.mgL3C3Title,
      prompt: (l10n) => l10n.mgL3C3Prompt,
      hints: [(l10n) => l10n.mgL3C3Hint1, (l10n) => l10n.mgL3C3Hint2],
      solution:
          'lives = 3\n'
          'if lives > 0:\n'
          '    print("Keep playing!")',
      requiredCode: const ['lives = 3', 'if lives > 0'],
      tests: const [
        TestCase(output: ['Keep playing!']),
      ],
    ),

    // 4. if/else: only one part runs.
    Challenge.quiz(
      id: 'mgL3C4',
      title: (l10n) => l10n.mgL3C4Title,
      prompt: (l10n) => l10n.mgL3C4Prompt,
      code: const [
        CodeLine('lives = 0'),
        CodeLine('if lives > 0:'),
        CodeLine('    print("Keep playing!")'),
        CodeLine('else:'),
        CodeLine('    print("Game over!")'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`Game over!`', correct: true),
        QuizAnswer(label: (_) => '`Keep playing!`'),
        QuizAnswer(label: (_) => '`0`'),
      ],
    ),

    // 5. elif, not a second if: with 95, a second if would also print
    // Silver! (typed).
    Challenge.fillBlank(
      id: 'mgL3C5',
      title: (l10n) => l10n.mgL3C5Title,
      prompt: (l10n) => l10n.mgL3C5Prompt,
      hints: [(l10n) => l10n.mgL3C5Hint1, (l10n) => l10n.mgL3C5Hint2],
      template:
          'score = 95\n'
          'if score >= 90:\n'
          '    print("Gold!")\n'
          '$blankMarker score >= 70:\n'
          '    print("Silver!")',
      solution: 'elif',
      tests: const [
        TestCase(output: ['Gold!']),
      ],
    ),

    // 6. The line inside the if needs its indent.
    Challenge.fixBug(
      id: 'mgL3C6',
      title: (l10n) => l10n.mgL3C6Title,
      prompt: (l10n) => l10n.mgL3C6Prompt,
      hints: [(l10n) => l10n.mgL3C6Hint1, (l10n) => l10n.mgL3C6Hint2],
      starter:
          'battery = 10\n'
          'if battery < 20:\n'
          'print("Low battery!")',
      solution:
          'battery = 10\n'
          'if battery < 20:\n'
          '    print("Low battery!")',
      requiredCode: const ['battery =', 'if battery'],
      tests: const [
        TestCase(output: ['Low battery!']),
      ],
    ),

    // 7. elif chain: the first True one runs, then Python stops.
    Challenge.quiz(
      id: 'mgL3C7',
      title: (l10n) => l10n.mgL3C7Title,
      prompt: (l10n) => l10n.mgL3C7Prompt,
      code: const [
        CodeLine('temp = 30'),
        CodeLine('if temp > 35:'),
        CodeLine('    print("Hot!")'),
        CodeLine('elif temp > 25:'),
        CodeLine('    print("Warm!")'),
        CodeLine('elif temp > 15:'),
        CodeLine('    print("Cool!")'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`Warm!`', correct: true),
        QuizAnswer(label: (_) => '`Cool!`'),
        QuizAnswer(label: (_) => '`Hot!`'),
      ],
    ),

    // 8. Two bugs: `=` instead of `==`, and no colon.
    Challenge.fixBug(
      id: 'mgL3C8',
      title: (l10n) => l10n.mgL3C8Title,
      prompt: (l10n) => l10n.mgL3C8Prompt,
      hints: [(l10n) => l10n.mgL3C8Hint1, (l10n) => l10n.mgL3C8Hint2],
      starter:
          'lives = 0\n'
          'if lives = 0\n'
          '    print("Game over!")',
      solution:
          'lives = 0\n'
          'if lives == 0:\n'
          '    print("Game over!")',
      requiredCode: const ['lives =', 'if lives =='],
      tests: const [
        TestCase(output: ['Game over!']),
      ],
    ),

    // 9. if and else.
    Challenge.writeCode(
      id: 'mgL3C9',
      title: (l10n) => l10n.mgL3C9Title,
      prompt: (l10n) => l10n.mgL3C9Prompt,
      hints: [(l10n) => l10n.mgL3C9Hint1, (l10n) => l10n.mgL3C9Hint2],
      solution:
          'battery = 15\n'
          'if battery < 20:\n'
          '    print("Low battery!")\n'
          'else:\n'
          '    print("Battery OK!")',
      requiredCode: const ['battery = 15', 'if battery < 20', 'else:'],
      tests: const [
        TestCase(output: ['Low battery!']),
      ],
    ),

    // 10. The whole lesson: if, elif and else, then a comparison printed
    // as True or False.
    Challenge.writeCode(
      id: 'mgL3C10',
      title: (l10n) => l10n.mgL3C10Title,
      prompt: (l10n) => l10n.mgL3C10Prompt,
      hints: [(l10n) => l10n.mgL3C10Hint1, (l10n) => l10n.mgL3C10Hint2],
      solution:
          'score = 85\n'
          'if score >= 90:\n'
          '    print("Gold!")\n'
          'elif score >= 70:\n'
          '    print("Silver!")\n'
          'else:\n'
          '    print("Try again!")\n'
          'print(score >= 90)',
      requiredCode: const [
        'score = 85',
        'if score >= 90',
        'elif score >= 70',
        'else:',
        'print(score >= 90)',
      ],
      tests: const [
        TestCase(output: ['Silver!', 'False']),
      ],
    ),
  ],
);
