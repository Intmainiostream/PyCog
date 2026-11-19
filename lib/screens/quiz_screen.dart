import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/lessons.dart';
import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/code_box.dart';
import '../widgets/cog_art.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/lesson_text.dart';
import '../widgets/cog_feedback_card.dart';
import '../widgets/lesson_top_bar.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import 'quiz_results_screen.dart';
import '../sound/sounds.dart';

/// Where the student is within one question.
enum _Phase {
  answering, // picking an answer (maybe after a wrong try)
  correct, // got it right
  revealed, // used up the tries; the answer is shown
}

/// Runs any lesson's quiz, one question at a time.
///
/// Reusable: give it a [Lesson] whose `quiz` is filled in (see
/// lib/data/quizzes/). Everything Cog says is worked out from the current
/// state each time the screen draws, so switching language mid-question
/// updates the text right away.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.lesson,
    required this.lessonNumber,
    required this.settings,
    required this.progress,
    this.random,
  });

  final Lesson lesson;
  final int lessonNumber;
  final SettingsController settings;
  final ProgressController progress;

  /// Used to shuffle the answers. Tests pass a seeded one; the app uses a
  /// fresh random order every time.
  final math.Random? random;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// For each question: the order to show its answers in (original indexes).
  late final List<List<int>> _order;

  int _q = 0; // current question
  int? _selected; // answer the student tapped (original index)
  final Set<int> _wrongPicked = {}; // wrong answers tried on this question
  int? _lastWrong; // the most recent wrong answer (for Cog's hint)
  _Phase _phase = _Phase.answering;
  int _mistakes = 0; // wrong tries in the whole quiz
  bool _finishing = false;

  final _feedbackKey = GlobalKey();

  List<QuizQuestion> get _quiz => widget.lesson.quiz;
  QuizQuestion get _question => _quiz[_q];
  bool get _isLastQuestion => _q == _quiz.length - 1;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? math.Random();
    _order = [
      for (final question in _quiz)
        question.shuffleAnswers
            ? (List.generate(question.answers.length, (i) => i)
                ..shuffle(random))
            : List.generate(question.answers.length, (i) => i),
    ];
  }

  void _select(int answer) => setState(() => _selected = answer);

  void _check() {
    final picked = _selected;
    if (picked == null) return;
    setState(() {
      if (_question.answers[picked].correct) {
        Sounds.play(Sfx.correct);
        _phase = _Phase.correct;
      } else {
        Sounds.play(Sfx.wrong);
        _mistakes++;
        _wrongPicked.add(picked);
        _lastWrong = picked;
        _selected = null;
        if (_wrongPicked.length >= maxTriesPerQuestion) {
          _phase = _Phase.revealed;
        }
      }
    });
    _scrollToFeedback();
  }

  void _next() {
    if (_isLastQuestion) {
      _finish();
      return;
    }
    setState(() {
      _q++;
      _selected = null;
      _wrongPicked.clear();
      _lastWrong = null;
      _phase = _Phase.answering;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final stars = starsForMistakes(_mistakes);
    final unlockedBefore = widget.progress.unlockedCount(lessons);
    final newBest = await widget.progress.saveStars(widget.lesson.id, stars);
    final unlockedAfter = widget.progress.unlockedCount(lessons);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizResultsScreen(
          lesson: widget.lesson,
          lessonNumber: widget.lessonNumber,
          stars: stars,
          isNewBest: newBest,
          unlockedLessonNumber: unlockedAfter > unlockedBefore
              ? unlockedAfter
              : null,
          settings: widget.settings,
          progress: widget.progress,
        ),
      ),
    );
  }

  /// After Check, make sure Cog's feedback is on screen.
  void _scrollToFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _feedbackKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  current: _q + 1,
                  total: _quiz.length,
                  progressLabel: l10n.quizProgress(_q + 1, _quiz.length),
                  closeLabel: l10n.quizClose,
                  onClose: () => Navigator.of(context).pop(),
                  onSettings: () => showSettingsSheet(context, widget.settings),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    // New key per question = starts scrolled to the top.
                    key: ValueKey(_q),
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      AppSizes.gap8,
                      sidePadding,
                      AppSizes.gap16,
                    ),
                    child: _questionView(context, l10n, wide),
                  ),
                ),
                _bottomBar(l10n, sidePadding),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _questionView(BuildContext context, AppLocalizations l10n, bool wide) {
    final heading = Text(
      '${l10n.lessonNumber(widget.lessonNumber)} · '
      '${widget.lesson.title(l10n)} · ${l10n.quizLabel}',
      textAlign: TextAlign.center,
      style: AppTextStyles.small,
    );

    final asking = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CogArt(
            pose: CogPose.waving,
            size: CogPlaceholder.lessonSizeFor(context),
          ),
        ),
        Semantics(
          header: true,
          child: SpeechBubble(text: _question.prompt(l10n)),
        ),
        if (_question.code.isNotEmpty) ...[
          const SizedBox(height: AppSizes.gap16),
          CodeBox(lines: _question.code),
        ],
      ],
    );

    final feedback = _feedbackText(l10n);
    final answering = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in _order[_q]) ...[
          _AnswerButton(
            key: ValueKey('answer-$_q-$i'),
            label: _question.answers[i].label(l10n),
            state: _answerState(i),
            onTap: _phase == _Phase.answering && !_wrongPicked.contains(i)
                ? () => _select(i)
                : null,
          ),
          const SizedBox(height: AppSizes.gap8),
        ],
        if (feedback == null)
          Text(
            l10n.quizPickAnswer,
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          )
        else
          CogFeedbackCard(
            key: _feedbackKey,
            text: feedback,
            mood: switch (_phase) {
              _Phase.correct => CogMood.happy,
              _Phase.revealed => CogMood.explaining,
              _Phase.answering => CogMood.hint,
            },
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: AppSizes.gap8),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: asking),
              const SizedBox(width: AppSizes.gap24),
              Expanded(flex: 3, child: answering),
            ],
          )
        else ...[
          asking,
          const SizedBox(height: AppSizes.gap16),
          answering,
        ],
      ],
    );
  }

  _AnswerState _answerState(int i) {
    final answer = _question.answers[i];
    if (_wrongPicked.contains(i)) return _AnswerState.wrong;
    if (answer.correct &&
        (_phase == _Phase.correct || _phase == _Phase.revealed)) {
      return _AnswerState.right;
    }
    if (_selected == i) return _AnswerState.selected;
    return _AnswerState.normal;
  }

  /// What Cog says under the answers, or null before the first Check.
  String? _feedbackText(AppLocalizations l10n) {
    final question = _question;
    switch (_phase) {
      case _Phase.correct:
        final cheers = [l10n.quizCheer1, l10n.quizCheer2, l10n.quizCheer3];
        return '${cheers[_q % cheers.length]} ${question.explanation(l10n)}';
      case _Phase.revealed:
        final right = question.answers[question.correctIndex].label(l10n);
        return '${l10n.quizReveal(right)}\n${question.explanation(l10n)}';
      case _Phase.answering:
        final wrong = _lastWrong;
        if (wrong == null) return null;
        final hint = question.answers[wrong].whyWrong?.call(l10n) ?? '';
        return '$hint ${l10n.quizTryAgain}'.trim();
    }
  }

  Widget _bottomBar(AppLocalizations l10n, double sidePadding) {
    final answered = _phase != _Phase.answering;
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
      child: SizedBox(
        width: double.infinity,
        child: answered
            ? ChunkyButton(
                color: AppColors.success,
                onTap: _next,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _isLastQuestion ? l10n.quizSeeResults : l10n.quizNext,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              )
            : ChunkyButton(
                color: AppColors.red,
                onTap: _selected == null ? null : _check,
                child: Text(l10n.quizCheck, textAlign: TextAlign.center),
              ),
      ),
    );
  }
}

enum _AnswerState { normal, selected, right, wrong }

/// A big chunky answer button. Teal when picked, yellow-green when right,
/// red when it was a wrong try (with a ✓ / ✗ so it's not color-only).
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _AnswerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (state) {
      _AnswerState.normal => AppColors.surface,
      _AnswerState.selected => AppColors.teal,
      _AnswerState.right => AppColors.success,
      _AnswerState.wrong => AppColors.red,
    };
    final icon = switch (state) {
      _AnswerState.right => Icons.check_circle_rounded,
      _AnswerState.wrong => Icons.cancel_rounded,
      _ => null,
    };
    final stateLabel = switch (state) {
      _AnswerState.right => l10n.quizAnswerRight,
      _AnswerState.wrong => l10n.quizAnswerWrong,
      _ => null,
    };
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? AppColors.surface
        : AppColors.text;

    return Semantics(
      selected: state == _AnswerState.selected,
      value: stateLabel,
      child: ChunkyButton(
        color: color,
        disabledColor: color,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap16,
          vertical: AppSizes.gap12,
        ),
        child: Row(
          children: [
            Expanded(
              child: LessonText(
                label,
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: AppSizes.fontSubtitle,
                  color: textColor,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppSizes.gap8),
              Icon(icon, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}
