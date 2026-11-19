import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 9: Lesson 9 (Input and Output), plus Lessons 1-8.
/// `print` with commas (Python adds the spaces) and with `+` (you add
/// them), `input("question ")`, `input()` always gives text, `int()` turns
/// it into a whole number. The first level with input(): the problem text
/// names the exact question, and every code challenge that asks has 2+
/// hidden tests with different typed answers, so a fixed answer can't
/// pass. The expected output shows each question with the typed answer,
/// like the CODING output box. No "must use" pieces: the tests already
/// need the right code.
///
/// Every answer, solution, starting code, wrong choice and expected output
/// was run in real Python with the typed answers;
/// integration_test/minigame_solutions_test.dart runs them again on a
/// device.
final level9 = MinigameLevel(
  number: 9,
  challenges: [
    // 1. print with a comma adds a space.
    Challenge.quiz(
      id: 'mgL9C1',
      title: (l10n) => l10n.mgL9C1Title,
      prompt: (l10n) => l10n.mgL9C1Prompt,
      code: const [CodeLine('print("Score:", 10)')],
      answers: [
        QuizAnswer(label: (_) => '`Score: 10`', correct: true),
        QuizAnswer(label: (_) => '`Score:10`'),
        QuizAnswer(label: (_) => '`Score: , 10`'),
      ],
    ),

    // 2. Use what the person typed.
    Challenge.fillBlank(
      id: 'mgL9C2',
      title: (l10n) => l10n.mgL9C2Title,
      prompt: (l10n) => l10n.mgL9C2Prompt,
      hints: [(l10n) => l10n.mgL9C2Hint1, (l10n) => l10n.mgL9C2Hint2],
      template:
          'name = input("Name? ")\n'
          'print("Hi, " + $blankMarker)',
      choices: const ['name', '"name"', 'Name'],
      solution: 'name',
      tests: const [
        TestCase(inputs: ['Ana'], output: ['Name? Ana', 'Hi, Ana']),
        TestCase(inputs: ['Ben'], output: ['Name? Ben', 'Hi, Ben']),
      ],
    ),

    // 3. Ask with input(), answer with print and a comma.
    Challenge.writeCode(
      id: 'mgL9C3',
      title: (l10n) => l10n.mgL9C3Title,
      prompt: (l10n) => l10n.mgL9C3Prompt,
      hints: [(l10n) => l10n.mgL9C3Hint1, (l10n) => l10n.mgL9C3Hint2],
      solution: 'name = input("Name? ")\nprint("Hi,", name)',
      tests: const [
        TestCase(inputs: ['Ana'], output: ['Name? Ana', 'Hi, Ana']),
        TestCase(inputs: ['Cog'], output: ['Name? Cog', 'Hi, Cog']),
      ],
    ),

    // 4. input() always gives text: "12" + "1" is "121".
    Challenge.quiz(
      id: 'mgL9C4',
      title: (l10n) => l10n.mgL9C4Title,
      prompt: (l10n) => l10n.mgL9C4Prompt,
      code: const [
        CodeLine('age = input("Age? ")'),
        CodeLine('print(age + "1")'),
      ],
      typed: const ['12'],
      answers: [
        QuizAnswer(label: (_) => '`121`', correct: true),
        QuizAnswer(label: (_) => '`13`'),
        QuizAnswer(label: (_) => '`12 1`'),
      ],
    ),

    // 5. int() turns the typed text into a number (typed).
    Challenge.fillBlank(
      id: 'mgL9C5',
      title: (l10n) => l10n.mgL9C5Title,
      prompt: (l10n) => l10n.mgL9C5Prompt,
      hints: [(l10n) => l10n.mgL9C5Hint1, (l10n) => l10n.mgL9C5Hint2],
      template:
          'age = $blankMarker(input("Age? "))\n'
          'print(age + 1)',
      solution: 'int',
      tests: const [
        TestCase(inputs: ['12'], output: ['Age? 12', '13']),
        TestCase(inputs: ['30'], output: ['Age? 30', '31']),
      ],
    ),

    // 6. Text + a number is an error: add int().
    Challenge.fixBug(
      id: 'mgL9C6',
      title: (l10n) => l10n.mgL9C6Title,
      prompt: (l10n) => l10n.mgL9C6Prompt,
      hints: [(l10n) => l10n.mgL9C6Hint1, (l10n) => l10n.mgL9C6Hint2],
      starter: 'age = input("Age? ")\nprint(age + 1)',
      solution: 'age = int(input("Age? "))\nprint(age + 1)',
      tests: const [
        TestCase(inputs: ['9'], output: ['Age? 9', '10']),
        TestCase(inputs: ['15'], output: ['Age? 15', '16']),
      ],
    ),

    // 7. + adds no space: "Hi" + "Cog" is "HiCog".
    Challenge.quiz(
      id: 'mgL9C7',
      title: (l10n) => l10n.mgL9C7Title,
      prompt: (l10n) => l10n.mgL9C7Prompt,
      code: const [
        CodeLine('name = input("Name? ")'),
        CodeLine('print("Hi" + name)'),
      ],
      typed: const ['Cog'],
      answers: [
        QuizAnswer(label: (_) => '`HiCog`', correct: true),
        QuizAnswer(label: (_) => '`Hi Cog`'),
        QuizAnswer(label: (_) => '`Hi, Cog`'),
      ],
    ),

    // 8. Two bugs: the question has no space at the end, and text * 2
    // repeats the text (44, not 8).
    Challenge.fixBug(
      id: 'mgL9C8',
      title: (l10n) => l10n.mgL9C8Title,
      prompt: (l10n) => l10n.mgL9C8Prompt,
      hints: [(l10n) => l10n.mgL9C8Hint1, (l10n) => l10n.mgL9C8Hint2],
      starter: 'n = input("Number?")\nprint(n * 2)',
      solution: 'n = int(input("Number? "))\nprint(n * 2)',
      tests: const [
        TestCase(inputs: ['4'], output: ['Number? 4', '8']),
        TestCase(inputs: ['7'], output: ['Number? 7', '14']),
      ],
    ),

    // 9. Two questions, two int()s, and a comma in print.
    Challenge.writeCode(
      id: 'mgL9C9',
      title: (l10n) => l10n.mgL9C9Title,
      prompt: (l10n) => l10n.mgL9C9Prompt,
      hints: [(l10n) => l10n.mgL9C9Hint1, (l10n) => l10n.mgL9C9Hint2],
      solution:
          'a = int(input("First? "))\n'
          'b = int(input("Second? "))\n'
          'print("Total:", a + b)',
      tests: const [
        TestCase(
          inputs: ['2', '3'],
          output: ['First? 2', 'Second? 3', 'Total: 5'],
        ),
        TestCase(
          inputs: ['10', '7'],
          output: ['First? 10', 'Second? 7', 'Total: 17'],
        ),
      ],
    ),

    // 10. The whole lesson: text and a number from input(), int(), and
    // print with commas.
    Challenge.writeCode(
      id: 'mgL9C10',
      title: (l10n) => l10n.mgL9C10Title,
      prompt: (l10n) => l10n.mgL9C10Prompt,
      hints: [(l10n) => l10n.mgL9C10Hint1, (l10n) => l10n.mgL9C10Hint2],
      solution:
          'name = input("Name? ")\n'
          'age = int(input("Age? "))\n'
          'print(name, "is", age)\n'
          'print("Next year:", age + 1)',
      tests: const [
        TestCase(
          inputs: ['Ana', '12'],
          output: ['Name? Ana', 'Age? 12', 'Ana is 12', 'Next year: 13'],
        ),
        TestCase(
          inputs: ['Cog', '3'],
          output: ['Name? Cog', 'Age? 3', 'Cog is 3', 'Next year: 4'],
        ),
      ],
    ),
  ],
);
