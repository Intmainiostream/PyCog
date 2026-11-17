import '../../models/match_game.dart';

/// Lesson 4 game: "Label the Robot Box", Loops edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box, no setup line). Each box is a range; the student drops the numbers
/// it gives into it. Every box and chip was checked against real Python's
/// range before being written here. Text lives in the .arb files (keys
/// game4…); hint N matches chip N below. Code is the same in every language.
final List<GameRound> loopsGame = [
  // Round 1: range with one number (starts at 0).
  GameRound(
    intro: (l10n) => l10n.game4R1Intro,
    boxes: const [
      GameBox('range(3)'),
      GameBox('range(5)'),
      GameBox('range(2)'),
      GameBox('range(4)'),
    ],
    chips: [
      GameChip(
        value: '0, 1, 2',
        box: 'range(3)',
        hint: (l10n) => l10n.game4R1Hint1,
      ),
      GameChip(
        value: '0, 1, 2, 3, 4',
        box: 'range(5)',
        hint: (l10n) => l10n.game4R1Hint2,
      ),
      GameChip(
        value: '0, 1',
        box: 'range(2)',
        hint: (l10n) => l10n.game4R1Hint3,
      ),
      GameChip(
        value: '0, 1, 2, 3',
        box: 'range(4)',
        hint: (l10n) => l10n.game4R1Hint4,
      ),
    ],
  ),

  // Round 2: range with two numbers (start, and stop BEFORE the second).
  GameRound(
    intro: (l10n) => l10n.game4R2Intro,
    boxes: const [
      GameBox('range(1, 4)'),
      GameBox('range(2, 5)'),
      GameBox('range(3, 6)'),
      GameBox('range(1, 3)'),
    ],
    chips: [
      GameChip(
        value: '1, 2, 3',
        box: 'range(1, 4)',
        hint: (l10n) => l10n.game4R2Hint1,
      ),
      GameChip(
        value: '2, 3, 4',
        box: 'range(2, 5)',
        hint: (l10n) => l10n.game4R2Hint2,
      ),
      GameChip(
        value: '3, 4, 5',
        box: 'range(3, 6)',
        hint: (l10n) => l10n.game4R2Hint3,
      ),
      GameChip(
        value: '1, 2',
        box: 'range(1, 3)',
        hint: (l10n) => l10n.game4R2Hint4,
      ),
    ],
  ),

  // Round 3: both kinds mixed, with a look-alike pair: range(3) and
  // range(1, 4) both make 3 numbers, but different ones.
  GameRound(
    intro: (l10n) => l10n.game4R3Intro,
    boxes: const [
      GameBox('range(3)'),
      GameBox('range(1, 4)'),
      GameBox('range(4)'),
      GameBox('range(2, 4)'),
    ],
    chips: [
      GameChip(
        value: '0, 1, 2',
        box: 'range(3)',
        hint: (l10n) => l10n.game4R3Hint1,
      ),
      GameChip(
        value: '1, 2, 3',
        box: 'range(1, 4)',
        hint: (l10n) => l10n.game4R3Hint2,
      ),
      GameChip(
        value: '0, 1, 2, 3',
        box: 'range(4)',
        hint: (l10n) => l10n.game4R3Hint3,
      ),
      GameChip(
        value: '2, 3',
        box: 'range(2, 4)',
        hint: (l10n) => l10n.game4R3Hint4,
      ),
    ],
  ),
];
