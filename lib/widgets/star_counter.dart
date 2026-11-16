import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// The small "⭐ 12" pill at the top of the home screen.
class StarCounter extends StatelessWidget {
  const StarCounter({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).starsCount(stars),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.gap8,
          AppSizes.gap4,
          AppSizes.gap12,
          AppSizes.gap4,
        ),
        decoration: AppDecorations.card(radius: AppSizes.radiusLarge),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.star, size: 28),
            const SizedBox(width: AppSizes.gap4),
            Text('$stars', style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}
