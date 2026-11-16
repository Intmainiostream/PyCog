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
}

/// Whether a code line is a good or bad example (shown as a ✓ or ✗ badge).
enum CodeMark { none, good, bad }

/// One line in a code example.
class CodeLine {
  const CodeLine(this.code, {this.mark = CodeMark.none});

  final String code;
  final CodeMark mark;
}

/// A variable drawn as a labeled box: name on the label, value inside.
class VariableBoxData {
  const VariableBoxData(this.name, this.value, {this.oldValue});

  final String name;
  final String value;

  /// If set, shown crossed out above the value (the value it used to have).
  final String? oldValue;
}
