import 'package:material_ui/material_ui.dart';

import '../models/lesson_card.dart';
import '../theme/app_theme.dart';

/// A small True/False table on a lesson card (e.g. every combination for
/// `and`), as a cream sticker card.
///
/// Each value is a chip with the word `True` or `False` in the code font:
/// True on yellow-green, False on soft coral. The words are always shown,
/// so the colors are never the only signal. The last column (the result)
/// is bold.
class TruthTable extends StatelessWidget {
  const TruthTable({super.key, required this.data});

  final TruthTableData data;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final last = data.headings.length - 1;

    // Screen readers hear each row as a sentence, e.g.
    // "a True, b False, a and b False".
    final spoken = [
      for (final row in data.rows)
        [
          for (final (i, value) in row.indexed)
            '${data.headings[i]} ${value ? 'True' : 'False'}',
        ].join(', '),
    ].join('. ');

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.gap12),
        decoration: AppDecorations.card(color: AppColors.surface),
        // Same text-size cap as the code box, so the table always fits.
        child: MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              maxScaleFactor: AppSizes.maxCodeTextScale,
            ),
          ),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: AppColors.locked, width: 1.5),
            ),
            children: [
              TableRow(
                children: [
                  for (final (i, heading) in data.headings.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.gap8),
                      child: Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: _codeStyle(i == last)
                            .copyWith(color: AppColors.tealDark),
                      ),
                    ),
                ],
              ),
              for (final row in data.rows)
                TableRow(
                  children: [
                    for (final (i, value) in row.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: _ValueChip(value: value, bold: i == last),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _codeStyle(bool bold) => AppTextStyles.code.copyWith(
  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
  fontVariations: [FontVariation.weight(bold ? 800 : 600)],
);

/// `True` (yellow-green) or `False` (soft coral), in the code font.
class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.value, required this.bold});

  final bool value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: value ? AppColors.success : AppColors.hintBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outline, width: bold ? 2 : 1),
      ),
      child: Text(
        value ? 'True' : 'False',
        softWrap: false,
        style: _codeStyle(bold).copyWith(color: AppColors.text),
      ),
    );
  }
}
