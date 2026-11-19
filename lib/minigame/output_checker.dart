import '../models/minigame.dart';
import '../playground/python_runner.dart';

/// What happened when the student's code ran against the hidden tests.
class CheckResult {
  const CheckResult.passed()
    : failedNumber = null,
      failedCase = null,
      got = null,
      wrongQuestion = null,
      missing = const [];

  const CheckResult.failed({
    required int this.failedNumber,
    required TestCase this.failedCase,
    required PythonResult this.got,
    this.wrongQuestion,
  }) : missing = const [];

  /// Every test passed, but the code does not contain these required
  /// pieces.
  const CheckResult.missing(this.missing)
    : failedNumber = null,
      failedCase = null,
      got = null,
      wrongQuestion = null;

  /// Which test failed, counting from 1 (null when every test passed).
  final int? failedNumber;

  /// The first test that failed. Tests after it never ran, so they stay
  /// hidden.
  final TestCase? failedCase;

  /// What the code did in [failedCase].
  final PythonResult? got;

  /// When the test failed because the code asked a different input()
  /// question (or none): the question it should ask, e.g. `Age? `.
  final String? wrongQuestion;

  /// Required code pieces the student's code does not contain (its output
  /// was right). Empty otherwise.
  final List<String> missing;

  bool get passed => failedNumber == null && missing.isEmpty;
}

/// Makes code easy to search for a required piece: `#` comments are removed
/// (a piece inside a comment does not count), every string's quotes become
/// `"` (so `'Hi'` and `"Hi"` match; a quote inside the text stays as it
/// is), and spaces are dropped around `=`, the comparison signs (`==`,
/// `!=`, `<`, `>`, `<=`, `>=`), the math signs (`+`, `-`, `*`, `/`, `//`,
/// `%`, `**`), around commas and just inside brackets. So `speed=5` and
/// `speed = 5`, `lives>0` and `lives > 0`, `battery-1` and `battery - 1`,
/// `range(1,6)` and `range(1, 6)`, `print( speed )` and `print(speed)` all
/// match. The signs stay different: `<` never matches `<=`, `*` never
/// matches `**`, `/` never matches `//`, and `+` never matches `-`.
/// Inside an open bracket, line breaks and indentation don't matter, so a
/// list written over several lines matches the same list on one line.
/// Several spaces between words count as one (`a  and b` is `a and b`).
String normalizeCode(String code) {
  return _flatten(code.replaceAll('\r\n', '\n'))
      // Several spaces or tabs count as one space (`a  and b` is
      // `a and b`). Line breaks are not touched.
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      // Longest signs first, so `<=`, `**` and `//` stay whole.
      .replaceAllMapped(
        RegExp(r'[ \t]*(==|!=|<=|>=|\*\*|//|<|>|=|\+|-|\*|/|%|,)[ \t]*'),
        (m) => m[1]!,
      )
      .replaceAllMapped(RegExp(r'([(\[{])[ \t]+'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'[ \t]+([)\]}])'), (m) => m[1]!);
}

/// One pass over the code: drops `#` comments (a `#` inside quotes is
/// text), writes each string's opening and closing quote as `"` (the text
/// inside is kept, so an apostrophe in "It's" stays an apostrophe), and
/// inside an open bracket (`(`, `[` or `{`) turns a line break and the
/// indentation after it into one space, so a list written over several
/// lines reads like one line. A bracket inside quotes does not count.
String _flatten(String code) {
  final out = StringBuffer();
  String? quote; // the quote that opened the current string
  var depth = 0; // open brackets
  var inComment = false;
  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (c == '\n') {
      inComment = false;
      quote = null; // a string never goes past the end of its line
      if (depth > 0) {
        out.write(' ');
        while (i + 1 < code.length &&
            (code[i + 1] == ' ' || code[i + 1] == '\t')) {
          i++;
        }
      } else {
        out.write(c);
      }
    } else if (inComment) {
      // skip the comment
    } else if (quote != null) {
      if (c == r'\' && i + 1 < code.length && code[i + 1] != '\n') {
        out
          ..write(c)
          ..write(code[i + 1]);
        i++; // the escaped letter is text
      } else if (c == quote) {
        out.write('"');
        quote = null;
      } else {
        out.write(c);
      }
    } else if (c == '"' || c == "'") {
      out.write('"');
      quote = c;
    } else if (c == '#') {
      inComment = true;
    } else {
      if (c == '(' || c == '[' || c == '{') depth++;
      if ((c == ')' || c == ']' || c == '}') && depth > 0) depth--;
      out.write(c);
    }
  }
  return out.toString();
}

/// The required pieces that [code] does not contain (see [normalizeCode]
/// for what does not matter). Each piece is a [String] or an [AnyOf]: an
/// [AnyOf] counts when any one of its options is there. A missing piece is
/// listed by its first option. Empty when all are there.
List<String> missingCode(String code, List<Object> required) {
  final normalized = normalizeCode(code);
  return [
    for (final piece in required)
      if (!pieceOptions(piece)
          .any((option) => normalized.contains(normalizeCode(option))))
        pieceOptions(piece).first,
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
  List<Object> required = const [],
}) async {
  for (final (i, test) in tests.indexed) {
    final result = await engine.run(code, inputs: test.inputs);
    final ok = result.ok && outputMatches(result.stdout, test.output);
    if (!ok) {
      return CheckResult.failed(
        failedNumber: i + 1,
        failedCase: test,
        got: result,
        wrongQuestion: wrongQuestion(test, result),
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

/// The input() questions [result] asked, in order: the text on the line
/// before each typed answer, e.g. `Age? ` for `Age? 12`.
List<String> askedQuestions(PythonResult result) => [
  for (final answer in result.typed)
    result.stdout.substring(
      answer.offset == 0
          ? 0
          : result.stdout.lastIndexOf('\n', answer.offset - 1) + 1,
      answer.offset,
    ),
];

/// The input() questions [test] expects, in order (from its output lines
/// and typed answers).
List<String> expectedQuestions(TestCase test) {
  final (rows, typed) = splitExpected(test.output, test.inputs);
  return [for (final row in typed.keys.toList()..sort()) rows[row]];
}

/// When [result] asked a different input() question than [test] expects,
/// or asked none at all: the question it should have asked. Null when the
/// questions are right (the test failed for another reason) or the test
/// asks nothing.
String? wrongQuestion(TestCase test, PythonResult result) {
  final expected = expectedQuestions(test);
  if (expected.isEmpty) return null;
  final asked = askedQuestions(result);
  if (asked.isEmpty) return expected.first;
  for (var i = 0; i < expected.length && i < asked.length; i++) {
    if (asked[i] != expected[i]) return expected[i];
  }
  return null;
}
