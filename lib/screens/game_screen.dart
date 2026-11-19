import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../models/match_game.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/code_box.dart';
import '../widgets/cog_feedback_card.dart';
import '../widgets/cog_art.dart';
import '../widgets/game_widgets.dart';
import '../widgets/lesson_top_bar.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import 'game_results_screen.dart';
import '../sound/sounds.dart';

/// What Cog is saying under the boxes right now.
enum _Say { nothing, cheer, hint, tapValueFirst, roundDone }

/// "Label the Robot Box": drag (or tap) each value chip into its box.
///
/// Reusable: give it a [Lesson] whose `game` rounds are filled in (see
/// lib/data/games/). No timer, no lives. Wrong drops only lower the bonus
/// stars at the end. Everything Cog says is worked out from the current
/// state each time the screen draws, so switching language updates it
/// right away.
class GameScreen extends StatefulWidget {
  const GameScreen({
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

  /// Shuffles the chips. Tests pass a seeded one.
  final math.Random? random;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// For each round: the order to show its chips in (by value).
  late final List<List<String>> _chipOrder;

  int _r = 0; // current round
  final Map<String, String> _placed = {}; // chip value -> box name (this round)
  String? _selected; // chip picked by tapping
  final Map<String, int> _shakes = {}; // chip value -> wrong drops (animation)
  int _wrong = 0; // wrong drops in the whole game
  _Say _say = _Say.nothing;
  String? _hintChip; // which chip Cog's hint is about
  int _cheers = 0; // rotates through the cheers
  bool _finishing = false;

  List<GameRound> get _rounds => widget.lesson.game;
  GameRound get _round => _rounds[_r];
  bool get _roundDone => _placed.length == _round.chips.length;
  bool get _isLastRound => _r == _rounds.length - 1;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? math.Random();
    _chipOrder = [
      for (final round in _rounds)
        [for (final chip in round.chips) chip.value]..shuffle(random),
    ];
  }

  /// The chip with this value in the current round.
  GameChip _chip(String value) =>
      _round.chips.firstWhere((chip) => chip.value == value);

  /// The values matched into a box so far, in the order they were placed.
  List<String> _valuesIn(String boxName) => [
    for (final MapEntry(key: value, value: box) in _placed.entries)
      if (box == boxName) value,
  ];

  /// A box is full once every chip that belongs in it has been placed.
  /// (Usually one chip per box; a True/False box can take several.)
  bool _isFull(String boxName) =>
      _valuesIn(boxName).length >=
      _round.chips.where((chip) => chip.box == boxName).length;

  void _tapChip(String value) {
    setState(() {
      _selected = _selected == value ? null : value;
      if (_say == _Say.tapValueFirst) _say = _Say.nothing;
    });
  }

  void _tapBox(String boxName) {
    final picked = _selected;
    if (picked == null) {
      setState(() => _say = _Say.tapValueFirst);
      return;
    }
    _place(picked, boxName);
  }

  /// A chip was dropped (or tap-placed) on a box.
  void _place(String value, String boxName) {
    if (_placed.containsKey(value) || _isFull(boxName)) return;
    setState(() {
      _selected = null;
      if (_chip(value).box == boxName) {
        Sounds.play(Sfx.correct);
        _placed[value] = boxName; // snaps in
        _cheers++;
        _say = _roundDone ? _Say.roundDone : _Say.cheer;
      } else {
        Sounds.play(Sfx.wrong);
        _wrong++; // bounces back
        _shakes[value] = (_shakes[value] ?? 0) + 1;
        _hintChip = value;
        _say = _Say.hint;
      }
    });
  }

  void _nextRound() {
    if (_isLastRound) {
      _finish();
      return;
    }
    setState(() {
      _r++;
      _placed.clear();
      _selected = null;
      _shakes.clear();
      _say = _Say.nothing;
      _hintChip = null;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final stars = starsForMistakes(_wrong);
    final newBest = await widget.progress.saveBonusStars(
      widget.lesson.id,
      stars,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameResultsScreen(
          lesson: widget.lesson,
          lessonNumber: widget.lessonNumber,
          stars: stars,
          isNewBest: newBest,
          settings: widget.settings,
          progress: widget.progress,
        ),
      ),
    );
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

            final topBar = LessonTopBar(
              sidePadding: sidePadding,
              current: _r + 1,
              total: _rounds.length,
              progressLabel: l10n.gameProgress(_r + 1, _rounds.length),
              closeLabel: l10n.gameClose,
              onClose: () => Navigator.of(context).pop(),
              onSettings: () => showSettingsSheet(context, widget.settings),
            );

            return Column(
              children: [
                topBar,
                Expanded(
                  child: wide
                      ? _wideLayout(l10n, sidePadding)
                      : _narrowLayout(l10n, sidePadding, constraints),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Phones: boxes scroll in the middle; the chip tray stays at the bottom
  /// so the chips are always in reach.
  Widget _narrowLayout(
    AppLocalizations l10n,
    double sidePadding,
    BoxConstraints screen,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('game-scroll-$_r'),
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              AppSizes.gap8,
              sidePadding,
              AppSizes.gap16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading(l10n),
                const SizedBox(height: AppSizes.gap8),
                _cogIntro(l10n),
                ..._setup(),
                const SizedBox(height: AppSizes.gap16),
                _boxes(l10n),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.outline,
                width: AppSizes.outlineWidth,
              ),
            ),
          ),
          // The tray never takes more than ~half the screen; if it would,
          // it scrolls on its own.
          constraints: BoxConstraints(
            maxHeight: screen.maxHeight * AppSizes.gameTrayMaxFraction,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              AppSizes.gap8,
              sidePadding,
              AppSizes.gap12,
            ),
            child: _tray(l10n),
          ),
        ),
      ],
    );
  }

  /// Landscape: Cog, feedback and chips on the left; boxes on the right, so
  /// chips and boxes are side by side for dragging.
  Widget _wideLayout(AppLocalizations l10n, double sidePadding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              AppSizes.gap8,
              AppSizes.gap12,
              AppSizes.gap16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading(l10n),
                const SizedBox(height: AppSizes.gap8),
                _cogIntro(l10n),
                ..._setup(),
                const SizedBox(height: AppSizes.gap8),
                _tray(l10n),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            key: ValueKey('game-scroll-$_r'),
            padding: EdgeInsets.fromLTRB(
              AppSizes.gap12,
              AppSizes.gap16,
              sidePadding,
              AppSizes.gap16,
            ),
            child: _boxes(l10n, columns: AppSizes.gameNarrowBoxColumns),
          ),
        ),
      ],
    );
  }

  Widget _heading(AppLocalizations l10n) {
    return Text(
      '${l10n.lessonNumber(widget.lessonNumber)} · '
      '${widget.lesson.title(l10n)} · ${l10n.gameTitle}',
      textAlign: TextAlign.center,
      style: AppTextStyles.small,
    );
  }

  /// The round's optional setup code (e.g. `battery = 10`) in a code box.
  /// Returns nothing for rounds without setup, so those look unchanged.
  List<Widget> _setup() => [
    if (_round.setup.isNotEmpty) ...[
      const SizedBox(height: AppSizes.gap12),
      CodeBox(lines: _round.setup),
    ],
  ];

  /// Small Cog beside the speech bubble with the round's story.
  Widget _cogIntro(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CogArt(pose: CogPose.waving, size: AppSizes.gameCogSize),
        const SizedBox(width: AppSizes.gap4),
        Expanded(
          child: Semantics(
            header: true,
            child: SpeechBubble(
              text: _round.intro(l10n),
              tail: TailSide.left,
              textAlign: TextAlign.start,
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }

  /// The labeled boxes in a grid (2 per row on phones, 4 on wide areas).
  Widget _boxes(AppLocalizations l10n, {int? columns}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Never more columns than boxes (2 boxes shouldn't sit in a 4-wide
        // grid). With 4 boxes this changes nothing.
        final cols = math.min(
          columns ??
              (constraints.maxWidth >= AppSizes.gameWideBoxMinWidth
                  ? AppSizes.gameWideBoxColumns
                  : AppSizes.gameNarrowBoxColumns),
          _round.boxes.length,
        );
        const gap = AppSizes.gap12;
        final itemWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: AppSizes.gap16,
          children: [
            for (final box in _round.boxes)
              SizedBox(
                width: itemWidth,
                child: GameBoxView(
                  key: ValueKey('game-box-$_r-${box.name}'),
                  name: box.name,
                  startValue: box.startValue,
                  placedValues: _valuesIn(box.name),
                  full: _isFull(box.name),
                  semanticLabel: _boxLabel(l10n, box),
                  onTap: () => _tapBox(box.name),
                  onDrop: (value) => _place(value, box.name),
                ),
              ),
          ],
        );
      },
    );
  }

  String _boxLabel(AppLocalizations l10n, GameBox box) {
    final values = _valuesIn(box.name);
    if (values.isNotEmpty) {
      return l10n.gameBoxFilled(box.name, values.join(', '));
    }
    if (box.startValue != null) {
      return l10n.gameBoxNeedsUpdate(box.name, box.startValue!);
    }
    return l10n.gameBoxEmpty(box.name);
  }

  /// Cog's feedback, then the chips still to place, or the Next button.
  Widget _tray(AppLocalizations l10n) {
    final feedback = _feedbackText(l10n);
    final remaining = [
      for (final value in _chipOrder[_r])
        if (!_placed.containsKey(value)) value,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feedback != null) ...[
          CogFeedbackCard(
            text: feedback,
            mood: switch (_say) {
              _Say.cheer || _Say.roundDone => CogMood.happy,
              _Say.hint => CogMood.hint,
              _ => CogMood.explaining,
            },
          ),
          const SizedBox(height: AppSizes.gap8),
        ],
        if (_roundDone)
          ChunkyButton(
            color: AppColors.success,
            onTap: _nextRound,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _isLastRound ? l10n.gameSeeResults : l10n.gameNextRound,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          )
        else ...[
          Text(
            l10n.gameInstructions,
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSizes.gap8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSizes.gap8,
            runSpacing: AppSizes.gap4,
            children: [
              for (final value in remaining)
                GameValueChip(
                  key: ValueKey('game-chip-$_r-$value'),
                  value: value,
                  selected: _selected == value,
                  shakeCount: _shakes[value] ?? 0,
                  semanticLabel: l10n.gameChipLabel(value),
                  onTap: () => _tapChip(value),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String? _feedbackText(AppLocalizations l10n) {
    switch (_say) {
      case _Say.nothing:
        return null;
      case _Say.cheer:
        final cheers = [l10n.gameCheer1, l10n.gameCheer2, l10n.gameCheer3];
        return cheers[(_cheers - 1) % cheers.length];
      case _Say.hint:
        return _chip(_hintChip!).hint(l10n);
      case _Say.tapValueFirst:
        return l10n.gameTapValueFirst;
      case _Say.roundDone:
        return l10n.gameRoundDone;
    }
  }
}
