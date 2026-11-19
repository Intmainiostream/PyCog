import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 1: Lesson 1 (Variables) only. Making a variable with `=`,
/// changing it, the three kinds of values (numbers, words in quotes,
/// `True` / `False`), `#` comments and the naming rules. The one extra is
/// `print()`, which the challenges explain ("shows what is inside a box");
/// there is no input(), so each challenge has one hidden test, and the
/// write-it challenges list required code so `print(5)` alone can't pass.
///
/// Every answer, solution, starting code and expected output was run in
/// real Python; integration_test/minigame_solutions_test.dart runs them
/// again on a device.
final level1 = MinigameLevel(
  number: 1,
  challenges: [
    // 1. Changing a variable: the box keeps only its newest value.
    Challenge.quiz(
      id: 'mgL1C1',
      title: (l10n) => l10n.mgL1C1Title,
      prompt: (l10n) => l10n.mgL1C1Prompt,
      code: const [
        CodeLine('battery = 100'),
        CodeLine('battery = 80'),
        CodeLine('print(battery)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`80`', correct: true),
        QuizAnswer(label: (_) => '`100`'),
        QuizAnswer(label: (_) => '`180`'),
        QuizAnswer(label: (_) => '`battery`'),
      ],
    ),

    // 2. Big and small letters, and quotes: only `name` prints Cog.
    Challenge.fillBlank(
      id: 'mgL1C2',
      title: (l10n) => l10n.mgL1C2Title,
      prompt: (l10n) => l10n.mgL1C2Prompt,
      hints: [(l10n) => l10n.mgL1C2Hint1, (l10n) => l10n.mgL1C2Hint2],
      template: 'name = "Cog"\nprint($blankMarker)',
      choices: const ['name', '"name"', 'Name'],
      solution: 'name',
      tests: const [
        TestCase(output: ['Cog']),
      ],
    ),

    // 3. Making a variable and showing it.
    Challenge.writeCode(
      id: 'mgL1C3',
      title: (l10n) => l10n.mgL1C3Title,
      prompt: (l10n) => l10n.mgL1C3Prompt,
      hints: [(l10n) => l10n.mgL1C3Hint1, (l10n) => l10n.mgL1C3Hint2],
      solution: 'speed = 5\nprint(speed)',
      requiredCode: const ['speed = 5', 'print(speed)'],
      tests: const [
        TestCase(output: ['5']),
      ],
    ),

    // 4. Naming rules: no spaces, no number at the start.
    Challenge.quiz(
      id: 'mgL1C4',
      title: (l10n) => l10n.mgL1C4Title,
      prompt: (l10n) => l10n.mgL1C4Prompt,
      answers: [
        QuizAnswer(label: (_) => '`robot_name`', correct: true),
        QuizAnswer(label: (_) => '`robot name`'),
        QuizAnswer(label: (_) => '`2robot`'),
      ],
    ),

    // 5. A word needs quotes (typed, not picked).
    Challenge.fillBlank(
      id: 'mgL1C5',
      title: (l10n) => l10n.mgL1C5Title,
      prompt: (l10n) => l10n.mgL1C5Prompt,
      hints: [(l10n) => l10n.mgL1C5Hint1, (l10n) => l10n.mgL1C5Hint2],
      template: 'robot_name = $blankMarker\nprint(robot_name)',
      solution: '"Bolt"',
      tests: const [
        TestCase(output: ['Bolt']),
      ],
    ),

    // 6. A space in a name is a bug.
    Challenge.fixBug(
      id: 'mgL1C6',
      title: (l10n) => l10n.mgL1C6Title,
      prompt: (l10n) => l10n.mgL1C6Prompt,
      hints: [(l10n) => l10n.mgL1C6Hint1, (l10n) => l10n.mgL1C6Hint2],
      starter: 'robot name = "Cog"\nprint(robot name)',
      solution: 'robot_name = "Cog"\nprint(robot_name)',
      tests: const [
        TestCase(output: ['Cog']),
      ],
    ),

    // 7. Python skips a `#` comment.
    Challenge.quiz(
      id: 'mgL1C7',
      title: (l10n) => l10n.mgL1C7Title,
      prompt: (l10n) => l10n.mgL1C7Prompt,
      code: const [
        CodeLine('battery = 100'),
        CodeLine('# battery = 50'),
        CodeLine('print(battery)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`100`', correct: true),
        QuizAnswer(label: (_) => '`50`'),
        QuizAnswer(label: (_) => '`battery`'),
      ],
    ),

    // 8. `speed` and `Speed` are two different boxes.
    Challenge.fixBug(
      id: 'mgL1C8',
      title: (l10n) => l10n.mgL1C8Title,
      prompt: (l10n) => l10n.mgL1C8Prompt,
      hints: [(l10n) => l10n.mgL1C8Hint1, (l10n) => l10n.mgL1C8Hint2],
      starter: 'speed = 5\nprint(Speed)',
      solution: 'speed = 5\nprint(speed)',
      tests: const [
        TestCase(output: ['5']),
      ],
    ),

    // 9. Changing a variable, printing before and after.
    Challenge.writeCode(
      id: 'mgL1C9',
      title: (l10n) => l10n.mgL1C9Title,
      prompt: (l10n) => l10n.mgL1C9Prompt,
      hints: [(l10n) => l10n.mgL1C9Hint1, (l10n) => l10n.mgL1C9Hint2],
      solution: 'lives = 3\nprint(lives)\nlives = 2\nprint(lives)',
      requiredCode: const ['lives = 3', 'lives = 2', 'print(lives)'],
      tests: const [
        TestCase(output: ['3', '2']),
      ],
    ),

    // 10. All three kinds of values, in order.
    Challenge.writeCode(
      id: 'mgL1C10',
      title: (l10n) => l10n.mgL1C10Title,
      prompt: (l10n) => l10n.mgL1C10Prompt,
      hints: [(l10n) => l10n.mgL1C10Hint1, (l10n) => l10n.mgL1C10Hint2],
      solution:
          'robot_name = "Cog"\n'
          'speed = 5\n'
          'is_moving = True\n'
          'print(robot_name)\n'
          'print(speed)\n'
          'print(is_moving)',
      requiredCode: const [
        'robot_name =',
        'speed =',
        'is_moving =',
        'print(robot_name)',
        'print(speed)',
        'print(is_moving)',
      ],
      tests: const [
        TestCase(output: ['Cog', '5', 'True']),
      ],
    ),
  ],
);
