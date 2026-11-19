import '../models/minigame.dart';
import '../playground/python_runner.dart';

/// What happened when the student's code ran against the hidden tests.
class CheckResult {
  const CheckResult.passed()
    : failedNumber = null,
      failedCase = null,
      got = null,
      missing = const [];

  const CheckResult.failed({
    required int this.failedNumber,
    required TestCase this.failedCase,
    required PythonResult this.got,
  }) : missing = const [];

  /// Every test passed, but the code does not contain these required
  /// pieces.
  const CheckResult.missing(this.missing)
    : failedNumber = null,
      failedCase = null,
      got = null;

  /// Which test failed, counting from 1 (null when every test passed).
  final int? failedNumber;

  /// The first test that failed. Tests after it never ran, so they stay
  /// hidden.
  final TestCase? failedCase;

  /// What the code did in [failedCase].
  final PythonResult? got;

  /// Required code pieces the student's code does not contain (its output
  /// was right). Empty otherwise.
  final List<String> missing;

  bool get passed => failedNumber == null && missing.isEmpty;
}

/// Makes code easy to search for a required piece: `#` comments are removed
/// (a piece inside a comment does not count), and spaces are dropped around
/// `=`, the comparison signs (`==`, `!=`, `<`, `>`, `<=`, `>=`), the math
/// signs (`+`, `-`, `*`, `/`, `//`, `%`, `**`), around commas and just
/// inside brackets. So `speed=5` and `speed = 5`, `lives>0` and
/// `lives > 0`, `battery-1` and `battery - 1`, `range(1,6)` and
/// `range(1, 6)`, `print( speed )` and `print(speed)` all match. The signs
/// stay different: `<` never matches `<=`, `*` never matches `**`, `/`
/// never matches `//`, and `+` never matches `-`.
String normalizeCode(String code) {
  final lines = [
    for (final line in code.replaceAll('\r\n', '\n').split('\n'))
      _withoutComment(line),
  ];
  return lines
      .join('\n')
      // Longest signs first, so `<=`, `**` and `//` stay whole.
      .replaceAllMapped(
        RegExp(r'[ \t]*(==|!=|<=|>=|\*\*|//|<|>|=|\+|-|\*|/|%|,)[ \t]*'),
        (m) => m[1]!,
      )
      .replaceAllMapped(RegExp(r'([(\[{])[ \t]+'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'[ \t]+([)\]}])'), (m) => m[1]!);
}

/// The line up to a `#` that is not inside quotes.
String _withoutComment(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == r'\') {
        i++; // skip the escaped letter
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '#') {
      return line.substring(0, i);
    }
  }
  return line;
}

/// The [required] pieces that [code] does not contain (see [normalizeCode]
/// for what does not matter). Empty when all are there.
List<String> missingCode(String code, List<String> required) {
  final normalized = normalizeCode(code);
  return [
    for (final piece in required)
      if (!normalized.contains(normalizeCode(piece))) piece,
  ];
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
///
/// Only when every test passes are the [required] pieces checked: if one
/// is missing, the result lists them ([CheckResult.missing]). So a wrong
/// output or a real Python error is always shown first.
Future<CheckResult> checkProgram(
  PythonEngine engine,
  String code,
  List<TestCase> tests, {
  List<String> required = const [],
}) async {
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
  final missing = missingCode(code, required);
  if (missing.isNotEmpty) return CheckResult.missing(missing);
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
