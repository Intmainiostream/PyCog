import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/minigame/levels.dart';
import '../data/minigame_progress.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/minigame.dart';
import '../playground/python_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_feedback_card.dart';
import '../widgets/cog_art.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/title_top_bar.dart';
import 'challenge_screen.dart';
import '../sound/sounds.dart';
import '../sound/sound_on_show.dart';
import '../sound/music_zone.dart';

/// The MINIGAME map (opened by MINIGAME on the home screen): 10 levels of
/// challenges, with the stars earned on each. A level opens when its Play
/// lesson is finished and (from Level 2) [challengesToUnlockNext]
/// challenges of the level before it have at least 1 star.
class MinigameMapScreen extends StatelessWidget {
  MinigameMapScreen({
    super.key,
    required this.settings,
    required this.progress,
    List<MinigameLevel>? levels,
    this.engine,
  }) : levels = levels ?? minigameLevels;

  final SettingsController settings;
  final MinigameProgress progress;

  /// Defaults to the real levels in lib/data/minigame/. Tests pass others.
  final List<MinigameLevel> levels;

  /// Defaults to the real Python. Tests pass a fake.
  final PythonEngine? engine;

  void _onLevelTap(BuildContext context, int index, bool unlocked) {
    final level = levels[index];
    final l10n = AppLocalizations.of(context);
    if (unlocked && level.challenges.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MinigameLevelScreen(
            level: level,
            levels: levels,
            settings: settings,
            progress: progress,
            engine: engine,
          ),
        ),
      );
      return;
    }
    final message = unlocked
        ? l10n.mgLevelSoon
        : lockedMessage(l10n, progress, levels, index);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MusicZone(
      song: Song.game,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: progress, // stars and open levels update live
          builder: (context, _) => SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.max(
                  AppSizes.screenPadding,
                  (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
                );
                final unlocked = progress.unlockedCount(levels);
                return Column(
                  children: [
                    TitleTopBar(
                      padding: side,
                      title: l10n.mgMapTitle,
                      backLabel: l10n.homeBackToHome,
                      settingsLabel: l10n.settingsTooltip,
                      onSettings: () => showSettingsSheet(context, settings),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          side,
                          AppSizes.gap4,
                          side,
                          AppSizes.gap24,
                        ),
                        children: [
                          CogSays(text: l10n.mgMapIntro),
                          const SizedBox(height: AppSizes.gap8),
                          Text(
                            l10n.mgUnlockRule,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.small,
                          ),
                          const SizedBox(height: AppSizes.gap16),
                          for (final (i, level) in levels.indexed) ...[
                            _LevelTile(
                              key: ValueKey('mg-level-${level.number}'),
                              level: level,
                              unlocked: i < unlocked,
                              lockedDetail: i < unlocked
                                  ? null
                                  : lockedDetail(l10n, progress, levels, i),
                              stars: progress.levelStars(level),
                              solved: progress.solvedCount(level),
                              onTap: () =>
                                  _onLevelTap(context, i, i < unlocked),
                            ),
                            const SizedBox(height: AppSizes.gap12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Small Cog beside a speech bubble (like the mini game intro).
class CogSays extends StatelessWidget {
  const CogSays({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CogArt(pose: CogPose.waving, size: AppSizes.gameCogSize),
        const SizedBox(width: AppSizes.gap4),
        Expanded(
          child: SpeechBubble(
            text: text,
            tail: TailSide.left,
            textAlign: TextAlign.start,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}

/// One level on the map: its number (or a lock), the stars earned, and
/// how many challenges are done.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.level,
    required this.unlocked,
    this.lockedDetail,
    required this.stars,
    required this.solved,
    required this.onTap,
  });

  final MinigameLevel level;
  final bool unlocked;

  /// What a locked level says under its name (why it is locked).
  final String? lockedDetail;
  final int stars;
  final int solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = level.challenges.length;
    final empty = total == 0;
    final maxStars = total * 3;
    final open = unlocked && !empty;

    final String detail;
    if (!unlocked) {
      detail = lockedDetail ?? l10n.mgLocked;
    } else if (empty) {
      detail = l10n.mgLevelSoon;
    } else {
      detail = l10n.mgSolved(solved, total);
    }

    return Semantics(
      label: [
        l10n.mgLevel(level.number),
        if (!empty && unlocked) l10n.mgLevelStars(stars, maxStars),
        detail,
      ].join(', '),
      button: true,
      excludeSemantics: true,
      child: ChunkyButton(
        color: open ? AppColors.surface : AppColors.locked,
        disabledColor: AppColors.locked,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap12,
          vertical: AppSizes.gap12,
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.minTouchTarget,
              height: AppSizes.minTouchTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: open ? AppColors.teal : AppColors.lockedDark,
                shape: BoxShape.circle,
                border: AppDecorations.outline,
              ),
              child: unlocked
                  ? Text(
                      '${level.number}',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.surface,
                      ),
                    )
                  : const Icon(Icons.lock_rounded, color: AppColors.surface),
            ),
            const SizedBox(width: AppSizes.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mgLevel(level.number),
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    detail,
                    style: AppTextStyles.small.copyWith(
                      color: open ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (open) ...[
              const SizedBox(width: AppSizes.gap8),
              const Icon(Icons.star_rounded, color: AppColors.star, size: 26),
              const SizedBox(width: 2),
              Text(
                '$stars/$maxStars',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.text),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One level's challenges: each with its number, title, type and best
/// stars. Every challenge in an open level can be played, in any order.
class MinigameLevelScreen extends StatelessWidget {
  const MinigameLevelScreen({
    super.key,
    required this.level,
    required this.levels,
    required this.settings,
    required this.progress,
    this.engine,
  });

  final MinigameLevel level;
  final List<MinigameLevel> levels;
  final SettingsController settings;
  final MinigameProgress progress;
  final PythonEngine? engine;

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeScreen(
          level: level,
          index: index,
          levels: levels,
          settings: settings,
          progress: progress,
          engine: engine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MusicZone(
      song: Song.game,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: progress,
          builder: (context, _) => SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.max(
                  AppSizes.screenPadding,
                  (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
                );
                final total = level.challenges.length;
                // The last level has no next level to open. When all of its
                // challenges have a star, the whole game is done.
                final isLast = identical(level, levels.last);
                final allDone =
                    isLast && total > 0 && progress.solvedCount(level) == total;
                final gameTotal = levels.fold(
                  0,
                  (sum, l) => sum + l.challenges.length,
                );
                return Column(
                  children: [
                    TitleTopBar(
                      padding: side,
                      title: l10n.mgLevel(level.number),
                      backLabel: l10n.lessonBack,
                      settingsLabel: l10n.settingsTooltip,
                      onSettings: () => showSettingsSheet(context, settings),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          side,
                          AppSizes.gap4,
                          side,
                          AppSizes.gap24,
                        ),
                        children: [
                          if (allDone) ...[
                            // The big ending: the victory sound.
                            SoundOnShow(
                              play: () => Sounds.play(Sfx.victory),
                              child: CogFeedbackCard(
                                key: const ValueKey('mg-all-done'),
                                text: l10n.mgAllDone(gameTotal),
                                mood: CogMood.happy,
                              ),
                            ),
                            const SizedBox(height: AppSizes.gap12),
                          ],
                          // A star icon, not an emoji: the app fonts have no
                          // emoji.
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${l10n.mgSolved(progress.solvedCount(level), total)} · ',
                                ),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: AppColors.star,
                                    size: 22,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${progress.levelStars(level)}/${total * 3}',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyBold,
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: AppSizes.gap4),
                            Text(
                              key: const ValueKey('mg-unlock-rule'),
                              l10n.mgUnlockRule,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.small,
                            ),
                          ],
                          const SizedBox(height: AppSizes.gap16),
                          for (final (i, challenge)
                              in level.challenges.indexed) ...[
                            _ChallengeTile(
                              key: ValueKey('mg-challenge-${challenge.id}'),
                              number: i + 1,
                              challenge: challenge,
                              stars: progress.bestStars(challenge.id),
                              onTap: () => _open(context, i),
                            ),
                            const SizedBox(height: AppSizes.gap12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The icon and name of a challenge type.
(IconData, String) challengeTypeLabel(
  AppLocalizations l10n,
  ChallengeType type,
) => switch (type) {
  ChallengeType.quiz => (Icons.quiz_rounded, l10n.mgTypeQuiz),
  ChallengeType.fillBlank => (Icons.edit_note_rounded, l10n.mgTypeFillBlank),
  ChallengeType.fixBug => (Icons.build_rounded, l10n.mgTypeFixBug),
  ChallengeType.writeCode => (Icons.code_rounded, l10n.mgTypeWriteCode),
};

/// Three small stars, filled up to [stars].
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < stars ? AppColors.star : AppColors.lockedDark,
            size: size,
          ),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    super.key,
    required this.number,
    required this.challenge,
    required this.stars,
    required this.onTap,
  });

  final int number;
  final Challenge challenge;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, typeName) = challengeTypeLabel(l10n, challenge.type);
    return Semantics(
      label: [
        l10n.mgChallenge(number),
        challenge.title(l10n),
        typeName,
        l10n.starsCount(stars),
      ].join(', '),
      button: true,
      excludeSemantics: true,
      child: ChunkyButton(
        color: stars > 0 ? AppColors.mint : AppColors.surface,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap12,
          vertical: AppSizes.gap12,
        ),
        child: Row(
          children: [
            Text(
              '$number',
              style: AppTextStyles.title.copyWith(color: AppColors.tealDark),
            ),
            const SizedBox(width: AppSizes.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title(l10n),
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          typeName,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.gap8),
            StarRow(stars: stars),
          ],
        ),
      ),
    );
  }
}

/// Everything a locked level still needs, one line each (shown when the
/// student taps it).
String lockedMessage(
  AppLocalizations l10n,
  MinigameProgress progress,
  List<MinigameLevel> levels,
  int index,
) {
  final why = progress.whyLocked(levels, index);
  return [
    if (why.needsLesson) l10n.mgNeedLesson(levels[index].number),
    if (why.needsStars) l10n.mgLevelLocked(levels[index - 1].number),
  ].join('\n');
}

/// The short reason under a locked level's name: the lesson first, since
/// it is done in Play mode.
String lockedDetail(
  AppLocalizations l10n,
  MinigameProgress progress,
  List<MinigameLevel> levels,
  int index,
) {
  final why = progress.whyLocked(levels, index);
  return why.needsLesson
      ? l10n.mgNeedLesson(levels[index].number)
      : l10n.mgLocked;
}
