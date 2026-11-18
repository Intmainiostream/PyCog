import '../../models/lesson_card.dart';
import '../../models/match_game.dart';

/// Lesson 8 game: "Label the Robot Box", Lists edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box). Each round shows the backpack list in its setup at the top (on 3
/// lines, like the lesson, so it fits a 360px phone); each box is a list
/// expression, and the student drops its result into it. Round 3's setup
/// also changes the list before the boxes ask about it.
///
/// Chips are written exactly as Python's print() shows the result: text
/// without quotes (`sword`), numbers as digits, True / False. No two chips
/// in a round look the same. Every box and chip was checked in real Python
/// 3.13 with the round's setup, and test/game8_test.dart checks them again
/// on every test run. Hints never name the right box. Text lives in the
/// .arb files (keys game8…); hint N matches chip N below.
const _backpack = [
  CodeLine('items = ["sword",'),
  CodeLine('         "shield",'),
  CodeLine('         "potion"]'),
];

final List<GameRound> listsGame = [
  // Round 1: picking by index, counting from 0, plus len(). (Negative
  // indexes like items[-1] were not taught in Lesson 8.)
  GameRound(
    intro: (l10n) => l10n.game8R1Intro,
    setup: _backpack,
    boxes: const [
      GameBox('items[0]'),
      GameBox('items[1]'),
      GameBox('items[2]'),
      GameBox('len(items)'),
    ],
    chips: [
      GameChip(
        value: 'sword',
        box: 'items[0]',
        hint: (l10n) => l10n.game8R1Hint1,
      ),
      GameChip(
        value: 'shield',
        box: 'items[1]',
        hint: (l10n) => l10n.game8R1Hint2,
      ),
      GameChip(
        value: 'potion',
        box: 'items[2]',
        hint: (l10n) => l10n.game8R1Hint3,
      ),
      GameChip(
        value: '3',
        box: 'len(items)',
        hint: (l10n) => l10n.game8R1Hint4,
      ),
    ],
  ),

  // Round 2: len() and in, with one False. len("sword") counts characters
  // (a string), not items.
  GameRound(
    intro: (l10n) => l10n.game8R2Intro,
    setup: _backpack,
    boxes: const [
      GameBox('len(items)'),
      GameBox('"sword" in items'),
      GameBox('"map" in items'),
      GameBox('len("sword")'),
    ],
    chips: [
      GameChip(
        value: '3',
        box: 'len(items)',
        hint: (l10n) => l10n.game8R2Hint1,
      ),
      GameChip(
        value: 'True',
        box: '"sword" in items',
        hint: (l10n) => l10n.game8R2Hint2,
      ),
      GameChip(
        value: 'False',
        box: '"map" in items',
        hint: (l10n) => l10n.game8R2Hint3,
      ),
      GameChip(
        value: '5',
        box: 'len("sword")',
        hint: (l10n) => l10n.game8R2Hint4,
      ),
    ],
  ),

  // Round 3: the setup changes the list (append adds "map" at the end,
  // then axe replaces sword), and the boxes ask about the new list.
  GameRound(
    intro: (l10n) => l10n.game8R3Intro,
    setup: const [
      ..._backpack,
      CodeLine('items.append("map")'),
      CodeLine('items[0] = "axe"'),
    ],
    boxes: const [
      GameBox('len(items)'),
      GameBox('items[3]'),
      GameBox('items[0]'),
      GameBox('"sword" in items'),
    ],
    chips: [
      GameChip(
        value: '4',
        box: 'len(items)',
        hint: (l10n) => l10n.game8R3Hint1,
      ),
      GameChip(
        value: 'map',
        box: 'items[3]',
        hint: (l10n) => l10n.game8R3Hint2,
      ),
      GameChip(
        value: 'axe',
        box: 'items[0]',
        hint: (l10n) => l10n.game8R3Hint3,
      ),
      GameChip(
        value: 'False',
        box: '"sword" in items',
        hint: (l10n) => l10n.game8R3Hint4,
      ),
    ],
  ),
];
