import '../models/minigame.dart';
import '../playground/python_runner.dart';

/// What happened when the student's code ran against the hidden tests.
class CheckResult {
  const CheckResult.passed()
    : failedNumber = null,
      failedCase = null,
      got = null;

  const CheckResult.failed({
    required int this.failedNumber,
    required TestCase this.failedCase,
    required PythonResult this.got,
  });

  /// Which test failed, counting from 1 (null when every test passed).
  final int? failedNumber;

  /// The first test that failed. Tests after it never ran, so they stay
  /// hidden.
  final TestCase? failedCase;

  /// What the code did in [failedCase].
  final PythonResult? got;

  bool get passed => failedNumber == null;
}

/// Makes two outputs comparable: spaces and tabs at the end of each line are
/// ignored, and so are empty lines at the very end (print() always adds a
/// new line at the end).
String normalizeOutput(String output) {
  final lines = output
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.replaceFirst(RegExp(r'[ \t]+$'), ''))
      .toList();
  while (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

/// True when [stdout] shows exactly the [expected] lines (see
/// [normalizeOutput] for what is ignored).
bool outputMatches(String stdout, List<String> expected) =>
    normalizeOutput(stdout) == normalizeOutput(expected.join('\n'));

/// Runs [code] once per test, in order, and stops at the first test that
/// fails. A test passes only if the program finished without an error, did
/// not run too long, and printed exactly the expected output.
Future<CheckResult> checkProgram(
  PythonEngine engine,
  String code,
  List<TestCase> tests,
) async {
  for (final (i, test) in tests.indexed) {
    final result = await engine.run(code, inputs: test.inputs);
    final ok = result.ok && outputMatches(result.stdout, test.output);
    if (!ok) {
      return CheckResult.failed(
        failedNumber: i + 1,
        failedCase: test,
        got: result,
      );
    }
  }
  return const CheckResult.passed();
}

/// For showing an expected output in the output box: finds where each typed
/// answer sits (the end of a line, in order) and moves it out of its line,
/// like `splitOutput` does for real runs. Returns the rows and, for each
/// row with an answer, that answer.
(List<String>, Map<int, String>) splitExpected(
  List<String> lines,
  List<String> inputs,
) {
  final rows = [...lines];
  final typed = <int, String>{};
  var from = 0;
  for (final answer in inputs) {
    for (var i = from; i < rows.length; i++) {
      if (rows[i].endsWith(answer)) {
        rows[i] = rows[i].substring(0, rows[i].length - answer.length);
        typed[i] = answer;
        from = i + 1;
        break;
      }
    }
  }
  return (rows, typed);
}
