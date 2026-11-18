import '../../models/lesson_card.dart';
import '../../models/match_game.dart';

/// Lesson 10 game: "Label the Robot Box", Logic edition.
///
/// Same reusable game screen and rules as the other games, and the same
/// True / False boxes as Lesson 3 (if_statements_game.dart): each round
/// shows its values above the boxes, and the student drops each check into
/// the box it gives. Text lives in the .arb files (keys game10…); hint N
/// matches chip N below. Code is the same in every language.
///
/// Every chip was checked in real Python 3.13 with its round's values, and
/// test/game10_test.dart checks them again on every test run. Hints never
/// name the right box.
const _boolBoxes = [GameBox('True'), GameBox('False')];

final List<GameRound> logicGame = [
  // Round 1: one and, two or, one not, with easy values. (Chips are at
  // most 24 letters: a chip row fits 25 at 360px.)
  GameRound(
    intro: (l10n) => l10n.game10R1Intro,
    setup: const [
      CodeLine('battery = 50'),
      CodeLine('lives = 0'),
      CodeLine('has_key = True'),
    ],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'battery > 20 and has_key',
        box: 'True',
        hint: (l10n) => l10n.game10R1Hint1,
      ),
      GameChip(
        value: 'has_key or lives > 0',
        box: 'True',
        hint: (l10n) => l10n.game10R1Hint2,
      ),
      GameChip(
        value: 'not has_key',
        box: 'False',
        hint: (l10n) => l10n.game10R1Hint3,
      ),
      GameChip(
        value: 'battery > 80 or has_key',
        box: 'True',
        hint: (l10n) => l10n.game10R1Hint4,
      ),
    ],
  ),

  // Round 2: the SAME checks with new values. Three answers change.
  GameRound(
    intro: (l10n) => l10n.game10R2Intro,
    setup: const [
      CodeLine('battery = 30'),
      CodeLine('lives = 2'),
      CodeLine('has_key = False'),
    ],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'battery > 20 and has_key',
        box: 'False',
        hint: (l10n) => l10n.game10R2Hint1,
      ),
      GameChip(
        value: 'has_key or lives > 0',
        box: 'True',
        hint: (l10n) => l10n.game10R2Hint2,
      ),
      GameChip(
        value: 'not has_key',
        box: 'True',
        hint: (l10n) => l10n.game10R2Hint3,
      ),
      GameChip(
        value: 'battery > 80 or has_key',
        box: 'False',
        hint: (l10n) => l10n.game10R2Hint4,
      ),
    ],
  ),

  // Round 3 (tricky): two operators per check. `key or gem and hp > 0`
  // is True because and goes first (reading left to right gives False);
  // the same check with brackets is False.
  GameRound(
    intro: (l10n) => l10n.game10R3Intro,
    setup: const [
      CodeLine('key = True'),
      CodeLine('gem = False'),
      CodeLine('hp = 0'),
    ],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'key or gem and hp > 0',
        box: 'True',
        hint: (l10n) => l10n.game10R3Hint1,
      ),
      GameChip(
        value: '(key or gem) and hp > 0',
        box: 'False',
        hint: (l10n) => l10n.game10R3Hint2,
      ),
      GameChip(
        value: 'not gem and key',
        box: 'True',
        hint: (l10n) => l10n.game10R3Hint3,
      ),
      GameChip(
        value: 'not key or hp > 0',
        box: 'False',
        hint: (l10n) => l10n.game10R3Hint4,
      ),
    ],
  ),
];
