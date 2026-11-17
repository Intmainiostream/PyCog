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
            // Same text-size cap as the code box: printed lines don't wrap.
            MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  maxScaleFactor: AppSizes.maxCodeTextScale,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line,
                          softWrap: false,
                          style: AppTextStyles.code.copyWith(
                            fontWeight: FontWeight.w700,
                            fontVariations: const [FontVariation.weight(700)],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
