import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/result_widgets.dart';
import '../widgets/speech_bubble.dart';
import 'game_screen.dart';
import 'trail_screen.dart';

/// End of the game: 1 to 3 bonus stars, Cog's reaction, "Play again" and
/// "Back to lessons". (The bonus stars are already saved before this opens.)
class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({
    super.key,
    required this.lesson,
    required this.lessonNumber,
    required this.stars,
    required this.isNewBest,
    required this.settings,
    required this.progress,
  });

  final Lesson lesson;
  final int lessonNumber;
  final int stars;
  final bool isNewBest;
  final SettingsController settings;
  final ProgressController progress;

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          lesson: lesson,
          lessonNumber: lessonNumber,
          settings: settings,
          progress: progress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reaction = switch (stars) {
      >= 3 => l10n.gameResults3Stars,
      2 => l10n.gameResults2Stars,
      _ => l10n.gameResults1Star,
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppSizes.wideLayoutMinWidth &&
                constraints.maxWidth > constraints.maxHeight;
            final sidePadding = math.max(
              AppSizes.screenPadding,
              (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
            );
            final starSize = math.min(
              AppSizes.resultsStarMax,
              (constraints.maxWidth - sidePadding * 2) *
                  AppSizes.resultsStarFraction,
            );

            final playAgain = ChunkyButton(
              color: AppColors.red,
              onTap: () => _playAgain(context),
              child: Text(l10n.gamePlayAgain, textAlign: TextAlign.center),
            );
            final back = ChunkyButton(
              color: AppColors.surface,
              onTap: () => popToTrail(context),
              child: Text(
                l10n.resultsBackToLessons,
                textAlign: TextAlign.center,
              ),
            );

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      AppSizes.gap24,
                      sidePadding,
                      AppSizes.gap16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.gameResultsTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display,
                          ),
                        ),
                        const SizedBox(height: AppSizes.gap16),
                        StickerStarRow(
                          stars: stars,
                          size: starSize,
                          label: l10n.gameBonusStars(stars),
                        ),
                        const SizedBox(height: AppSizes.gap16),
                        Center(
                          child: CogPlaceholder(
                            size: CogPlaceholder.lessonSizeFor(context),
                          ),
                        ),
                        SpeechBubble(text: reaction),
                        const SizedBox(height: AppSizes.gap16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSizes.gap8,
                          runSpacing: AppSizes.gap8,
                          children: [
                            if (isNewBest)
                              StickerBadge(
                                text: l10n.resultsNewBest,
                                color: AppColors.star,
                              ),
                            StickerBadge(
                              text: l10n.gameBestBonus(
                                progress.bestBonusStars(lesson.id),
                              ),
                              color: AppColors.surface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outline,
                        width: AppSizes.outlineWidth,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    AppSizes.gap12,
                    sidePadding,
                    AppSizes.gap12,
                  ),
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: back),
                              const SizedBox(width: AppSizes.gap12),
                              Expanded(child: playAgain),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            playAgain,
                            const SizedBox(height: AppSizes.gap4),
                            back,
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
