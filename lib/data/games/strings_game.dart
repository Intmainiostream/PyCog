import '../../models/match_game.dart';

/// Lesson 7 game: "Label the Robot Box", Strings edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box). Each box is a string expression, and the student drops its result
/// into it. No setup line.
///
/// Chips are written exactly as Python's print() shows the result: text
/// without quotes (`Hi, Cog`), numbers as digits (`3`). Because print()
/// shows "55" and 55 the same way, no two chips in a round look alike, so a
/// number chip can never be mistaken for a text chip. Every box and chip
/// was checked in real Python 3.13, and test/game7_test.dart checks them
/// again on every test run. Hints never name the right box. Text lives in
/// the .arb files (keys game7…); hint N matches chip N below.
final List<GameRound> stringsGame = [
  // Round 1: joining with + (one with the space missing) and repeating
  // with *.
  GameRound(
    intro: (l10n) => l10n.game7R1Intro,
    boxes: const [
      GameBox('"Hi, " + "Cog"'),
      GameBox('"Hi" + "Cog"'),
      GameBox('"Ha" * 3'),
      GameBox('"Go" * 2'),
    ],
    chips: [
      GameChip(
        value: 'Hi, Cog',
        box: '"Hi, " + "Cog"',
        hint: (l10n) => l10n.game7R1Hint1,
      ),
      GameChip(
        value: 'HiCog',
        box: '"Hi" + "Cog"',
        hint: (l10n) => l10n.game7R1Hint2,
      ),
      GameChip(
        value: 'HaHaHa',
        box: '"Ha" * 3',
        hint: (l10n) => l10n.game7R1Hint3,
      ),
      GameChip(
        value: 'GoGo',
        box: '"Go" * 2',
        hint: (l10n) => l10n.game7R1Hint4,
      ),
    ],
  ),

  // Round 2: len() (the space counts) and [ ] (counting from 0).
  GameRound(
    intro: (l10n) => l10n.game7R2Intro,
    boxes: const [
      GameBox('len("Cog")'),
      GameBox('len("Hi Cog")'),
      GameBox('"Cog"[0]'),
      GameBox('"Cog"[2]'),
    ],
    chips: [
      GameChip(
        value: '3',
        box: 'len("Cog")',
        hint: (l10n) => l10n.game7R2Hint1,
      ),
      GameChip(
        value: '6',
        box: 'len("Hi Cog")',
        hint: (l10n) => l10n.game7R2Hint2,
      ),
      GameChip(value: 'C', box: '"Cog"[0]', hint: (l10n) => l10n.game7R2Hint3),
      GameChip(value: 'g', box: '"Cog"[2]', hint: (l10n) => l10n.game7R2Hint4),
    ],
  ),

  // Round 3: .upper() / .lower(), and the look-alike pair "5" + "5" (text
  // 55) vs 5 + 5 (number 10).
  GameRound(
    intro: (l10n) => l10n.game7R3Intro,
    boxes: const [
      GameBox('"cog".upper()'),
      GameBox('"COG".lower()'),
      GameBox('"5" + "5"'),
      GameBox('5 + 5'),
    ],
    chips: [
      GameChip(
        value: 'COG',
        box: '"cog".upper()',
        hint: (l10n) => l10n.game7R3Hint1,
      ),
      GameChip(
        value: 'cog',
        box: '"COG".lower()',
        hint: (l10n) => l10n.game7R3Hint2,
      ),
      GameChip(
        value: '55',
        box: '"5" + "5"',
        hint: (l10n) => l10n.game7R3Hint3,
      ),
      GameChip(value: '10', box: '5 + 5', hint: (l10n) => l10n.game7R3Hint4),
    ],
  ),
];
