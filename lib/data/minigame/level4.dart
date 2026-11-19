import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 4: Lesson 4 (Loops), plus Lessons 1-3. `for` with
/// `range(n)` and `range(start, stop)` (it stops BEFORE the stop number),
/// using the counter, `while` (change the value you check, or it never
/// stops), and `break`. There is no input(), so each code challenge has one
/// hidden test, and every fix and write challenge lists required code with
/// the loop line in it, so printing the answer can't pass.
///
/// Pieces avoid commas and `-` (spaces there are not ignored yet), e.g.
/// `for number in range(1,` and `battery = battery`; the output checks the
/// numbers.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
final level4 = MinigameLevel(
  number: 4,
  challenges: [
    // 1. range(2, 5) gives 2, 3, 4.
    Challenge.quiz(
      id: 'mgL4C1',
      title: (l10n) => l10n.mgL4C1Title,
      prompt: (l10n) => l10n.mgL4C1Prompt,
      code: const [CodeLine('for n in range(2, 5):'), CodeLine('    print(n)')],
      answers: [
        QuizAnswer(label: (_) => '`2, 3, 4`', correct: true),
        QuizAnswer(label: (_) => '`2, 3, 4, 5`'),
        QuizAnswer(label: (_) => '`3, 4, 5`'),
      ],
    ),

    // 2. range stops BEFORE the stop number: 1 to 5 needs range(1, 6).
    Challenge.fillBlank(
      id: 'mgL4C2',
      title: (l10n) => l10n.mgL4C2Title,
      prompt: (l10n) => l10n.mgL4C2Prompt,
      hints: [(l10n) => l10n.mgL4C2Hint1, (l10n) => l10n.mgL4C2Hint2],
      template:
          'for number in range(1, $blankMarker):\n'
          '    print(number)',
      choices: const ['5', '6', '4'],
      solution: '6',
      tests: const [
        TestCase(output: ['1', '2', '3', '4', '5']),
      ],
    ),

    // 3. The shape of a for loop.
    Challenge.writeCode(
      id: 'mgL4C3',
      title: (l10n) => l10n.mgL4C3Title,
      prompt: (l10n) => l10n.mgL4C3Prompt,
      hints: [(l10n) => l10n.mgL4C3Hint1, (l10n) => l10n.mgL4C3Hint2],
      solution:
          'for step in range(3):\n'
          '    print("Step")',
      requiredCode: const ['for step in range(3)'],
      tests: const [
        TestCase(output: ['Step', 'Step', 'Step']),
      ],
    ),

    // 4. while repeats as long as the question is True.
    Challenge.quiz(
      id: 'mgL4C4',
      title: (l10n) => l10n.mgL4C4Title,
      prompt: (l10n) => l10n.mgL4C4Prompt,
      code: const [
        CodeLine('battery = 4'),
        CodeLine('while battery > 2:'),
        CodeLine('    print(battery)'),
        CodeLine('    battery = battery - 1'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`4, 3`', correct: true),
        QuizAnswer(label: (_) => '`4, 3, 2`'),
        QuizAnswer(label: (_) => '`3, 2`'),
      ],
    ),

    // 5. break stops the loop early (typed).
    Challenge.fillBlank(
      id: 'mgL4C5',
      title: (l10n) => l10n.mgL4C5Title,
      prompt: (l10n) => l10n.mgL4C5Prompt,
      hints: [(l10n) => l10n.mgL4C5Hint1, (l10n) => l10n.mgL4C5Hint2],
      template:
          'for room in range(1, 6):\n'
          '    if room == 2:\n'
          '        print("Enemy!")\n'
          '        $blankMarker\n'
          '    print("Clear")',
      solution: 'break',
      tests: const [
        TestCase(output: ['Clear', 'Enemy!']),
      ],
    ),

    // 6. A while loop that never stops: change battery inside it.
    Challenge.fixBug(
      id: 'mgL4C6',
      title: (l10n) => l10n.mgL4C6Title,
      prompt: (l10n) => l10n.mgL4C6Prompt,
      hints: [(l10n) => l10n.mgL4C6Hint1, (l10n) => l10n.mgL4C6Hint2],
      starter:
          'battery = 3\n'
          'while battery > 0:\n'
          '    print("Moving")',
      solution:
          'battery = 3\n'
          'while battery > 0:\n'
          '    print("Moving")\n'
          '    battery = battery - 1',
      requiredCode: const ['while battery > 0', 'battery = battery'],
      tests: const [
        TestCase(output: ['Moving', 'Moving', 'Moving']),
      ],
    ),

    // 7. break: the rest of the loop is skipped.
    Challenge.quiz(
      id: 'mgL4C7',
      title: (l10n) => l10n.mgL4C7Title,
      prompt: (l10n) => l10n.mgL4C7Prompt,
      code: const [
        CodeLine('for n in range(1, 10):'),
        CodeLine('    if n == 3:'),
        CodeLine('        break'),
        CodeLine('    print(n)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`1, 2`', correct: true),
        QuizAnswer(label: (_) => '`1, 2, 3`'),
        QuizAnswer(label: (_) => '`3`'),
      ],
    ),

    // 8. Two bugs: no colon, and range(1, 5) stops before 5.
    Challenge.fixBug(
      id: 'mgL4C8',
      title: (l10n) => l10n.mgL4C8Title,
      prompt: (l10n) => l10n.mgL4C8Prompt,
      hints: [(l10n) => l10n.mgL4C8Hint1, (l10n) => l10n.mgL4C8Hint2],
      starter:
          'for number in range(1, 5)\n'
          '    print(number)',
      solution:
          'for number in range(1, 6):\n'
          '    print(number)',
      requiredCode: const ['for number in range(1,'],
      tests: const [
        TestCase(output: ['1', '2', '3', '4', '5']),
      ],
    ),

    // 9. A while countdown, then one line after the loop.
    Challenge.writeCode(
      id: 'mgL4C9',
      title: (l10n) => l10n.mgL4C9Title,
      prompt: (l10n) => l10n.mgL4C9Prompt,
      hints: [(l10n) => l10n.mgL4C9Hint1, (l10n) => l10n.mgL4C9Hint2],
      solution:
          'battery = 3\n'
          'while battery > 0:\n'
          '    print(battery)\n'
          '    battery = battery - 1\n'
          'print("Empty!")',
      requiredCode: const [
        'battery = 3',
        'while battery > 0',
        'print(battery)',
        'battery = battery',
      ],
      tests: const [
        TestCase(output: ['3', '2', '1', 'Empty!']),
      ],
    ),

    // 10. The whole lesson: a for loop with the counter, an if inside it,
    // and break.
    Challenge.writeCode(
      id: 'mgL4C10',
      title: (l10n) => l10n.mgL4C10Title,
      prompt: (l10n) => l10n.mgL4C10Prompt,
      hints: [(l10n) => l10n.mgL4C10Hint1, (l10n) => l10n.mgL4C10Hint2],
      solution:
          'for room in range(1, 6):\n'
          '    if room == 4:\n'
          '        print("Found!")\n'
          '        break\n'
          '    print(room)',
      requiredCode: const [
        'for room in range(1,',
        'if room == 4',
        'break',
        'print(room)',
      ],
      tests: const [
        TestCase(output: ['1', '2', '3', 'Found!']),
      ],
    ),
  ],
);
