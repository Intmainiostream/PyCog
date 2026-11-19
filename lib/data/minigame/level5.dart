import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 5: Lesson 5 (Functions), plus Lessons 1-4. `def` makes a
/// function but does not run it, calling it with `()` does, parameters
/// (`def greet(name):`), `return` (with `a + b`), "print is not return"
/// (`None`), and an `if` inside a function. There is no input(), so each
/// code challenge has one hidden test, and every fix and write challenge
/// lists required code (the def line, the call, the return line), so
/// printing the answer can't pass.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python; integration_test/minigame_solutions_test.dart
/// runs them again on a device.
final level5 = MinigameLevel(
  number: 5,
  challenges: [
    // 1. def only makes the function; nothing runs until it is called.
    Challenge.quiz(
      id: 'mgL5C1',
      title: (l10n) => l10n.mgL5C1Title,
      prompt: (l10n) => l10n.mgL5C1Prompt,
      code: const [
        CodeLine('def cheer():'),
        CodeLine('    print("Go!")'),
        CodeLine('print("Ready")'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`Ready`', correct: true),
        QuizAnswer(label: (_) => '`Go!, Ready`'),
        QuizAnswer(label: (_) => '`Ready, Go!`'),
      ],
    ),

    // 2. The value of a call goes into the parameter.
    Challenge.fillBlank(
      id: 'mgL5C2',
      title: (l10n) => l10n.mgL5C2Title,
      prompt: (l10n) => l10n.mgL5C2Prompt,
      hints: [(l10n) => l10n.mgL5C2Hint1, (l10n) => l10n.mgL5C2Hint2],
      template:
          'def greet(name):\n'
          '    print("Hi,", name)\n'
          'greet($blankMarker)',
      choices: const ['"Ana"', 'Ana', 'name'],
      solution: '"Ana"',
      tests: const [
        TestCase(output: ['Hi, Ana']),
      ],
    ),

    // 3. Make a function with a parameter, then call it.
    Challenge.writeCode(
      id: 'mgL5C3',
      title: (l10n) => l10n.mgL5C3Title,
      prompt: (l10n) => l10n.mgL5C3Prompt,
      hints: [(l10n) => l10n.mgL5C3Hint1, (l10n) => l10n.mgL5C3Hint2],
      solution:
          'def hello(name):\n'
          '    print("Hi,", name)\n'
          'hello("Cog")',
      requiredCode: const [
        'def hello(name):',
        'print("Hi,", name)',
        'hello("Cog")',
      ],
      tests: const [
        TestCase(output: ['Hi, Cog']),
      ],
    ),

    // 4. return gives a value back.
    Challenge.quiz(
      id: 'mgL5C4',
      title: (l10n) => l10n.mgL5C4Title,
      prompt: (l10n) => l10n.mgL5C4Prompt,
      code: const [
        CodeLine('def add(a, b):'),
        CodeLine('    return a + b'),
        CodeLine('print(add(4, 3))'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`7`', correct: true),
        QuizAnswer(label: (_) => '`43`'),
        QuizAnswer(label: (_) => '`a + b`'),
      ],
    ),

    // 5. return (typed): without it, the function gives back None.
    Challenge.fillBlank(
      id: 'mgL5C5',
      title: (l10n) => l10n.mgL5C5Title,
      prompt: (l10n) => l10n.mgL5C5Prompt,
      hints: [(l10n) => l10n.mgL5C5Hint1, (l10n) => l10n.mgL5C5Hint2],
      template:
          'def double(n):\n'
          '    $blankMarker n + n\n'
          'print(double(4))',
      solution: 'return',
      tests: const [
        TestCase(output: ['8']),
      ],
    ),

    // 6. print is not return: the variable got None.
    Challenge.fixBug(
      id: 'mgL5C6',
      title: (l10n) => l10n.mgL5C6Title,
      prompt: (l10n) => l10n.mgL5C6Prompt,
      hints: [(l10n) => l10n.mgL5C6Hint1, (l10n) => l10n.mgL5C6Hint2],
      starter:
          'def add(a, b):\n'
          '    print(a + b)\n'
          'result = add(2, 3)\n'
          'print(result)',
      solution:
          'def add(a, b):\n'
          '    return a + b\n'
          'result = add(2, 3)\n'
          'print(result)',
      requiredCode: const ['result = add(2, 3)', 'print(result)'],
      tests: const [
        TestCase(output: ['5']),
      ],
    ),

    // 7. A function without return gives back None.
    Challenge.quiz(
      id: 'mgL5C7',
      title: (l10n) => l10n.mgL5C7Title,
      prompt: (l10n) => l10n.mgL5C7Prompt,
      code: const [
        CodeLine('def say(word):'),
        CodeLine('    print(word)'),
        CodeLine('x = say("Hi")'),
        CodeLine('print(x)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`Hi, None`', correct: true),
        QuizAnswer(label: (_) => '`Hi, Hi`'),
        QuizAnswer(label: (_) => '`None`'),
      ],
    ),

    // 8. Two bugs: no colon after def, and a call without ().
    Challenge.fixBug(
      id: 'mgL5C8',
      title: (l10n) => l10n.mgL5C8Title,
      prompt: (l10n) => l10n.mgL5C8Prompt,
      hints: [(l10n) => l10n.mgL5C8Hint1, (l10n) => l10n.mgL5C8Hint2],
      starter:
          'def cheer(name)\n'
          '    print("Go,", name)\n'
          'cheer',
      solution:
          'def cheer(name):\n'
          '    print("Go,", name)\n'
          'cheer("Cog")',
      requiredCode: const ['def cheer(name):', 'cheer("Cog")'],
      tests: const [
        TestCase(output: ['Go, Cog']),
      ],
    ),

    // 9. An if inside a function, with two returns.
    Challenge.writeCode(
      id: 'mgL5C9',
      title: (l10n) => l10n.mgL5C9Title,
      prompt: (l10n) => l10n.mgL5C9Prompt,
      hints: [(l10n) => l10n.mgL5C9Hint1, (l10n) => l10n.mgL5C9Hint2],
      solution:
          'def check(level):\n'
          '    if level < 20:\n'
          '        return "Low"\n'
          '    else:\n'
          '        return "OK"\n'
          'print(check(10))\n'
          'print(check(80))',
      requiredCode: const [
        'def check(level):',
        'if level < 20',
        'print(check(10))',
        'print(check(80))',
      ],
      tests: const [
        TestCase(output: ['Low', 'OK']),
      ],
    ),

    // 10. The whole lesson: a function with a parameter and return, called
    // in a for loop (Lesson 4).
    Challenge.writeCode(
      id: 'mgL5C10',
      title: (l10n) => l10n.mgL5C10Title,
      prompt: (l10n) => l10n.mgL5C10Prompt,
      hints: [(l10n) => l10n.mgL5C10Hint1, (l10n) => l10n.mgL5C10Hint2],
      solution:
          'def double(n):\n'
          '    return n + n\n'
          'for i in range(1, 4):\n'
          '    print(double(i))',
      requiredCode: const [
        'def double(n):',
        'return n + n',
        'for i in range(1, 4)',
        'print(double(i))',
      ],
      tests: const [
        TestCase(output: ['2', '4', '6']),
      ],
    ),
  ],
);
