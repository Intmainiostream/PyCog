import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/speech_bubble.dart';
import 'quiz_screen.dart';

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

  void _backToLessons(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reaction = switch (stars) {
      >= 3 => l10n.results3Stars,
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
                        _StarRow(stars: stars, size: starSize),
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
                              _Badge(
                                text: l10n.resultsNewBest,
                                color: AppColors.star,
                              ),
                            if (unlockedLessonNumber != null)
                              _Badge(
                                text: l10n.resultsUnlocked(
                                  unlockedLessonNumber!,
                                ),
                                color: AppColors.success,
                              ),
                            _Badge(
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
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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

/// Three big stars; earned ones are yellow, the rest light brown.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.size});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).starsCount(stars),
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
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

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
