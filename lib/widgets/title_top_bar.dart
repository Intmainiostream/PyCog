import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'chunky_button.dart';

/// Back arrow, title and gear, like the other screens (the CODING
/// playground and the MINIGAME map).
class TitleTopBar extends StatelessWidget {
  const TitleTopBar({
    super.key,
    required this.padding,
    required this.title,
    required this.backLabel,
    required this.settingsLabel,
    required this.onSettings,
  });

  final double padding;
  final String title;
  final String backLabel;
  final String settingsLabel;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppSizes.gap12,
        padding,
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
            semanticLabel: backLabel,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_rounded, size: 28),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
            ),
          ),
          ChunkyButton(
            circle: true,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            semanticLabel: settingsLabel,
            onTap: onSettings,
            child: const Icon(Icons.settings_rounded, size: 28),
          ),
        ],
      ),
    );
  }
}
