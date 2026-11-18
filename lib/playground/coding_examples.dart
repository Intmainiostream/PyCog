import '../models/lesson_card.dart';

/// A starter program for the CODING playground, taken from the lessons.
class CodingExample {
  const CodingExample({
    required this.title,
    required this.code,
    this.answers = const [],
  });

  final LocalizedText title;

  /// Python code (the same in every language).
  final String code;

  /// Typed answers for input(), if the program asks for any.
  final List<String> answers;
}

/// The Examples menu, in lesson order. Every program was run in real
/// Python, and integration_test/python_runner_test.dart runs them again on
/// a device.
final List<CodingExample> codingExamples = [
  CodingExample(
    title: (l10n) => l10n.codingExampleHello,
    code: 'print("Hi, I am Cog!")',
  ),
  CodingExample(
    title: (l10n) => l10n.codingExampleVariables,
    code: 'battery = 100\nprint(battery)\nbattery = 80\nprint(battery)',
  ),
  CodingExample(
    title: (l10n) => l10n.codingExampleIf,
    code:
        'battery = 10\n'
        'if battery < 20:\n'
        '    print("Low battery!")\n'
        'else:\n'
        '    print("Battery OK")',
  ),
  CodingExample(
    title: (l10n) => l10n.codingExampleFor,
    code: 'for step in range(3):\n    print("Step", step)',
  ),
  CodingExample(
    title: (l10n) => l10n.codingExampleFunction,
    code: 'def add(a, b):\n    return a + b\n\nprint(add(2, 3))',
  ),
  CodingExample(
    title: (l10n) => l10n.codingExampleInput,
    code:
        'name = input("Your name? ")\n'
        'age = int(input("Age? "))\n'
        'print("Hi, " + name)\n'
        'print("Next year:", age + 1)',
    answers: ['Ana', '12'],
  ),
];
