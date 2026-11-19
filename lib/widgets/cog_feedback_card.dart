import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'cog_art.dart';
import 'cog_placeholder.dart';
import 'lesson_text.dart';

/// How Cog feels: green cheer, soft-coral hint, or mint explanation.
enum CogMood { happy, hint, explaining }

/// "Cog says…" card with a mini Cog: a cheer, a gentle hint, or an
/// explanation. Shared by the quiz and the game.
class CogFeedbackCard extends StatelessWidget {
  const CogFeedbackCard({super.key, required this.text, required this.mood});

  final String text;
  final CogMood mood;

  @override
  Widget build(BuildContext context) {
    final color = switch (mood) {
      CogMood.happy => AppColors.success,
      CogMood.hint => AppColors.hintBackground,
      CogMood.explaining => AppColors.mint,
    };
    return Semantics(
      liveRegion: true, // screen readers announce it when it appears
      child: Container(
        margin: const EdgeInsets.only(top: AppSizes.gap8),
        padding: const EdgeInsets.all(AppSizes.gap12),
        decoration: AppDecorations.card(color: color),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A cheer shows Cog with both hands up. Hints and explanations
            // keep the drawn Cog: neither new picture (waving hello or
            // celebrating) fits "not quite, try again".
            if (mood == CogMood.happy)
              const CogArt(
                pose: CogPose.cheering,
                size: AppSizes.feedbackCogSize,
              )
            else
              const CogPlaceholder(size: AppSizes.feedbackCogSize),
            const SizedBox(width: AppSizes.gap12),
            Expanded(child: LessonText(text, style: AppTextStyles.bodyBold)),
          ],
        ),
      ),
    );
  }
}
