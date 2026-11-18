import '../l10n/generated/app_localizations.dart';

/// A piece of text that changes with the language. It looks up the current
/// translation each time, e.g. `(l10n) => l10n.lesson1Card1Title`.
typedef LocalizedText = String Function(AppLocalizations l10n);

/// One card of a lesson's explanation. The lesson screen shows one at a time.
///
/// Text fields are [LocalizedText] (they change with the language).
/// Code fields are plain strings (code is always the same, in English).
class LessonCard {
  const LessonCard({
    required this.title,
    required this.speech,
    this.boxes = const [],
    this.code = const [],
    this.tip,
    this.output = const [],
    this.typed = const {},
    this.table,
  });

  /// Heading at the top of the card.
  final LocalizedText title;

  /// What Cog says in the speech bubble. Wrap code words in backticks,
  /// like `battery`, to show them in the code font.
  final LocalizedText speech;

  /// Optional picture of variables as labeled boxes.
  final List<VariableBoxData> boxes;

  /// Optional code example, one entry per line.
  final List<CodeLine> code;

  /// Optional short reminder shown under the code.
  final LocalizedText? tip;

  /// Optional lines the code prints when it runs, shown in an "Output" box
  /// under the code (one entry per printed line). Same in every language,
  /// since it's what the program shows. Empty = no output box.
  final List<String> output;

  /// Optional, for code that uses `input()`: what the person types. Maps an
  /// [output] row (by number, from 0) to the answer typed at the end of that
  /// row, right after the question the program printed, e.g.
  /// `{0: 'Ana'}`. The output box shows it in a different style. Empty =
  /// nothing typed (every lesson before Lesson 9).
  final Map<int, String> typed;

  /// Optional True/False table, shown above the code (Lesson 10 on).
  /// Null = no table (every lesson before Lesson 10).
  final TruthTableData? table;
}

/// A small True/False table, e.g. for `and`: every combination of the
/// inputs and the result. The headings are code (the same in every
/// language); the last column is the result.
class TruthTableData {
  const TruthTableData({required this.headings, required this.rows});

  /// Column headings, e.g. `['a', 'b', 'a and b']`.
  final List<String> headings;

  /// One list of values per row, one value per heading.
  final List<List<bool>> rows;
}

/// Whether a code line is a good or bad example (shown as a ✓ or ✗ badge).
enum CodeMark { none, good, bad }

/// One line in a code example.
class CodeLine {
  const CodeLine(this.code, {this.mark = CodeMark.none, this.note});

  final String code;
  final CodeMark mark;

  /// Optional plain-words note shown after the line as "← note" (changes
  /// with the language). Use it on lesson cards only, never in quizzes
  /// (it would give the answer away), and not on `#` comment lines (they
  /// are already notes).
  final LocalizedText? note;
}

/// A variable drawn as a labeled box: name on the label, value inside.
class VariableBoxData {
  const VariableBoxData(this.name, this.value, {this.oldValue});

  final String name;
  final String value;

  /// If set, shown crossed out above the value (the value it used to have).
  final String? oldValue;
}
