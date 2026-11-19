import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 10, the last level: Lesson 10 (Logic), plus Lessons 1-9.
/// `and` (both True), `or` (one is enough), `not` (flips it), comparisons
/// kept in variables, the and/or mix-up, the order (`not`, then `and`,
/// then `or`) and brackets, and "between two numbers" (`1 <= n <= 10`).
/// The quizzes on order and brackets would give the other answer if read
/// the wrong way. Challenges with input() follow the Level 9 rules (exact
/// question, 2+ tests with different answers, including the edges like 13
/// and 19); the others have required code. Challenge 10 is the final
/// challenge of the game: a list, input(), int(), a range check, `in`,
/// `or` and joining text.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python with the typed answers;
/// integration_test/minigame_solutions_test.dart runs them again on a
/// device.
final level10 = MinigameLevel(
  number: 10,
  challenges: [
    // 1. or: one True is enough.
    Challenge.quiz(
      id: 'mgL10C1',
      title: (l10n) => l10n.mgL10C1Title,
      prompt: (l10n) => l10n.mgL10C1Prompt,
      code: const [CodeLine('print(False or True)')],
      answers: [
        QuizAnswer(label: (_) => '`True`', correct: true),
        QuizAnswer(label: (_) => '`False`'),
        QuizAnswer(label: (_) => '`False or True`'),
      ],
    ),

    // 2. and: both must be True.
    Challenge.fillBlank(
      id: 'mgL10C2',
      title: (l10n) => l10n.mgL10C2Title,
      prompt: (l10n) => l10n.mgL10C2Prompt,
      hints: [(l10n) => l10n.mgL10C2Hint1, (l10n) => l10n.mgL10C2Hint2],
      template:
          'has_key = True\n'
          'battery = 0\n'
          'if has_key $blankMarker battery > 0:\n'
          '    print("Door opens!")\n'
          'else:\n'
          '    print("Still locked")',
      choices: const ['and', 'or', 'not'],
      solution: 'and',
      tests: const [
        TestCase(output: ['Still locked']),
      ],
    ),

    // 3. and between two comparisons, with typed ages (13 and 19 count).
    Challenge.writeCode(
      id: 'mgL10C3',
      title: (l10n) => l10n.mgL10C3Title,
      prompt: (l10n) => l10n.mgL10C3Prompt,
      hints: [(l10n) => l10n.mgL10C3Hint1, (l10n) => l10n.mgL10C3Hint2],
      solution:
          'age = int(input("Age? "))\n'
          'if age >= 13 and age <= 19:\n'
          '    print("Teen")\n'
          'else:\n'
          '    print("Not teen")',
      tests: const [
        TestCase(inputs: ['15'], output: ['Age? 15', 'Teen']),
        TestCase(inputs: ['20'], output: ['Age? 20', 'Not teen']),
        TestCase(inputs: ['9'], output: ['Age? 9', 'Not teen']),
        TestCase(inputs: ['13'], output: ['Age? 13', 'Teen']),
        TestCase(inputs: ['19'], output: ['Age? 19', 'Teen']),
      ],
    ),

    // 4. not goes before and: (not False) and False is False. Read the
    // other way, not (False and False), it would be True.
    Challenge.quiz(
      id: 'mgL10C4',
      title: (l10n) => l10n.mgL10C4Title,
      prompt: (l10n) => l10n.mgL10C4Prompt,
      code: const [CodeLine('print(not False and False)')],
      answers: [
        QuizAnswer(label: (_) => '`False`', correct: true),
        QuizAnswer(label: (_) => '`True`'),
        QuizAnswer(label: (_) => '`not False`'),
      ],
    ),

    // 5. not flips False to True (typed).
    Challenge.fillBlank(
      id: 'mgL10C5',
      title: (l10n) => l10n.mgL10C5Title,
      prompt: (l10n) => l10n.mgL10C5Prompt,
      hints: [(l10n) => l10n.mgL10C5Hint1, (l10n) => l10n.mgL10C5Hint2],
      template:
          'game_over = False\n'
          'if $blankMarker game_over:\n'
          '    print("Keep playing!")',
      solution: 'not',
      tests: const [
        TestCase(output: ['Keep playing!']),
      ],
    ),

    // 6. The and/or mix-up: needs both, so and.
    Challenge.fixBug(
      id: 'mgL10C6',
      title: (l10n) => l10n.mgL10C6Title,
      prompt: (l10n) => l10n.mgL10C6Prompt,
      hints: [(l10n) => l10n.mgL10C6Hint1, (l10n) => l10n.mgL10C6Hint2],
      starter:
          'lives = 3\n'
          'power = 0\n'
          'if lives > 0 or power > 0:\n'
          '    print("Robot moves")\n'
          'else:\n'
          '    print("Robot stops")',
      solution:
          'lives = 3\n'
          'power = 0\n'
          'if lives > 0 and power > 0:\n'
          '    print("Robot moves")\n'
          'else:\n'
          '    print("Robot stops")',
      requiredCode: const [
        AnyOf(['if lives > 0 and power > 0', 'if power > 0 and lives > 0']),
      ],
      tests: const [
        TestCase(output: ['Robot stops']),
      ],
    ),

    // 7. Brackets go first: (a or b) and c is False; without brackets,
    // a or (b and c) would be True.
    Challenge.quiz(
      id: 'mgL10C7',
      title: (l10n) => l10n.mgL10C7Title,
      prompt: (l10n) => l10n.mgL10C7Prompt,
      code: const [
        CodeLine('a = True'),
        CodeLine('b = False'),
        CodeLine('c = False'),
        CodeLine('print((a or b) and c)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`False`', correct: true),
        QuizAnswer(label: (_) => '`True`'),
        QuizAnswer(label: (_) => '`a or b`'),
      ],
    ),

    // 8. Two bugs in a "between" check: => is not a sign, and the colon is
    // missing. Typed numbers test both edges (1 and 10 are in range).
    Challenge.fixBug(
      id: 'mgL10C8',
      title: (l10n) => l10n.mgL10C8Title,
      prompt: (l10n) => l10n.mgL10C8Prompt,
      hints: [(l10n) => l10n.mgL10C8Hint1, (l10n) => l10n.mgL10C8Hint2],
      starter:
          'n = int(input("Number? "))\n'
          'if 1 <= n => 10\n'
          '    print("In range")\n'
          'else:\n'
          '    print("Out of range")',
      solution:
          'n = int(input("Number? "))\n'
          'if 1 <= n <= 10:\n'
          '    print("In range")\n'
          'else:\n'
          '    print("Out of range")',
      tests: const [
        TestCase(inputs: ['5'], output: ['Number? 5', 'In range']),
        TestCase(inputs: ['12'], output: ['Number? 12', 'Out of range']),
        TestCase(inputs: ['0'], output: ['Number? 0', 'Out of range']),
        TestCase(inputs: ['10'], output: ['Number? 10', 'In range']),
        TestCase(inputs: ['1'], output: ['Number? 1', 'In range']),
      ],
    ),

    // 9. Comparisons kept in variables, then and / or.
    Challenge.writeCode(
      id: 'mgL10C9',
      title: (l10n) => l10n.mgL10C9Title,
      prompt: (l10n) => l10n.mgL10C9Prompt,
      hints: [(l10n) => l10n.mgL10C9Hint1, (l10n) => l10n.mgL10C9Hint2],
      solution:
          'battery = 50\n'
          'lives = 0\n'
          'power = battery > 20\n'
          'alive = lives > 0\n'
          'print(power and alive)\n'
          'print(power or alive)',
      requiredCode: const [
        'battery = 50',
        'lives = 0',
        'power = battery > 20',
        'alive = lives > 0',
        AnyOf(['print(power and alive)', 'print(alive and power)']),
        AnyOf(['print(power or alive)', 'print(alive or power)']),
      ],
      tests: const [
        TestCase(output: ['False', 'True']),
      ],
    ),

    // 10. The final challenge of the game: a list and `in` (Lesson 8),
    // input() and int() (Lesson 9), a range check, or, if / else and
    // joining text. The tests catch and-for-or, < for <=, and a missing
    // level check.
    Challenge.writeCode(
      id: 'mgL10C10',
      title: (l10n) => l10n.mgL10C10Title,
      prompt: (l10n) => l10n.mgL10C10Prompt,
      hints: [(l10n) => l10n.mgL10C10Hint1, (l10n) => l10n.mgL10C10Hint2],
      solution:
          'vip = ["Ana", "Cog"]\n'
          'name = input("Name? ")\n'
          'lvl = int(input("Level? "))\n'
          'good = 5 <= lvl <= 9\n'
          'if name in vip or good:\n'
          '    print("Hi, " + name)\n'
          'else:\n'
          '    print("Sorry, " + name)',
      tests: const [
        TestCase(
          inputs: ['Ana', '1'],
          output: ['Name? Ana', 'Level? 1', 'Hi, Ana'],
        ),
        TestCase(
          inputs: ['Bob', '7'],
          output: ['Name? Bob', 'Level? 7', 'Hi, Bob'],
        ),
        TestCase(
          inputs: ['Bob', '12'],
          output: ['Name? Bob', 'Level? 12', 'Sorry, Bob'],
        ),
        TestCase(
          inputs: ['Zed', '3'],
          output: ['Name? Zed', 'Level? 3', 'Sorry, Zed'],
        ),
        TestCase(
          inputs: ['Cog', '12'],
          output: ['Name? Cog', 'Level? 12', 'Hi, Cog'],
        ),
        TestCase(
          inputs: ['Bob', '5'],
          output: ['Name? Bob', 'Level? 5', 'Hi, Bob'],
        ),
        TestCase(
          inputs: ['Bob', '9'],
          output: ['Name? Bob', 'Level? 9', 'Hi, Bob'],
        ),
      ],
    ),
  ],
);
