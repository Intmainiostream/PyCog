import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_art.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/result_widgets.dart';
import '../widgets/speech_bubble.dart';
import 'game_screen.dart';
import 'quiz_screen.dart';
import 'trail_screen.dart';
import '../sound/sounds.dart';
import '../sound/sound_on_show.dart';

/// End of a quiz: 1 to 3 stars, Cog's reaction, "Try again" and
/// "Back to lessons". (The stars are already saved before this opens.)
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({
    super.key,
    required this.lesson,
    required this.lessonNumber,
    required this.stars,
    required this.isNewBest,
    required this.unlockedLessonNumber,
    required this.settings,
    required this.progress,
  });

  final Lesson lesson;
  final int lessonNumber;
  final int stars;
  final bool isNewBest;

  /// The lesson this result just opened, if any (e.g. 2).
  final int? unlockedLessonNumber;

  final SettingsController settings;
  final ProgressController progress;

  void _tryAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          lesson: lesson,
          lessonNumber: lessonNumber,
          settings: settings,
          progress: progress,
        ),
      ),
    );
  }

  void _playGame(BuildContext context) {
    Navigator.of(context).push(
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

  void _backToLessons(BuildContext context) {
    popToTrail(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reaction = switch (stars) {
      >= 3 => lesson.perfectQuizMessage?.call(l10n) ?? l10n.results3Stars,
      2 => l10n.results2Stars,
      _ => l10n.results1Star,
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
            final contentWidth = constraints.maxWidth - sidePadding * 2;
            final starSize = math.min(
              AppSizes.resultsStarMax,
              contentWidth * AppSizes.resultsStarFraction,
            );

            final tryAgain = ChunkyButton(
              color: AppColors.red,
              onTap: () => _tryAgain(context),
              child: Text(l10n.resultsTryAgain, textAlign: TextAlign.center),
            );
            final back = ChunkyButton(
              color: AppColors.surface,
              onTap: () => _backToLessons(context),
              child: Text(
                l10n.resultsBackToLessons,
                textAlign: TextAlign.center,
              ),
            );
            // Only lessons that have a game get this button.
            final playGame = lesson.hasGame
                ? ChunkyButton(
                    color: AppColors.success,
                    onTap: () => _playGame(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.extension_rounded),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.resultsPlayGame,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : null;

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
                            l10n.resultsTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display,
                          ),
                        ),
                        const SizedBox(height: AppSizes.gap16),
                        // Stars appear: one star sound per star.
                        SoundOnShow(
                          play: () => Sounds.stars(stars, first: Sfx.finish),
                          child: StickerStarRow(
                            stars: stars,
                            size: starSize,
                            label: l10n.starsCount(stars),
                          ),
                        ),
                        const SizedBox(height: AppSizes.gap16),
                        Center(
                          child: CogArt(
                            pose: CogPose.cheering,
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
                            if (unlockedLessonNumber != null)
                              StickerBadge(
                                text: l10n.resultsUnlocked(
                                  unlockedLessonNumber!,
                                ),
                                color: AppColors.success,
                              ),
                            StickerBadge(
                              text: l10n.resultsBest(
                                progress.bestStars(lesson.id),
                              ),
                              color: AppColors.surface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Buttons stay on screen; side by side when there's room.
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
                              Expanded(child: tryAgain),
                              if (playGame != null) ...[
                                const SizedBox(width: AppSizes.gap12),
                                Expanded(child: playGame),
                              ],
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (playGame != null) ...[
                              playGame,
                              const SizedBox(height: AppSizes.gap4),
                            ],
                            tryAgain,
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
