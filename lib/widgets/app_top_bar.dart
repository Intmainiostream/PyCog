import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';
import 'star_counter.dart';

/// Stars on the left, app name in the middle, gear on the right; optionally a
/// back arrow before the stars. Shared by the home screen and the trail.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.sidePadding,
    required this.stars,
    required this.onSettings,
    this.onBack,
    this.backLabel,
  });

  final double sidePadding;
  final int stars;
  final VoidCallback onSettings;

  /// Shows a back arrow when set.
  final VoidCallback? onBack;

  /// What screen readers say for the back arrow.
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        AppSizes.gap12,
        sidePadding,
        AppSizes.gap8,
      ),
      // The back arrow (if any) sits in front, always at full touch size.
      // After it, two equal side slots keep the title centered; the star
      // counter may shrink a little on tiny screens with huge text instead
      // of overflowing.
      child: Row(
        children: [
          if (onBack != null) ...[
            ChunkyButton(
              circle: true,
              width: AppSizes.minTouchTarget,
              height: AppSizes.minTouchTarget,
              padding: EdgeInsets.zero,
              color: AppColors.surface,
              semanticLabel: backLabel,
              onTap: onBack,
              child: const Icon(Icons.arrow_back_rounded, size: 28),
            ),
            const SizedBox(width: AppSizes.gap8),
          ],
          Expanded(child: _starsTitleGear(l10n)),
        ],
      ),
    );
  }

  Widget _starsTitleGear(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The title may shrink on tiny screens with huge text, so each side
        // slot always keeps room for a full 48px button.
        const sideMin = AppSizes.minTouchTarget + AppSizes.gap8;
        final titleMax = math.max(0.0, constraints.maxWidth - 2 * sideMin);
        return _row(l10n, titleMax);
      },
    );
  }

  Widget _row(AppLocalizations l10n, double titleMax) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StarCounter(stars: stars),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: titleMax),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.gap8),
              child: Text(
                l10n.appTitle,
                style: AppTextStyles.title.copyWith(color: AppColors.tealDark),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ChunkyButton(
              circle: true,
              width: AppSizes.minTouchTarget,
              height: AppSizes.minTouchTarget,
              padding: EdgeInsets.zero,
              color: AppColors.surface,
              semanticLabel: l10n.settingsTooltip,
              onTap: onSettings,
              child: const Icon(Icons.settings_rounded, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}
