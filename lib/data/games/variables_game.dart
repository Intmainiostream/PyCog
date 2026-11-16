import '../../models/match_game.dart';

/// Lesson 1 game: "Label the Robot Box". 3 rounds, each a little harder.
///
/// Cog's lines live in lib/l10n/app_en.arb and app_tl.arb (keys game1…).
/// Each round's intro gives the clues needed to tell similar values apart
/// (e.g. which number is the battery). Chips are shuffled on screen.
final List<GameRound> variablesGame = [
  // Round 1: numbers and words.
  GameRound(
    intro: (l10n) => l10n.game1R1Intro,
    boxes: const [
      GameBox('robot_name'),
      GameBox('battery'),
      GameBox('wheels'),
      GameBox('color'),
    ],
    chips: [
      GameChip(
        value: '"Cog"',
        box: 'robot_name',
        hint: (l10n) => l10n.game1R1HintCog,
      ),
      GameChip(value: '80', box: 'battery', hint: (l10n) => l10n.game1R1Hint80),
      GameChip(value: '4', box: 'wheels', hint: (l10n) => l10n.game1R1Hint4),
      GameChip(
        value: '"teal"',
        box: 'color',
        hint: (l10n) => l10n.game1R1HintTeal,
      ),
    ],
  ),

  // Round 2: adds True / False.
  GameRound(
    intro: (l10n) => l10n.game1R2Intro,
    boxes: const [
      GameBox('robot_name'),
      GameBox('speed'),
      GameBox('is_moving'),
      GameBox('home_city'),
    ],
    chips: [
      GameChip(
        value: '"Bolt"',
        box: 'robot_name',
        hint: (l10n) => l10n.game1R2HintBolt,
      ),
      GameChip(value: '5', box: 'speed', hint: (l10n) => l10n.game1R2Hint5),
      GameChip(
        value: 'True',
        box: 'is_moving',
        hint: (l10n) => l10n.game1R2HintTrue,
      ),
      GameChip(
        value: '"Manila"',
        box: 'home_city',
        hint: (l10n) => l10n.game1R2HintManila,
      ),
    ],
  ),

  // Round 3: the "changing it" twist. battery starts at 100; drop 60 on it.
  GameRound(
    intro: (l10n) => l10n.game1R3Intro,
    boxes: const [
      GameBox('battery', startValue: '100'),
      GameBox('robot_name'),
      GameBox('is_charging'),
      GameBox('steps'),
    ],
    chips: [
      GameChip(value: '60', box: 'battery', hint: (l10n) => l10n.game1R3Hint60),
      GameChip(
        value: '"Cog"',
        box: 'robot_name',
        hint: (l10n) => l10n.game1R3HintCog,
      ),
      GameChip(
        value: 'False',
        box: 'is_charging',
        hint: (l10n) => l10n.game1R3HintFalse,
      ),
      GameChip(value: '250', box: 'steps', hint: (l10n) => l10n.game1R3Hint250),
    ],
  ),
];
