import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/lessons.dart';
import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cloud_footer.dart';
import 'lesson_screen.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/lesson_path.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';

/// Goes back to the lesson trail (used by "Back to lessons" on the results
/// screens). Falls back to the first screen if the trail isn't open.
void popToTrail(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) => route.settings.name == TrailScreen.routeName || route.isFirst,
  );
}

/// The lesson trail: the winding path of lessons (opened by PLAY on the
/// home screen). Its route is named [TrailScreen.routeName] so "Back to
/// lessons" on the results screens can return here (see [popToTrail]).
///
/// Two layouts:
///  * Narrow / portrait: one centered column (max width on tablets) with Cog,
///    the speech bubble and the lesson path, all in one scrolling list.
///  * Wide landscape: Cog + speech bubble on the left, the lesson path on the
///    right; each side scrolls on its own.
class TrailScreen extends StatelessWidget {
  const TrailScreen({
    super.key,
    required this.settings,
    required this.progress,
  });

  static const routeName = '/trail';

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
              AppTopBar(
                sidePadding: sidePadding,
                stars: progress.totalStars(lessons),
                onSettings: () => showSettingsSheet(context, settings),
                // Back to the home screen (hidden if there's nothing below).
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).pop()
                    : null,
                backLabel: AppLocalizations.of(context).homeBackToHome,
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
        // The path keeps going past the last lesson, into the clouds.
        showTail: true,
      ),
      const CloudFooter(),
    ];
  }
}
