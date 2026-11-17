import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// What the code on a lesson card prints when it runs, shown as a light
/// "screen" under the dark code box, one printed line per row.
///
/// It looks different from the code box on purpose (light, not dark), so
/// students can tell "the code" from "what appears on the screen".
class OutputBox extends StatelessWidget {
  const OutputBox({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).lessonOutputLabel;
    final media = MediaQuery.of(context);

    return Semantics(
      container: true,
      label: '$label: ${lines.join(', ')}',
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
              child: _OutputLines(lines: lines),
            ),
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
  const _OutputLines({required this.lines});

  final List<String> lines;

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
              for (final line in lines)
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
