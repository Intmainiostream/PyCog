import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Outlined progress bar that fills with teal as the student moves through
/// the cards. [current] starts at 1.
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;

  /// What screen readers say, e.g. "Card 2 of 5".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: AppSizes.progressBarHeight,
        decoration: AppDecorations.card(
          color: AppColors.locked,
          radius: AppSizes.progressBarHeight,
          shadow: false,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.progressBarHeight),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              widthFactor: total == 0 ? 0 : current / total,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.teal),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
