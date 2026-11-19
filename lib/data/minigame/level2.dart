import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 2: Lesson 2 (Data Types), plus Lesson 1 ideas. The four
/// types (`int`, `float`, `str`, `bool`), quotes make text (`"5"` is not
/// `5`), `True` / `False` need a big first letter, `10.0` is a float, and
/// asking Python with `print(type(...))`. There is no input(), so each code
/// challenge has one hidden test, and every fix and write challenge lists
/// required code so printing the answer can't pass.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
const _int = "<class 'int'>";
const _float = "<class 'float'>";
const _str = "<class 'str'>";
const _bool = "<class 'bool'>";

final level2 = MinigameLevel(
  number: 2,
  challenges: [
    // 1. A whole number is an int.
    Challenge.quiz(
      id: 'mgL2C1',
      title: (l10n) => l10n.mgL2C1Title,
      prompt: (l10n) => l10n.mgL2C1Prompt,
      code: const [CodeLine('steps = 250')],
      answers: [
        QuizAnswer(label: (_) => '`int`', correct: true),
        QuizAnswer(label: (_) => '`float`'),
        QuizAnswer(label: (_) => '`str`'),
        QuizAnswer(label: (_) => '`bool`'),
      ],
    ),

    // 2. Quotes make text: only "5" is a str.
    Challenge.fillBlank(
      id: 'mgL2C2',
      title: (l10n) => l10n.mgL2C2Title,
      prompt: (l10n) => l10n.mgL2C2Prompt,
      hints: [(l10n) => l10n.mgL2C2Hint1, (l10n) => l10n.mgL2C2Hint2],
      template: 'print(type($blankMarker))',
      choices: const ['5', '"5"', '5.0'],
      solution: '"5"',
      tests: const [
        TestCase(output: [_str]),
      ],
    ),

    // 3. Make an int and ask Python its type.
    Challenge.writeCode(
      id: 'mgL2C3',
      title: (l10n) => l10n.mgL2C3Title,
      prompt: (l10n) => l10n.mgL2C3Prompt,
      hints: [(l10n) => l10n.mgL2C3Hint1, (l10n) => l10n.mgL2C3Hint2],
      solution: 'lives = 3\nprint(type(lives))',
      requiredCode: const ['lives = 3', 'print(type(lives))'],
      tests: const [
        TestCase(output: [_int]),
      ],
    ),

    // 4. "5" in quotes is text.
    Challenge.quiz(
      id: 'mgL2C4',
      title: (l10n) => l10n.mgL2C4Title,
      prompt: (l10n) => l10n.mgL2C4Prompt,
      code: const [CodeLine('room = "5"'), CodeLine('print(type(room))')],
      answers: [
        QuizAnswer(label: (_) => '`$_str`', correct: true),
        QuizAnswer(label: (_) => '`$_int`'),
        QuizAnswer(label: (_) => '`5`'),
      ],
    ),

    // 5. A bool is True or False (typed). False passes too.
    Challenge.fillBlank(
      id: 'mgL2C5',
      title: (l10n) => l10n.mgL2C5Title,
      prompt: (l10n) => l10n.mgL2C5Prompt,
      hints: [(l10n) => l10n.mgL2C5Hint1, (l10n) => l10n.mgL2C5Hint2],
      template: 'is_online = $blankMarker\nprint(type(is_online))',
      solution: 'True',
      tests: const [
        TestCase(output: [_bool]),
      ],
    ),

    // 6. `false` with a small f is not a bool.
    Challenge.fixBug(
      id: 'mgL2C6',
      title: (l10n) => l10n.mgL2C6Title,
      prompt: (l10n) => l10n.mgL2C6Prompt,
      hints: [(l10n) => l10n.mgL2C6Hint1, (l10n) => l10n.mgL2C6Hint2],
      starter: 'is_flying = false\nprint(type(is_flying))',
      solution: 'is_flying = False\nprint(type(is_flying))',
      requiredCode: const ['is_flying =', 'print(type(is_flying))'],
      tests: const [
        TestCase(output: [_bool]),
      ],
    ),

    // 7. The dot counts: 10.0 is a float.
    Challenge.quiz(
      id: 'mgL2C7',
      title: (l10n) => l10n.mgL2C7Title,
      prompt: (l10n) => l10n.mgL2C7Prompt,
      code: const [CodeLine('price = 10.0'), CodeLine('print(type(price))')],
      answers: [
        QuizAnswer(label: (_) => '`$_float`', correct: true),
        QuizAnswer(label: (_) => '`$_int`'),
        QuizAnswer(label: (_) => '`10.0`'),
      ],
    ),

    // 8. Quotes made `lives` text; it should be an int.
    Challenge.fixBug(
      id: 'mgL2C8',
      title: (l10n) => l10n.mgL2C8Title,
      prompt: (l10n) => l10n.mgL2C8Prompt,
      hints: [(l10n) => l10n.mgL2C8Hint1, (l10n) => l10n.mgL2C8Hint2],
      starter: 'lives = "3"\nprint(type(lives))',
      solution: 'lives = 3\nprint(type(lives))',
      requiredCode: const ['lives =', 'print(type(lives))'],
      tests: const [
        TestCase(output: [_int]),
      ],
    ),

    // 9. A float and a str ("5"), each type printed in order.
    Challenge.writeCode(
      id: 'mgL2C9',
      title: (l10n) => l10n.mgL2C9Title,
      prompt: (l10n) => l10n.mgL2C9Prompt,
      hints: [(l10n) => l10n.mgL2C9Hint1, (l10n) => l10n.mgL2C9Hint2],
      solution:
          'speed = 2.5\n'
          'room = "5"\n'
          'print(type(speed))\n'
          'print(type(room))',
      requiredCode: const [
        'speed =',
        'room =',
        'print(type(speed))',
        'print(type(room))',
      ],
      tests: const [
        TestCase(output: [_float, _str]),
      ],
    ),

    // 10. The whole lesson: pick a value of each type (any values), then
    // print all four types in order.
    Challenge.writeCode(
      id: 'mgL2C10',
      title: (l10n) => l10n.mgL2C10Title,
      prompt: (l10n) => l10n.mgL2C10Prompt,
      hints: [(l10n) => l10n.mgL2C10Hint1, (l10n) => l10n.mgL2C10Hint2],
      solution:
          'lives = 3\n'
          'speed = 2.5\n'
          'robot = "Cog"\n'
          'is_online = True\n'
          'print(type(lives))\n'
          'print(type(speed))\n'
          'print(type(robot))\n'
          'print(type(is_online))',
      requiredCode: const [
        'lives =',
        'speed =',
        'robot =',
        'is_online =',
        'print(type(lives))',
        'print(type(speed))',
        'print(type(robot))',
        'print(type(is_online))',
      ],
      tests: const [
        TestCase(output: [_int, _float, _str, _bool]),
      ],
    ),
  ],
);
