import '../../models/match_game.dart';

/// Lesson 6 game: "Label the Robot Box", Math Operators edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box). Each box is a math expression, and the student drops its answer
/// into it. No setup line: the boxes need no values.
///
/// Chips are written exactly as Python's print() shows the answer, so `5`
/// (a whole number) and `5.0` (a float, from `/`) are different chips. Every
/// box and chip was checked in real Python 3.13, with the exact type, and
/// test/game6_test.dart checks them again on every test run. No two boxes in
/// a round have the same answer. Hints never name the right box. Text lives
/// in the .arb files (keys game6…); hint N matches chip N below.
final List<GameRound> mathOperatorsGame = [
  // Round 1: + - * with easy numbers. `3 * 4` and `3 + 4` look alike.
  GameRound(
    intro: (l10n) => l10n.game6R1Intro,
    boxes: const [
      GameBox('2 + 3'),
      GameBox('10 - 4'),
      GameBox('3 * 4'),
      GameBox('3 + 4'),
    ],
    chips: [
      GameChip(value: '5', box: '2 + 3', hint: (l10n) => l10n.game6R1Hint1),
      GameChip(value: '6', box: '10 - 4', hint: (l10n) => l10n.game6R1Hint2),
      GameChip(value: '12', box: '3 * 4', hint: (l10n) => l10n.game6R1Hint3),
      GameChip(value: '7', box: '3 + 4', hint: (l10n) => l10n.game6R1Hint4),
    ],
  ),

  // Round 2: / always gives a decimal (5.0); // gives a whole number (5);
  // % gives what is left over.
  GameRound(
    intro: (l10n) => l10n.game6R2Intro,
    boxes: const [
      GameBox('10 / 2'),
      GameBox('10 // 2'),
      GameBox('7 // 2'),
      GameBox('7 % 2'),
    ],
    chips: [
      GameChip(value: '5.0', box: '10 / 2', hint: (l10n) => l10n.game6R2Hint1),
      GameChip(value: '5', box: '10 // 2', hint: (l10n) => l10n.game6R2Hint2),
      GameChip(value: '3', box: '7 // 2', hint: (l10n) => l10n.game6R2Hint3),
      GameChip(value: '1', box: '7 % 2', hint: (l10n) => l10n.game6R2Hint4),
    ],
  ),

  // Round 3: order of operations and **. Two look-alike pairs:
  // 2 + 3 * 4 vs (2 + 3) * 4, and 2 ** 3 vs 3 ** 2.
  GameRound(
    intro: (l10n) => l10n.game6R3Intro,
    boxes: const [
      GameBox('2 + 3 * 4'),
      GameBox('(2 + 3) * 4'),
      GameBox('2 ** 3'),
      GameBox('3 ** 2'),
    ],
    chips: [
      GameChip(
        value: '14',
        box: '2 + 3 * 4',
        hint: (l10n) => l10n.game6R3Hint1,
      ),
      GameChip(
        value: '20',
        box: '(2 + 3) * 4',
        hint: (l10n) => l10n.game6R3Hint2,
      ),
      GameChip(value: '8', box: '2 ** 3', hint: (l10n) => l10n.game6R3Hint3),
      GameChip(value: '9', box: '3 ** 2', hint: (l10n) => l10n.game6R3Hint4),
    ],
  ),
];
