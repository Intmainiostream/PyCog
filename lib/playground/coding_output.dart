import '../l10n/generated/app_localizations.dart';
import 'python_runner.dart';

/// Splits what a program printed into output-box rows, and moves each typed
/// answer (from input()) out of its row so the output box can show it in
/// the "typed by the person" style. Returns the rows and, for each row with
/// an answer, that answer.
(List<String>, Map<int, String>) splitOutput(
  String stdout,
  List<TypedAnswer> typed,
) {
  final text = stdout.endsWith('\n')
      ? stdout.substring(0, stdout.length - 1)
      : stdout;
  final rows = text.isEmpty ? <String>[] : text.split('\n');
  final starts = <int>[];
  var position = 0;
  for (final row in rows) {
    starts.add(position);
    position += row.length + 1;
  }
  final answers = <int, String>{};
  for (final answer in typed) {
    final row = starts.lastIndexWhere((start) => start <= answer.offset);
    if (row < 0) continue;
    final column = answer.offset - starts[row];
    // The answer ends its row (the program reads it, then Enter).
    if (column <= rows[row].length &&
        rows[row].substring(column) == answer.text) {
      rows[row] = rows[row].substring(0, column);
      answers[row] = answer.text;
    }
  }
  return (rows, answers);
}

/// The error's type, e.g. "ValueError" from
/// "ValueError: invalid literal for int() with base 10: 'abc'".
String errorType(String error) => error.split(':').first.trim();

/// True when the program asked for more input() answers than were typed.
bool needsMoreAnswers(String error) => errorType(error) == 'EOFError';

/// True when Python itself could not start.
bool isStartError(String error) => errorType(error) == 'PythonStartError';

/// Cog's one friendly line for an error.
String friendlyTip(AppLocalizations l10n, String error) =>
    switch (errorType(error)) {
      'SyntaxError' => l10n.codingTipSyntax,
      'IndentationError' || 'TabError' => l10n.codingTipIndent,
      'NameError' || 'UnboundLocalError' => l10n.codingTipName,
      'TypeError' => l10n.codingTipType,
      'ValueError' => l10n.codingTipValue,
      'ZeroDivisionError' => l10n.codingTipZero,
      'IndexError' => l10n.codingTipIndex,
      'EOFError' => l10n.codingNeedMoreAnswers,
      'PythonStartError' => l10n.codingStartError,
      'PermissionError' ||
      'ImportError' ||
      'ModuleNotFoundError' => l10n.codingTipBlocked,
      _ => l10n.codingTipOther,
    };
