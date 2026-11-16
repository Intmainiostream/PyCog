import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/lessons.dart';
import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import 'lesson_screen.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/lesson_path.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/star_counter.dart';

/// The home screen.
///
/// Two layouts:
///  * Narrow / portrait: one centered column (max width on tablets) with Cog,
///    the speech bubble and the lesson path, all in one scrolling list.
///  * Wide landscape: Cog + speech bubble on the left, the lesson path on the
///    right; each side scrolls on its own.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings, required this.progress});

  final SettingsController settings;
  final ProgressController progress;

  void _onLessonTap(BuildContext context, Lesson lesson, bool unlocked) {
    // Open lessons that have content; everything else shows a message.
    if (unlocked && lesson.hasContent) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LessonScreen(
            lesson: lesson,
            lessonNumber: lessons.indexOf(lesson) + 1,
            settings: settings,
            progress: progress,
          ),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(unlocked ? l10n.comingSoon : l10n.lessonLocked)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Redraw when saved progress changes (stars total, unlocked lessons).
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= AppSizes.wideLayoutMinWidth &&
              constraints.maxWidth > constraints.maxHeight;
          final maxWidth = wide
              ? AppSizes.maxWideContentWidth
              : AppSizes.maxContentWidth;
          // Side padding that keeps content centered at [maxWidth] on big
          // screens. Used as scroll padding (not a wrapper) so you can
          // still scroll by dragging in the empty side margins.
          final sidePadding = math.max(
            AppSizes.screenPadding,
            (constraints.maxWidth - maxWidth) / 2,
          );

          return Column(
            children: [
              _TopBar(
                sidePadding: sidePadding,
                stars: progress.totalStars(lessons),
                onSettings: () => showSettingsSheet(context, settings),
              ),
              Expanded(
                child: wide
                    ? _wideBody(context, sidePadding)
                    : _narrowBody(context, sidePadding),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _narrowBody(BuildContext context, double sidePadding) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        AppSizes.gap8,
        sidePadding,
        AppSizes.gap24,
      ),
      children: [
        _cogWithBubble(context),
        const SizedBox(height: AppSizes.gap24),
        ..._lessons(context),
      ],
    );
  }

  Widget _wideBody(BuildContext context, double sidePadding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                AppSizes.gap8,
                AppSizes.gap12,
                AppSizes.gap24,
              ),
              child: _cogWithBubble(context),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSizes.gap12,
              AppSizes.gap8,
              sidePadding,
              AppSizes.gap24,
            ),
            children: _lessons(context),
          ),
        ),
      ],
    );
  }

  Widget _cogWithBubble(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CogPlaceholder(size: CogPlaceholder.sizeFor(context)),
        SpeechBubble(text: AppLocalizations.of(context).cogGreeting),
      ],
    );
  }

  List<Widget> _lessons(BuildContext context) {
    return [
      Text(
        AppLocalizations.of(context).lessonsHeader,
        textAlign: TextAlign.center,
        style: AppTextStyles.display,
      ),
      const SizedBox(height: AppSizes.gap16),
      LessonPath(
        lessons: lessons,
        unlockedCount: progress.unlockedCount(lessons),
        onLessonTap: (lesson, unlocked) =>
            _onLessonTap(context, lesson, unlocked),
      ),
    ];
  }
}

/// Stars on the left, app name in the middle, gear on the right.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.sidePadding,
    required this.stars,
    required this.onSettings,
  });

  final double sidePadding;
  final int stars;
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
      // Two equal side slots keep the title exactly centered. The star counter
      // may shrink a little on tiny screens with huge text instead of
      // overflowing.
      child: Row(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.gap8),
            child: Text(
              l10n.appTitle,
              style: AppTextStyles.title.copyWith(color: AppColors.tealDark),
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
      ),
    );
  }
}
