import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';
import 'lesson_progress_bar.dart';

/// Shared by the lesson and quiz screens.
/// X on the left, progress bar in the middle, gear on the right.
class LessonTopBar extends StatelessWidget {
  const LessonTopBar({
    super.key,
    required this.sidePadding,
    required this.current,
    required this.total,
    required this.progressLabel,
    required this.closeLabel,
    required this.onClose,
    required this.onSettings,
  });

  final double sidePadding;
  final int current;
  final int total;

  /// What screen readers say for the bar, e.g. "Card 2 of 5".
  final String progressLabel;

  /// What screen readers say for the X button.
  final String closeLabel;
  final VoidCallback onClose;
  final VoidCallback onSettings;

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
      child: Row(
        children: [
          ChunkyButton(
            circle: true,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            semanticLabel: closeLabel,
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 28),
          ),
          const SizedBox(width: AppSizes.gap12),
          Expanded(
            // Lift the bar so it lines up with the buttons' faces (not their
            // shadows).
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.shadowDepth),
              child: LessonProgressBar(
                current: current,
                total: total,
                label: progressLabel,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gap8),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.shadowDepth),
              child: Text('$current/$total', style: AppTextStyles.bodyBold),
            ),
          ),
          const SizedBox(width: AppSizes.gap12),
          ChunkyButton(
            circle: true,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            semanticLabel: l10n.settingsTooltip,
            onTap: onSettings,
            child: const Icon(Icons.settings_rounded, size: 28),
          ),
        ],
      ),
    );
  }
}
