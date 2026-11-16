import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Pieces shared by the quiz results and game results screens.

/// Three big stars; earned ones are yellow, the rest light brown.
class StickerStarRow extends StatelessWidget {
  const StickerStarRow({
    super.key,
    required this.stars,
    required this.size,
    required this.label,
  });

  final int stars;
  final double size;

  /// What screen readers say, e.g. "2 stars".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              // The middle star sits a little higher, like a podium.
              padding: EdgeInsets.only(
                left: size * 0.05,
                right: size * 0.05,
                bottom: i == 1 ? size * 0.25 : 0,
              ),
              child: _StickerStar(earned: i < stars, size: size),
            ),
        ],
      ),
    );
  }
}

/// A star with a dark outline (a big dark star behind a smaller colored one).
class _StickerStar extends StatelessWidget {
  const _StickerStar({required this.earned, required this.size});

  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_rounded, size: size, color: AppColors.outline),
        Icon(
          Icons.star_rounded,
          size: size * 0.78,
          color: earned ? AppColors.star : AppColors.locked,
        ),
      ],
    );
  }
}

/// Small outlined pill, e.g. "New best!".
class StickerBadge extends StatelessWidget {
  const StickerBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.gap12,
        vertical: AppSizes.gap4,
      ),
      decoration: AppDecorations.card(
        color: color,
        radius: AppSizes.radiusLarge,
        shadow: false,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyBold,
      ),
    );
  }
}
