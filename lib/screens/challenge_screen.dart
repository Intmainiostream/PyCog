import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/minigame_progress.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../minigame/output_checker.dart';
import '../models/minigame.dart';
import '../playground/coding_output.dart';
import '../playground/python_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/code_box.dart';
import '../widgets/code_helper_bar.dart';
import '../widgets/cog_feedback_card.dart';
import '../widgets/lesson_text.dart';
import '../widgets/lesson_top_bar.dart';
import '../widgets/output_box.dart';
import '../widgets/settings_sheet.dart';
import 'minigame_map_screen.dart';
import '../sound/sounds.dart';
import '../sound/music_zone.dart';

/// One MINIGAME challenge: a quiz, fill the blank, fix the bug, or write it
/// yourself.
///
/// Code challenges run the student's code with real Python ([PythonEngine])
/// against hidden tests and check only the output. Each hint costs a star
/// ([starsForHints]); a failed run costs nothing. When solved, the best
/// stars are saved with [MinigameProgress].
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.level,
    required this.index,
    required this.levels,
    required this.settings,
    required this.progress,
    this.engine,
    this.random,
  });

  final MinigameLevel level;

  /// Which challenge of [level] (from 0).
  final int index;

  /// Every level (to tell when solving this opens the next one).
  final List<MinigameLevel> levels;
  final SettingsController settings;
  final MinigameProgress progress;

  /// Defaults to the real Python. Tests pass a fake.
  final PythonEngine? engine;

  /// Shuffles quiz answers. Tests pass a seeded one.
  final math.Random? random;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final _code = TextEditingController(text: _challenge.starter);
  final _codeFocus = FocusNode();
  final _resultKey = GlobalKey();

  /// Quiz: the order to show the answers in (original indexes).
  late final List<int> _order;

  late int _hintsUsed; // saved on the phone until the challenge is finished
  int? _selected; // quiz answer picked, not checked yet
  late final Set<int> _wrongPicked; // quiz answers already tried (saved too)
  int? _lastWrong;
  String? _choice; // fill the blank: the picked choice

  bool _running = false;
  CheckResult? _check;
  bool _solved = false;
  int _earned = 0;
  bool _firstRecord = true; // false on a replay: the record stays
  int _points = 0; // Star Points the solve earned
  int? _openedLevel; // level number that solving this opened

  Challenge get _challenge => widget.level.challenges[widget.index];
  PythonEngine get _engine => widget.engine ?? PyodideEngine.instance;
  bool get _isLast => widget.index == widget.level.challenges.length - 1;

  /// What the student entered: the blank's text, or the whole code.
  String get _entered =>
      _challenge.type == ChallengeType.fillBlank &&
          _challenge.choices.isNotEmpty
      ? (_choice ?? '')
      : _code.text;

  @override
  void initState() {
    super.initState();
    final count = _challenge.answers.length;
    _order = List.generate(count, (i) => i)
      ..shuffle(widget.random ?? math.Random());
    // Hints and wrong picks from an earlier visit stay (and so does the
    // star limit) until the challenge is finished.
    final id = _challenge.id;
    _hintsUsed = math.min(
      widget.progress.hintsUsed(id),
      _challenge.hints.length,
    );
    _wrongPicked = {
      for (final i in widget.progress.wrongPicks(id))
        if (i >= 0 && i < count && !_challenge.answers[i].correct) i,
    };
    _code.addListener(() => setState(() {}));
    _codeFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Stars the challenge is worth right now.
  int get _starsNow => starsFor(
    _challenge,
    hintsUsed: _hintsUsed,
    wrongPicks: _wrongPicked.length,
  );

  void _useHint() {
    if (_hintsUsed >= _challenge.hints.length || _solved) return;
    Sounds.play(Sfx.hint);
    setState(() => _hintsUsed++);
    widget.progress.saveHintsUsed(_challenge.id, _hintsUsed);
  }

  void _checkQuiz() {
    final picked = _selected;
    if (picked == null) return;
    if (_challenge.answers[picked].correct) {
      _pass();
      return;
    }
    Sounds.play(Sfx.wrong);
    setState(() {
      _wrongPicked.add(picked);
      _lastWrong = picked;
      _selected = null;
    });
    widget.progress.saveWrongPick(_challenge.id, picked);
    _scrollToResult();
  }

  Future<void> _runCheck() async {
    _codeFocus.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _running = true;
      _check = null;
    });
    final result = await checkProgram(
      _engine,
      _challenge.programFor(_entered),
      _challenge.tests,
      required: _challenge.requiredCode,
    );
    if (!mounted) return;
    if (result.passed) {
      _running = false;
      await _pass();
      return;
    }
    // A wrong answer (not when Python itself could not start).
    final error = result.got?.error;
    if (error == null || !isStartError(error)) Sounds.play(Sfx.wrong);
    setState(() {
      _running = false;
      _check = result;
    });
    _scrollToResult();
  }

  Future<void> _pass() async {
    final stars = _starsNow;
    final before = widget.progress.unlockedCount(widget.levels);
    // Only the first solve is saved (the permanent record).
    final first = await widget.progress.saveStars(_challenge.id, stars);
    // Star Points: every solve, doubled the first time.
    final points = widget.settings.shop.earnRun(stars, first: first);
    await widget.progress.clearAttempt(_challenge.id);
    final after = widget.progress.unlockedCount(widget.levels);
    if (!mounted) return;
    // Right quiz pick: correct. Code challenge done, or a new level
    // opened: finish. Then one star sound per earned star.
    final opened = after > before;
    Sounds.stars(
      stars,
      first: _challenge.runsCode || opened ? Sfx.finish : Sfx.correct,
    );
    setState(() {
      _solved = true;
      _earned = stars;
      _firstRecord = first;
      _points = points;
      _check = null;
      _selected = null;
      _openedLevel = after > before ? widget.levels[after - 1].number : null;
    });
    _scrollToResult();
  }

  void _next() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeScreen(
          level: widget.level,
          index: widget.index + 1,
          levels: widget.levels,
          settings: widget.settings,
          progress: widget.progress,
          engine: widget.engine,
          random: widget.random,
        ),
      ),
    );
  }

  void _resetCode() => setState(() {
    _code.text = _challenge.starter;
    _check = null;
  });

  /// After a check, make sure the result is on screen.
  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
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
    final total = widget.level.challenges.length;
    return MusicZone(
      song: Song.game,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.max(
                AppSizes.screenPadding,
                (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
              );
              return Column(
                children: [
                  LessonTopBar(
                    sidePadding: side,
                    current: widget.index + 1,
                    total: total,
                    progressLabel: l10n.mgChallengeProgress(
                      widget.index + 1,
                      total,
                    ),
                    closeLabel: l10n.mgClose,
                    onClose: () => Navigator.of(context).pop(),
                    onSettings: () =>
                        showSettingsSheet(context, widget.settings),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        AppSizes.gap8,
                        side,
                        AppSizes.gap24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _content(l10n),
                      ),
                    ),
                  ),
                  if (_codeFocus.hasFocus)
                    CodeHelperBar(
                      l10n: l10n,
                      padding: side,
                      keyPrefix: 'mg',
                      onInsert: (text, {back = 0}) =>
                          insertCode(_code, text, back: back),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n) {
    final (icon, typeName) = challengeTypeLabel(l10n, _challenge.type);
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${l10n.mgLevel(widget.level.number)} · $typeName',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSizes.gap4),
      Semantics(
        header: true,
        child: Text(
          _challenge.title(l10n),
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
      ),
      const SizedBox(height: AppSizes.gap8),
      CogSays(text: _challenge.prompt(l10n)),
      const SizedBox(height: AppSizes.gap16),
      ...switch (_challenge.type) {
        ChallengeType.quiz => _quiz(l10n),
        ChallengeType.fillBlank => _fillBlank(l10n),
        ChallengeType.fixBug || ChallengeType.writeCode => _codeEditor(l10n),
      },
      ..._example(l10n),
      const SizedBox(height: AppSizes.gap12),
      if (!_solved) _actionButton(l10n),
      if (_running) _checking(l10n),
      KeyedSubtree(
        key: _resultKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _result(l10n),
        ),
      ),
      const SizedBox(height: AppSizes.gap16),
      ..._hints(l10n),
    ];
  }

  // ---- Quiz ----

  List<Widget> _quiz(AppLocalizations l10n) => [
    if (_challenge.code.isNotEmpty) ...[
      CodeBox(lines: _challenge.code),
      const SizedBox(height: AppSizes.gap16),
    ],
    for (final i in _order) ...[
      _AnswerButton(
        key: ValueKey('mg-answer-$i'),
        label: _challenge.answers[i].label(l10n),
        state: _answerState(i),
        onTap: _solved || _wrongPicked.contains(i)
            ? null
            : () => setState(() => _selected = i),
      ),
      const SizedBox(height: AppSizes.gap8),
    ],
  ];

  _AnswerState _answerState(int i) {
    if (_wrongPicked.contains(i)) return _AnswerState.wrong;
    if (_solved && _challenge.answers[i].correct) return _AnswerState.right;
    if (_selected == i) return _AnswerState.selected;
    return _AnswerState.normal;
  }

  // ---- Fill the blank ----

  List<Widget> _fillBlank(AppLocalizations l10n) {
    final choices = _challenge.choices;
    return [
      _BlankCode(template: _challenge.template, entered: _entered),
      const SizedBox(height: AppSizes.gap12),
      if (choices.isNotEmpty) ...[
        Text(l10n.mgPickBlank, style: AppTextStyles.bodyBold),
        const SizedBox(height: AppSizes.gap8),
        Wrap(
          spacing: AppSizes.gap8,
          runSpacing: AppSizes.gap4,
          children: [
            for (final (i, choice) in choices.indexed)
              ChunkyButton(
                key: ValueKey('mg-choice-$i'),
                color: _choice == choice ? AppColors.teal : AppColors.surface,
                disabledColor: _choice == choice
                    ? AppColors.teal
                    : AppColors.surface,
                onTap: _solved || _running
                    ? null
                    : () => setState(() {
                        _choice = choice;
                        _check = null;
                      }),
                child: Text(
                  choice,
                  style: AppTextStyles.code.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _choice == choice
                        ? AppColors.surface
                        : AppColors.text,
                  ),
                ),
              ),
          ],
        ),
      ] else
        TextField(
          key: const ValueKey('mg-blank'),
          controller: _code,
          readOnly: _solved,
          autocorrect: false,
          enableSuggestions: false,
          smartQuotesType: SmartQuotesType.disabled,
          smartDashesType: SmartDashesType.disabled,
          textCapitalization: TextCapitalization.none,
          style: AppTextStyles.code.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: l10n.mgBlankLabel,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        ),
    ];
  }

  // ---- Fix the bug / write it yourself ----

  List<Widget> _codeEditor(AppLocalizations l10n) {
    final mono = AppTextStyles.code;
    return [
      Container(
        decoration: AppDecorations.card(color: AppColors.codeBackground),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap12,
          vertical: AppSizes.gap8,
        ),
        child: Semantics(
          label: l10n.codingCodeLabel,
          child: TextField(
            key: const ValueKey('mg-code'),
            controller: _code,
            focusNode: _codeFocus,
            readOnly: _solved,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.none,
            cursorColor: AppColors.codeOperator,
            style: mono.copyWith(color: AppColors.codeText),
            decoration: InputDecoration.collapsed(
              hintText: l10n.codingCodeHint,
              hintStyle: mono.copyWith(color: AppColors.codeComment),
            ),
          ),
        ),
      ),
      if (_challenge.starter.isNotEmpty &&
          _code.text != _challenge.starter &&
          !_solved)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            key: const ValueKey('mg-reset'),
            onPressed: _running ? null : Sounds.tapThen(_resetCode),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.mgReset),
          ),
        ),
    ];
  }

  /// The first test, shown before any run, when the challenge allows it.
  List<Widget> _example(AppLocalizations l10n) {
    if (!_challenge.runsCode || !_challenge.showFirstTest) return const [];
    final test = _challenge.tests.first;
    final (rows, typed) = splitExpected(test.output, test.inputs);
    return [
      const SizedBox(height: AppSizes.gap12),
      Text(l10n.mgExample, style: AppTextStyles.bodyBold),
      const SizedBox(height: AppSizes.gap4),
      OutputBox(key: const ValueKey('mg-example'), lines: rows, typed: typed),
    ];
  }

  // ---- Check button, result, hints ----

  Widget _actionButton(AppLocalizations l10n) {
    final isQuiz = _challenge.type == ChallengeType.quiz;
    final ready = isQuiz
        ? _selected != null
        : !_running && _entered.trim().isNotEmpty;
    return ChunkyButton(
      key: ValueKey(isQuiz ? 'mg-check' : 'mg-run'),
      color: AppColors.red,
      onTap: ready ? (isQuiz ? _checkQuiz : _runCheck) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isQuiz) ...[
            const Icon(Icons.play_arrow_rounded),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              isQuiz ? l10n.quizCheck : l10n.mgRunCheck,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checking(AppLocalizations l10n) {
    return ValueListenableBuilder<bool>(
      valueListenable: _engine.isReady,
      builder: (context, ready, _) => Padding(
        padding: const EdgeInsets.only(top: AppSizes.gap12),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSizes.gap8),
            Expanded(
              child: Text(
                ready ? l10n.mgChecking : l10n.codingStarting,
                key: const ValueKey('mg-status'),
                style: AppTextStyles.bodyBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _result(AppLocalizations l10n) {
    if (_solved) {
      final opened = _openedLevel;
      return [
        CogFeedbackCard(
          key: const ValueKey('mg-passed'),
          text: [
            l10n.mgPassed(_earned),
            if (opened != null) l10n.mgUnlocked(opened),
            if (!_firstRecord) l10n.recordKept,
          ].join('\n'),
          mood: CogMood.happy,
        ),
        const SizedBox(height: AppSizes.gap8),
        Center(child: StarRow(stars: _earned, size: 40)),
        if (_points > 0) ...[
          const SizedBox(height: AppSizes.gap4),
          Text(
            _firstRecord
                ? '${l10n.pointsEarned(_points)} ${l10n.pointsDoubled}'
                : l10n.pointsEarned(_points),
            key: const ValueKey('mg-points'),
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
        const SizedBox(height: AppSizes.gap12),
        if (!_isLast) ...[
          ChunkyButton(
            key: const ValueKey('mg-next'),
            color: AppColors.success,
            onTap: _next,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(l10n.mgNext, textAlign: TextAlign.center)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.gap8),
        ],
        ChunkyButton(
          key: const ValueKey('mg-back-level'),
          color: _isLast ? AppColors.success : AppColors.surface,
          onTap: () => Navigator.of(context).pop(),
          child: Text(l10n.mgBackToLevel, textAlign: TextAlign.center),
        ),
      ];
    }
    if (_challenge.type == ChallengeType.quiz) {
      final wrong = _lastWrong;
      if (wrong == null) return const [];
      final why = _challenge.answers[wrong].whyWrong?.call(l10n);
      return [
        CogFeedbackCard(
          key: const ValueKey('mg-wrong'),
          text: why == null ? l10n.mgTryAgain : '$why ${l10n.quizTryAgain}',
          mood: CogMood.hint,
        ),
      ];
    }
    final check = _check;
    if (check == null || check.passed) return const [];
    return _failure(l10n, check);
  }

  /// The first failed test: what was typed (in the output box), what the
  /// code showed, and what was expected. Tests after it are never shown.
  List<Widget> _failure(AppLocalizations l10n, CheckResult check) {
    if (check.missing.isNotEmpty) {
      // The output was right, but a required piece is missing.
      return [
        CogFeedbackCard(
          key: const ValueKey('mg-missing'),
          // Non-breaking spaces keep each piece (e.g. `speed =`) on one line.
          text: l10n.mgMustUse(
            check.missing
                .map((p) => '`${p.replaceAll(' ', '\u00A0')}`')
                .join(', '),
          ),
          mood: CogMood.hint,
        ),
      ];
    }
    final got = check.got!;
    final test = check.failedCase!;
    final error = got.error;
    if (error != null && isStartError(error)) {
      return [CogFeedbackCard(text: l10n.codingStartError, mood: CogMood.hint)];
    }
    final (rows, typed) = splitOutput(got.stdout, got.typed);
    final (wantRows, wantTyped) = splitExpected(test.output, test.inputs);
    final question = check.wrongQuestion;
    return [
      if (question != null)
        // A kind message instead of "did not match": which question to ask.
        // Non-breaking spaces keep `input("Age? ")` on one line.
        CogFeedbackCard(
          key: const ValueKey('mg-wrong-question'),
          text: l10n.mgWrongQuestion(
            '`input("${question.replaceAll(' ', '\u00A0')}")`',
          ),
          mood: CogMood.hint,
        )
      else
        CogFeedbackCard(
          key: const ValueKey('mg-failed'),
          text: l10n.mgFailed(check.failedNumber!),
          mood: CogMood.hint,
        ),
      if (got.timedOut)
        CogFeedbackCard(text: l10n.codingTimeout, mood: CogMood.hint),
      if (error != null) ...[
        Container(
          key: const ValueKey('mg-error'),
          margin: const EdgeInsets.only(top: AppSizes.gap8),
          padding: const EdgeInsets.all(AppSizes.gap12),
          decoration: AppDecorations.card(color: AppColors.surface),
          child: SelectableText(
            error,
            style: AppTextStyles.code.copyWith(
              color: AppColors.redDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CogFeedbackCard(
          text: needsMoreAnswers(error)
              ? l10n.mgTooManyInputs
              : friendlyTip(l10n, error),
          mood: CogMood.hint,
        ),
      ],
      const SizedBox(height: AppSizes.gap12),
      Text(l10n.mgYourOutput, style: AppTextStyles.bodyBold),
      const SizedBox(height: AppSizes.gap4),
      if (rows.isEmpty)
        Text(l10n.codingNothingPrinted, style: AppTextStyles.body)
      else
        OutputBox(
          key: const ValueKey('mg-your-output'),
          lines: rows,
          typed: typed,
        ),
      const SizedBox(height: AppSizes.gap12),
      Text(l10n.mgExpected, style: AppTextStyles.bodyBold),
      const SizedBox(height: AppSizes.gap4),
      OutputBox(
        key: const ValueKey('mg-expected-output'),
        lines: wantRows,
        typed: wantTyped,
      ),
    ];
  }

  List<Widget> _hints(AppLocalizations l10n) {
    return [
      for (var n = 0; n < _hintsUsed; n++)
        CogFeedbackCard(
          key: ValueKey('mg-hint-text-$n'),
          text: '${l10n.mgHintLabel(n + 1)}: ${_challenge.hints[n](l10n)}',
          mood: CogMood.explaining,
        ),
      if (!_solved) ...[
        const SizedBox(height: AppSizes.gap12),
        Row(
          children: [
            Flexible(
              child: Text(l10n.mgStarsLeft, style: AppTextStyles.bodyBold),
            ),
            const SizedBox(width: AppSizes.gap8),
            Semantics(
              label: l10n.starsCount(_starsNow),
              excludeSemantics: true,
              child: StarRow(
                key: const ValueKey('mg-stars-left'),
                stars: _starsNow,
              ),
            ),
          ],
        ),
        if (_hintsUsed < _challenge.hints.length) ...[
          const SizedBox(height: AppSizes.gap8),
          ChunkyButton(
            key: const ValueKey('mg-hint'),
            color: AppColors.star,
            onTap: _running ? null : _useHint,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lightbulb_rounded),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l10n.mgHintButton, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ],
      ],
    ];
  }
}

/// Fill-the-blank code: dark like the code boxes, with the blank shown as a
/// bright box holding what the student entered (or `?` while empty).
class _BlankCode extends StatelessWidget {
  const _BlankCode({required this.template, required this.entered});

  final String template;
  final String entered;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final style = AppTextStyles.code.copyWith(color: AppColors.codeText);
    final blank = entered.isEmpty ? ' ? ' : entered;
    final lines = template.split('\n');
    return Semantics(
      label: template.replaceFirst(blankMarker, '[ $blank ]'),
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.gap12),
        decoration: AppDecorations.card(color: AppColors.codeBackground),
        child: MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              maxScaleFactor: AppSizes.maxCodeTextScale,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _line(line, blank, style),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String line, String blank, TextStyle style) {
    final at = line.indexOf(blankMarker);
    if (at < 0) return Text(line, softWrap: false, style: style);
    return Text.rich(
      key: const ValueKey('mg-blank-code'),
      TextSpan(
        style: style,
        children: [
          TextSpan(text: line.substring(0, at)),
          TextSpan(
            text: blank,
            style: style.copyWith(
              color: AppColors.text,
              backgroundColor: AppColors.star,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: line.substring(at + blankMarker.length)),
        ],
      ),
      softWrap: false,
    );
  }
}

enum _AnswerState { normal, selected, right, wrong }

/// A chunky answer button, like the quiz: teal when picked, yellow-green
/// when right, red with a ✗ when it was a wrong try.
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
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? AppColors.surface
        : AppColors.text;
    return Semantics(
      selected: state == _AnswerState.selected,
      value: switch (state) {
        _AnswerState.right => l10n.quizAnswerRight,
        _AnswerState.wrong => l10n.quizAnswerWrong,
        _ => null,
      },
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
