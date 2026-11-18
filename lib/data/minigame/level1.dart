import '../../models/lesson_card.dart';
import '../../models/minigame.dart';
import '../../models/quiz.dart';

/// MINIGAME Level 1. Every answer, solution and expected output was run in
/// real Python; integration_test/minigame_solutions_test.dart runs the
/// solutions against the hidden tests again on a device.
final level1 = MinigameLevel(
  number: 1,
  challenges: [
    Challenge.quiz(
      id: 'mgL1C1',
      title: (l10n) => l10n.mgL1C1Title,
      prompt: (l10n) => l10n.mgL1C1Prompt,
      code: const [
        CodeLine('battery = 50'),
        CodeLine('battery = battery + 10'),
        CodeLine('print(battery)'),
      ],
      answers: [
        QuizAnswer(label: (_) => '`60`', correct: true),
        QuizAnswer(label: (_) => '`50`'),
        QuizAnswer(label: (_) => '`10`'),
        QuizAnswer(label: (_) => '`battery`'),
      ],
    ),
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
    Challenge.writeCode(
      id: 'mgL1C3',
      title: (l10n) => l10n.mgL1C3Title,
      prompt: (l10n) => l10n.mgL1C3Prompt,
      hints: [(l10n) => l10n.mgL1C3Hint1, (l10n) => l10n.mgL1C3Hint2],
      solution: 'age = int(input("Age? "))\nprint(age + 1)',
      showFirstTest: true,
      tests: const [
        TestCase(inputs: ['12'], output: ['Age? 12', '13']),
        TestCase(inputs: ['0'], output: ['Age? 0', '1']),
        TestCase(inputs: ['99'], output: ['Age? 99', '100']),
      ],
    ),
  ],
);
