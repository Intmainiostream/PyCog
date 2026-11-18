import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// What the code on a lesson card prints when it runs, shown as a light
/// "screen" under the dark code box, one printed line per row.
///
/// It looks different from the code box on purpose (light, not dark), so
/// students can tell "the code" from "what appears on the screen".
///
/// For code that uses `input()`, [typed] adds what the person types at the
/// end of a row, in a small mint chip with a keyboard icon, and a one-line
/// key under the rows. Without [typed], nothing changes.
class OutputBox extends StatelessWidget {
  const OutputBox({super.key, required this.lines, this.typed = const {}});

  final List<String> lines;

  /// What the person types: output row number -> typed answer.
  final Map<int, String> typed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.lessonOutputLabel;
    final media = MediaQuery.of(context);
    final spoken = [
      for (final (i, line) in lines.indexed)
        typed[i] == null
            ? line
            : '$line${typed[i]} (${l10n.lesson9TypedLabel})',
    ];

    return Semantics(
      container: true,
      label: '$label: ${spoken.join(', ')}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.gap12),
        decoration: AppDecorations.card(color: AppColors.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: media.textScaler.scale(20),
                  color: AppColors.tealDark,
                ),
                const SizedBox(width: AppSizes.gap8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.gap8),
            // Same text-size cap as the code box.
            MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  maxScaleFactor: AppSizes.maxCodeTextScale,
                ),
              ),
              child: _OutputLines(lines: lines, typed: typed),
            ),
            if (typed.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gap8),
              // The key: the keyboard icon means "the person typed this".
              Row(
                children: [
                  Icon(
                    Icons.keyboard_rounded,
                    size: media.textScaler.scale(18),
                    color: AppColors.tealDark,
                  ),
                  const SizedBox(width: AppSizes.gap8),
                  Expanded(
                    child: Text(
                      l10n.lesson9TypedLabel,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The printed lines. A line too long for the box continues on the next
/// row, indented by [outputWrapIndent] spaces, so it doesn't look like a
/// second printed line. (Code letters are all the same width, so "how many
/// fit" is the box width divided by one letter's width.) If that guess is
/// ever a little off, the rows can still be scrolled sideways.
class _OutputLines extends StatelessWidget {
  const _OutputLines({required this.lines, required this.typed});

  final List<String> lines;
  final Map<int, String> typed;

  static final _style = AppTextStyles.code.copyWith(
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
  );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: 'M' * 10, style: _style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final letterWidth = painter.width / 10;
        painter.dispose();
        final columns = constraints.maxWidth.isFinite
            ? (constraints.maxWidth / letterWidth).floor()
            : 1 << 20;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (n, line) in lines.indexed)
                if (typed[n] case final answer?)
                  // A question, then what the person typed (never wrapped:
                  // input questions are short).
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(line, softWrap: false, style: _style),
                        _TypedAnswer(
                          key: ValueKey('typed-$n'),
                          text: answer,
                          style: _style,
                        ),
                      ],
                    ),
                  )
                else
                  for (final (i, row) in wrapOutputLine(line, columns).indexed)
                    Padding(
                      // Rows of one wrapped line sit closer together.
                      padding: EdgeInsets.only(top: i == 0 ? 1 : 0, bottom: 1),
                      child: Text(row, softWrap: false, style: _style),
                    ),
            ],
          ),
        );
      },
    );
  }
}

/// What the person typed: a small mint chip with a keyboard icon, so it
/// can't be mistaken for something the program printed.
class _TypedAnswer extends StatelessWidget {
  const _TypedAnswer({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.tealDark, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_rounded,
            size: MediaQuery.textScalerOf(context).scale(16),
            color: AppColors.tealDark,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            softWrap: false,
            style: style.copyWith(color: AppColors.tealDark),
          ),
        ],
      ),
    );
  }
}

/// How many spaces a wrapped line's next rows are pushed in.
const outputWrapIndent = 2;

/// Splits one printed [line] into rows of at most [columns] letters,
/// breaking at spaces when possible. Rows after the first start with
/// [outputWrapIndent] spaces. A line that fits comes back unchanged.
List<String> wrapOutputLine(String line, int columns) {
  // Too narrow to wrap nicely: leave it on one row (it scrolls sideways).
  if (line.length <= columns || columns < 12) return [line];
  final indent = ' ' * outputWrapIndent;
  final rows = <String>[];
  var rest = line;
  var width = columns;
  while (rest.length > width) {
    var cut = rest.lastIndexOf(' ', width);
    if (cut <= 0) cut = width; // one long word: cut it
    rows.add(rest.substring(0, cut));
    rest = rest.substring(cut).trimLeft();
    width = columns - outputWrapIndent;
  }
  rows.add(rest);
  return [rows.first, for (final r in rows.skip(1)) '$indent$r'];
}
