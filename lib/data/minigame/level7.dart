import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 7: Lesson 7 (Strings), plus Lessons 1-6. Text in `'` or
/// `"` quotes (both ends must match), joining with `+` (spaces go inside
/// the quotes), repeating with `*`, `len()`, picking a letter with `[0]`
/// (counting starts at 0), `str()` before joining a number, and `.upper()`
/// / `.lower()`. There is no input(), so each code challenge has one hidden
/// test, and every fix and write challenge lists required code with the
/// full line in it. `'` and `"` count as the same, and equal other ways
/// are [AnyOf] options.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
final level7 = MinigameLevel(
  number: 7,
  challenges: [
    // 1. len() counts every character, the space too.
    Challenge.quiz(
      id: 'mgL7C1',
      title: (l10n) => l10n.mgL7C1Title,
      prompt: (l10n) => l10n.mgL7C1Prompt,
      code: const [CodeLine('print(len("Go Cog"))')],
      answers: [
        QuizAnswer(label: (_) => '`6`', correct: true),
        QuizAnswer(label: (_) => '`5`'),
        QuizAnswer(label: (_) => '`2`'),
      ],
    ),

    // 2. Joining with +: the space goes inside the quotes.
    Challenge.fillBlank(
      id: 'mgL7C2',
      title: (l10n) => l10n.mgL7C2Title,
      prompt: (l10n) => l10n.mgL7C2Prompt,
      hints: [(l10n) => l10n.mgL7C2Hint1, (l10n) => l10n.mgL7C2Hint2],
      template: 'print("Hi," + $blankMarker)',
      choices: const ['" Cog"', '"Cog"', 'Cog'],
      solution: '" Cog"',
      tests: const [
        TestCase(output: ['Hi, Cog']),
      ],
    ),

    // 3. A string * a number repeats it.
    Challenge.writeCode(
      id: 'mgL7C3',
      title: (l10n) => l10n.mgL7C3Title,
      prompt: (l10n) => l10n.mgL7C3Prompt,
      hints: [(l10n) => l10n.mgL7C3Hint1, (l10n) => l10n.mgL7C3Hint2],
      solution: 'laugh = "Ha" * 3\nprint(laugh)',
      requiredCode: const [
        AnyOf(['laugh = "Ha" * 3', 'laugh = 3 * "Ha"']),
        'print(laugh)',
      ],
      tests: const [
        TestCase(output: ['HaHaHa']),
      ],
    ),

    // 4. Counting starts at 0: word[1] is the second letter.
    Challenge.quiz(
      id: 'mgL7C4',
      title: (l10n) => l10n.mgL7C4Title,
      prompt: (l10n) => l10n.mgL7C4Prompt,
      code: const [CodeLine('word = "Robot"'), CodeLine('print(word[1])')],
      answers: [
        QuizAnswer(label: (_) => '`o`', correct: true),
        QuizAnswer(label: (_) => '`R`'),
        QuizAnswer(label: (_) => '`b`'),
      ],
    ),

    // 5. str() turns a number into text (typed).
    Challenge.fillBlank(
      id: 'mgL7C5',
      title: (l10n) => l10n.mgL7C5Title,
      prompt: (l10n) => l10n.mgL7C5Prompt,
      hints: [(l10n) => l10n.mgL7C5Hint1, (l10n) => l10n.mgL7C5Hint2],
      template:
          'score = 10\n'
          'print("Score " + $blankMarker(score))',
      solution: 'str',
      tests: const [
        TestCase(output: ['Score 10']),
      ],
    ),

    // 6. Text + a number is an error: use str().
    Challenge.fixBug(
      id: 'mgL7C6',
      title: (l10n) => l10n.mgL7C6Title,
      prompt: (l10n) => l10n.mgL7C6Prompt,
      hints: [(l10n) => l10n.mgL7C6Hint1, (l10n) => l10n.mgL7C6Hint2],
      starter: 'lives = 3\nprint("Lives " + lives)',
      solution: 'lives = 3\nprint("Lives " + str(lives))',
      requiredCode: const ['print("Lives " + str(lives))'],
      tests: const [
        TestCase(output: ['Lives 3']),
      ],
    ),

    // 7. .lower() makes small letters.
    Challenge.quiz(
      id: 'mgL7C7',
      title: (l10n) => l10n.mgL7C7Title,
      prompt: (l10n) => l10n.mgL7C7Prompt,
      code: const [CodeLine('name = "Bolt"'), CodeLine('print(name.lower())')],
      answers: [
        QuizAnswer(label: (_) => '`bolt`', correct: true),
        QuizAnswer(label: (_) => '`BOLT`'),
        QuizAnswer(label: (_) => '`Bolt`'),
      ],
    ),

    // 8. Two bugs: the quotes don't match, and [1] is the second letter.
    Challenge.fixBug(
      id: 'mgL7C8',
      title: (l10n) => l10n.mgL7C8Title,
      prompt: (l10n) => l10n.mgL7C8Prompt,
      hints: [(l10n) => l10n.mgL7C8Hint1, (l10n) => l10n.mgL7C8Hint2],
      starter: 'name = "Cog\'\nprint(name[1])',
      solution: 'name = "Cog"\nprint(name[0])',
      requiredCode: const ['name = "Cog"', 'print(name[0])'],
      tests: const [
        TestCase(output: ['C']),
      ],
    ),

    // 9. len(), then str() to join the number to text.
    Challenge.writeCode(
      id: 'mgL7C9',
      title: (l10n) => l10n.mgL7C9Title,
      prompt: (l10n) => l10n.mgL7C9Prompt,
      hints: [(l10n) => l10n.mgL7C9Hint1, (l10n) => l10n.mgL7C9Hint2],
      solution:
          'word = "Python"\n'
          'size = len(word)\n'
          'print("Size " + str(size))',
      requiredCode: const [
        'word = "Python"',
        'size = len(word)',
        'print("Size " + str(size))',
      ],
      tests: const [
        TestCase(output: ['Size 6']),
      ],
    ),

    // 10. The whole lesson: .upper(), * with len(), [0] and + in a banner.
    Challenge.writeCode(
      id: 'mgL7C10',
      title: (l10n) => l10n.mgL7C10Title,
      prompt: (l10n) => l10n.mgL7C10Prompt,
      hints: [(l10n) => l10n.mgL7C10Hint1, (l10n) => l10n.mgL7C10Hint2],
      solution:
          'name = "cog"\n'
          'print(name.upper())\n'
          'print("=" * len(name))\n'
          'print(name[0] + "!")',
      requiredCode: const [
        'name = "cog"',
        'print(name.upper())',
        AnyOf(['print("=" * len(name))', 'print(len(name) * "=")']),
        'print(name[0] + "!")',
      ],
      tests: const [
        TestCase(output: ['COG', '===', 'c!']),
      ],
    ),
  ],
);
