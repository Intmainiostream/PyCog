import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../models/lesson_card.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/code_box.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/lesson_top_bar.dart';
import '../widgets/lesson_text.dart';
import '../widgets/output_box.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/variable_box.dart';
import 'quiz_screen.dart';

/// Shows any lesson's explanation, one card at a time, with Cog explaining.
///
/// Reusable: give it a [Lesson] whose `cards` are filled in (see
/// lib/data/lessons/) and it works. No screen code changes per lesson.
///
/// Changing the language in Settings updates the text right away and keeps
/// the student on the same card.
class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lesson,
    required this.lessonNumber,
    required this.settings,
    required this.progress,
  });

  final Lesson lesson;
  final int lessonNumber;
  final SettingsController settings;
  final ProgressController progress;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;
  bool _goingForward = true; // which way the card slides in

  List<LessonCard> get _cards => widget.lesson.cards;
  bool get _isFirst => _index == 0;
  bool get _isLast => _index == _cards.length - 1;

  void _goTo(int index) {
    setState(() {
      _goingForward = index > _index;
      _index = index;
    });
  }

  void _next() {
    if (!_isLast) {
      _goTo(_index + 1);
    } else if (widget.lesson.hasQuiz) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizScreen(
            lesson: widget.lesson,
            lessonNumber: widget.lessonNumber,
            settings: widget.settings,
            progress: widget.progress,
          ),
        ),
      );
    } else {
      // This lesson has no quiz written yet.
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.quizComingSoon)));
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_cards.isNotEmpty, 'LessonScreen needs a lesson with cards');
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppSizes.wideLayoutMinWidth &&
                constraints.maxWidth > constraints.maxHeight;
            final maxWidth = wide
                ? AppSizes.maxWideContentWidth
                : AppSizes.maxContentWidth;
            final sidePadding = math.max(
              AppSizes.screenPadding,
              (constraints.maxWidth - maxWidth) / 2,
            );

            return Column(
              children: [
                LessonTopBar(
                  sidePadding: sidePadding,
                  current: _index + 1,
                  total: _cards.length,
                  progressLabel: l10n.lessonProgress(_index + 1, _cards.length),
                  closeLabel: l10n.lessonClose,
                  onClose: () => Navigator.of(context).pop(),
                  onSettings: () => showSettingsSheet(context, widget.settings),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: _slideAndFade,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, ?current],
                    ),
                    // A new key per card = new scroll position (starts at top).
                    child: _CardView(
                      key: ValueKey(_index),
                      card: _cards[_index],
                      lesson: widget.lesson,
                      lessonNumber: widget.lessonNumber,
                      wide: wide,
                      sidePadding: sidePadding,
                    ),
                  ),
                ),
                _LessonNavBar(
                  sidePadding: sidePadding,
                  isFirst: _isFirst,
                  isLast: _isLast,
                  onBack: () => _goTo(_index - 1),
                  onNext: _next,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _slideAndFade(Widget child, Animation<double> animation) {
    final isIncoming = child.key == ValueKey(_index);
    // Incoming card slides in from the side we're moving towards; the
    // outgoing one slides out the other way.
    final direction = (_goingForward == isIncoming) ? 1.0 : -1.0;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0.15 * direction, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// One card: title, Cog + speech bubble, variable boxes, code, tip.
/// Scrolls if it's taller than the screen.
class _CardView extends StatelessWidget {
  const _CardView({
    super.key,
    required this.card,
    required this.lesson,
    required this.lessonNumber,
    required this.wide,
    required this.sidePadding,
  });

  final LessonCard card;
  final Lesson lesson;
  final int lessonNumber;
  final bool wide;
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l10n.lessonNumber(lessonNumber)} · ${lesson.title(l10n)}',
          textAlign: TextAlign.center,
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppSizes.gap4),
        Semantics(
          header: true,
          child: Text(
            card.title(l10n),
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
        ),
      ],
    );

    final cogAndBubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CogPlaceholder(size: CogPlaceholder.lessonSizeFor(context)),
        SpeechBubble(
          text: card.speech(l10n),
          textAlign: TextAlign.start,
          style: AppTextStyles.body,
        ),
      ],
    );

    final extras = [
      if (card.boxes.isNotEmpty) ...[
        const SizedBox(height: AppSizes.gap16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSizes.gap16,
          runSpacing: AppSizes.gap16,
          children: [for (final box in card.boxes) VariableBox(data: box)],
        ),
      ],
      if (card.code.isNotEmpty) ...[
        const SizedBox(height: AppSizes.gap16),
        CodeBox(lines: card.code),
      ],
      // Only cards that set `output` get this box (none before Lesson 4).
      if (card.output.isNotEmpty) ...[
        const SizedBox(height: AppSizes.gap12),
        OutputBox(lines: card.output, typed: card.typed),
      ],
      if (card.tip != null) ...[
        const SizedBox(height: AppSizes.gap16),
        _TipCard(text: card.tip!(l10n)),
      ],
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        sidePadding,
        AppSizes.gap8,
        sidePadding,
        AppSizes.gap16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const SizedBox(height: AppSizes.gap8),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: cogAndBubble),
                const SizedBox(width: AppSizes.gap24),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: extras,
                  ),
                ),
              ],
            )
          else ...[
            cogAndBubble,
            ...extras,
          ],
        ],
      ),
    );
  }
}

/// "Cog's tip" box under the code.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final iconSize = MediaQuery.textScalerOf(context).scale(26);
    return Container(
      padding: const EdgeInsets.all(AppSizes.gap12),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.star, size: iconSize),
          const SizedBox(width: AppSizes.gap8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).tipLabel,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.tealDark,
                  ),
                ),
                const SizedBox(height: AppSizes.gap4),
                LessonText(text, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Back and Next buttons at the bottom. On the last card, Next becomes
/// "Next: Quiz".
class _LessonNavBar extends StatelessWidget {
  const _LessonNavBar({
    required this.sidePadding,
    required this.isFirst,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  final double sidePadding;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget label(IconData? before, String text, IconData? after) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (before != null) ...[Icon(before), const SizedBox(width: 4)],
          Flexible(child: Text(text, textAlign: TextAlign.center)),
          if (after != null) ...[const SizedBox(width: 4), Icon(after)],
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
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
      // Both buttons get the same height, even if one label wraps.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ChunkyButton(
                color: AppColors.surface,
                onTap: isFirst ? null : onBack,
                child: label(Icons.arrow_back_rounded, l10n.lessonBack, null),
              ),
            ),
            const SizedBox(width: AppSizes.gap12),
            Expanded(
              child: ChunkyButton(
                color: isLast ? AppColors.success : AppColors.red,
                onTap: onNext,
                child: label(
                  null,
                  isLast ? l10n.lessonNextQuiz : l10n.lessonNext,
                  Icons.arrow_forward_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
