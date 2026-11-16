import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/lesson_card.dart';
import '../theme/app_theme.dart';

/// A dark, outlined box that shows Python code in the code font, with simple
/// colors for strings, numbers, True/False, `=` and `# comments`.
///
/// Lines can carry an arrow note ("← battery is now 100"). The note sits on
/// the same line when it fits; otherwise it moves directly under its line.
///
/// Code never wraps (a wrapped line of code is confusing). Its text growth is
/// capped, and if a line is still too wide, that line scrolls sideways.
class CodeBox extends StatelessWidget {
  const CodeBox({super.key, required this.lines});

  final List<CodeLine> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasMarks = lines.any((l) => l.mark != CodeMark.none);
    final hasNotes = lines.any((l) => l.note != null);
    final media = MediaQuery.of(context);
    final codeScaler = media.textScaler.clamp(
      maxScaleFactor: AppSizes.maxCodeTextScale,
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _CodeLineView(line: line, hasMarks: hasMarks, l10n: l10n),
          ),
      ],
    );

    return Semantics(
      label: l10n.codeExampleLabel,
      container: true,
      child: MediaQuery(
        data: media.copyWith(textScaler: codeScaler),
        child: Container(
          width: double.infinity,
          decoration: AppDecorations.card(color: AppColors.codeBackground),
          // With notes, each line lays itself out to the box width (notes may
          // wrap). Without notes, the whole box scrolls sideways if needed.
          child: hasNotes
              ? Padding(
                  padding: const EdgeInsets.all(AppSizes.gap16),
                  child: column,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSizes.gap16),
                  child: column,
                ),
        ),
      ),
    );
  }
}

/// The plain code text style inside the dark box.
TextStyle get _codeStyle =>
    AppTextStyles.code.copyWith(color: AppColors.codeText);

/// One code line, plus its badge (✓/✗) and arrow note if it has them.
class _CodeLineView extends StatelessWidget {
  const _CodeLineView({
    required this.line,
    required this.hasMarks,
    required this.l10n,
  });

  final CodeLine line;
  final bool hasMarks;
  final AppLocalizations l10n;

  static const _noteGap = AppSizes.gap16;

  @override
  Widget build(BuildContext context) {
    final code = Text.rich(
      TextSpan(children: highlightPython(line.code)),
      softWrap: false,
      style: _codeStyle,
    );
    final badge = hasMarks
        ? [
            _MarkBadge(mark: line.mark, l10n: l10n),
            const SizedBox(width: AppSizes.gap8),
          ]
        : const <Widget>[];

    final noteText = line.note?.call(l10n);
    if (noteText == null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [...badge, code]);
    }

    // Built once and used for both drawing and measuring, so the "does it
    // fit on the same line?" check matches what's actually drawn.
    final noteSpan = TextSpan(
      style: AppTextStyles.codeNote,
      children: [
        // The body font has no arrow character; the bundled code font does.
        TextSpan(
          text: '← ',
          style: AppTextStyles.codeNote.copyWith(
            fontFamily: AppFonts.code,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w800,
            fontVariations: const [FontVariation.weight(800)],
          ),
        ),
        TextSpan(text: noteText),
      ],
    );
    final note = Text.rich(noteSpan);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(InlineSpan span) => (TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout()).width;

        final badgeWidth = hasMarks ? scaler.scale(22) + AppSizes.gap8 : 0.0;
        final codeWidth = widthOf(
          TextSpan(children: highlightPython(line.code), style: _codeStyle),
        );
        final noteWidth = widthOf(noteSpan);

        // Fits on one line: code, gap, note (with a little safety margin so
        // rounding never makes the note wrap inside the row).
        const safety = 4.0;
        if (badgeWidth + codeWidth + _noteGap + noteWidth + safety <=
            constraints.maxWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...badge,
              code,
              const SizedBox(width: _noteGap),
              Flexible(child: note),
            ],
          );
        }

        // Too narrow: note goes directly under its code line (and may wrap).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...badge,
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: code,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: badgeWidth, top: 2),
              child: note,
            ),
          ],
        );
      },
    );
  }
}

/// Green ✓ / red ✗ in front of good and bad example lines.
class _MarkBadge extends StatelessWidget {
  const _MarkBadge({required this.mark, required this.l10n});

  final CodeMark mark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(22);
    if (mark == CodeMark.none) return SizedBox(width: size, height: size);

    final good = mark == CodeMark.good;
    return Semantics(
      label: good ? l10n.codeGoodLabel : l10n.codeBadLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: good ? AppColors.success : AppColors.red,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.codeText, width: 2),
        ),
        child: Icon(
          good ? Icons.check_rounded : Icons.close_rounded,
          size: size * 0.7,
          color: good ? AppColors.outline : AppColors.surface,
        ),
      ),
    );
  }
}

/// Splits one line of Python into colored pieces. Deliberately tiny: it only
/// knows what the early lessons use. A `#` outside quotes starts a comment
/// that runs to the end of the line (muted and italic, like a real editor).
List<TextSpan> highlightPython(String code) {
  // Numbers may have a decimal point (2.5 is one number, not "2" "." "5").
  final token = RegExp(
    r'"[^"]*"|#.*|\b\d+(?:\.\d+)?\b|\b(?:True|False|None)\b|=',
  );
  final spans = <TextSpan>[];
  var last = 0;
  for (final match in token.allMatches(code)) {
    if (match.start > last) {
      spans.add(TextSpan(text: code.substring(last, match.start)));
    }
    final text = match[0]!;
    final style = switch (text) {
      _ when text.startsWith('#') => const TextStyle(
        color: AppColors.codeComment,
        fontStyle: FontStyle.italic,
      ),
      _ when text.startsWith('"') => const TextStyle(
        color: AppColors.codeString,
      ),
      '=' => const TextStyle(color: AppColors.codeOperator),
      'True' ||
      'False' ||
      'None' => const TextStyle(color: AppColors.codeKeyword),
      _ => const TextStyle(color: AppColors.codeNumber),
    };
    spans.add(TextSpan(text: text, style: style));
    last = match.end;
  }
  if (last < code.length) spans.add(TextSpan(text: code.substring(last)));
  return spans;
}
