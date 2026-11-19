import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 8: Lesson 8 (Lists), plus Lessons 1-7. Making a list
/// with `[ ]`, the first item is `[0]`, going too far is an error,
/// changing an item, `len()`, `.append()`, `for item in items:` and `in`.
/// Python prints a list with `'` quotes. There is no input(), so each code
/// challenge has one hidden test, and every fix and write challenge lists
/// required code with the full line in it (a list may be written over
/// several lines; `'` and `"` count as the same).
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
/// The backpack list from the lesson, written over several lines.
const _backpackCode =
    'items = ["sword",\n'
    '         "shield",\n'
    '         "potion"]';

final level8 = MinigameLevel(
  number: 8,
  challenges: [
    // 1. Pick an item with [ ]: [2] is the third item.
    Challenge.quiz(
      id: 'mgL8C1',
      title: (l10n) => l10n.mgL8C1Title,
      prompt: (l10n) => l10n.mgL8C1Prompt,
      code: const [
        CodeLine('scores = [10, 25, 7]'),
        CodeLine('print(scores[2])'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`7`', correct: true),
        QuizAnswer(label: (_) => '`25`'),
        QuizAnswer(label: (_) => '`10`'),
      ],
    ),

    // 2. The first item is [0]; [3] goes too far.
    Challenge.fillBlank(
      id: 'mgL8C2',
      title: (l10n) => l10n.mgL8C2Title,
      prompt: (l10n) => l10n.mgL8C2Prompt,
      hints: [(l10n) => l10n.mgL8C2Hint1, (l10n) => l10n.mgL8C2Hint2],
      template: '$_backpackCode\nprint(items[$blankMarker])',
      choices: const ['0', '1', '3'],
      solution: '0',
      tests: const [
        TestCase(output: ['sword']),
      ],
    ),

    // 3. .append() adds at the end.
    Challenge.writeCode(
      id: 'mgL8C3',
      title: (l10n) => l10n.mgL8C3Title,
      prompt: (l10n) => l10n.mgL8C3Prompt,
      hints: [(l10n) => l10n.mgL8C3Hint1, (l10n) => l10n.mgL8C3Hint2],
      solution:
          'bag = ["map", "key"]\n'
          'bag.append("rope")\n'
          'print(bag)',
      requiredCode: const [
        'bag = ["map", "key"]',
        'bag.append("rope")',
        'print(bag)',
      ],
      tests: const [
        TestCase(output: ["['map', 'key', 'rope']"]),
      ],
    ),

    // 4. in asks if an item is in the list.
    Challenge.quiz(
      id: 'mgL8C4',
      title: (l10n) => l10n.mgL8C4Title,
      prompt: (l10n) => l10n.mgL8C4Prompt,
      code: const [CodeLine('nums = [3, 8, 5]'), CodeLine('print(4 in nums)')],
      answers: [
        QuizAnswer(label: (_) => '`False`', correct: true),
        QuizAnswer(label: (_) => '`True`'),
        QuizAnswer(label: (_) => '`4`'),
      ],
    ),

    // 5. Change one item with [ ] and = (typed).
    Challenge.fillBlank(
      id: 'mgL8C5',
      title: (l10n) => l10n.mgL8C5Title,
      prompt: (l10n) => l10n.mgL8C5Prompt,
      hints: [(l10n) => l10n.mgL8C5Hint1, (l10n) => l10n.mgL8C5Hint2],
      template:
          'items = ["sword", "shield"]\n'
          '$blankMarker = "axe"\n'
          'print(items)',
      solution: 'items[0]',
      tests: const [
        TestCase(output: ["['axe', 'shield']"]),
      ],
    ),

    // 6. Going too far: with 3 items, the last one is [2].
    Challenge.fixBug(
      id: 'mgL8C6',
      title: (l10n) => l10n.mgL8C6Title,
      prompt: (l10n) => l10n.mgL8C6Prompt,
      hints: [(l10n) => l10n.mgL8C6Hint1, (l10n) => l10n.mgL8C6Hint2],
      starter: '$_backpackCode\nprint(items[3])',
      solution: '$_backpackCode\nprint(items[2])',
      requiredCode: const ['print(items[2])'],
      tests: const [
        TestCase(output: ['potion']),
      ],
    ),

    // 7. A for loop goes through the list, one item at a time.
    Challenge.quiz(
      id: 'mgL8C7',
      title: (l10n) => l10n.mgL8C7Title,
      prompt: (l10n) => l10n.mgL8C7Prompt,
      code: const [
        CodeLine('nums = [2, 4, 6]'),
        CodeLine('for n in nums:'),
        CodeLine('    print(n + 1)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`3, 5, 7`', correct: true),
        QuizAnswer(label: (_) => '`2, 4, 6`'),
        QuizAnswer(label: (_) => '`3, 4, 5`'),
      ],
    ),

    // 8. Two bugs: .append[ ] instead of .append( ), and [3] goes too far.
    Challenge.fixBug(
      id: 'mgL8C8',
      title: (l10n) => l10n.mgL8C8Title,
      prompt: (l10n) => l10n.mgL8C8Prompt,
      hints: [(l10n) => l10n.mgL8C8Hint1, (l10n) => l10n.mgL8C8Hint2],
      starter:
          'team = ["Cog", "Bolt"]\n'
          'team.append["Zip"]\n'
          'print(team[3])',
      solution:
          'team = ["Cog", "Bolt"]\n'
          'team.append("Zip")\n'
          'print(team[2])',
      requiredCode: const ['team.append("Zip")', 'print(team[2])'],
      tests: const [
        TestCase(output: ['Zip']),
      ],
    ),

    // 9. in inside an if, then a for loop over the list.
    Challenge.writeCode(
      id: 'mgL8C9',
      title: (l10n) => l10n.mgL8C9Title,
      prompt: (l10n) => l10n.mgL8C9Prompt,
      hints: [(l10n) => l10n.mgL8C9Hint1, (l10n) => l10n.mgL8C9Hint2],
      solution:
          'items = ["key", "map"]\n'
          'if "key" in items:\n'
          '    print("Door open!")\n'
          'for item in items:\n'
          '    print(item)',
      requiredCode: const [
        'items = ["key", "map"]',
        'if "key" in items',
        'for item in items',
        'print(item)',
      ],
      tests: const [
        TestCase(output: ['Door open!', 'key', 'map']),
      ],
    ),

    // 10. The whole lesson: append, change an item, loop, and len().
    Challenge.writeCode(
      id: 'mgL8C10',
      title: (l10n) => l10n.mgL8C10Title,
      prompt: (l10n) => l10n.mgL8C10Prompt,
      hints: [(l10n) => l10n.mgL8C10Hint1, (l10n) => l10n.mgL8C10Hint2],
      solution:
          'scores = [5, 8]\n'
          'scores.append(10)\n'
          'scores[0] = 6\n'
          'for s in scores:\n'
          '    print(s * 2)\n'
          'print(len(scores))',
      requiredCode: const [
        'scores = [5, 8]',
        'scores.append(10)',
        'scores[0] = 6',
        'for s in scores',
        AnyOf(['print(s * 2)', 'print(2 * s)', 'print(s + s)']),
        'print(len(scores))',
      ],
      tests: const [
        TestCase(output: ['12', '16', '20', '3']),
      ],
    ),
  ],
);
