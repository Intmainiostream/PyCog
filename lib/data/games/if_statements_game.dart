import '../../models/lesson_card.dart';
import '../../models/match_game.dart';

/// Lesson 3 game: "Label the Robot Box", If Statements edition.
///
/// Same reusable game screen and rules as Lessons 1 and 2. Two boxes, True
/// and False; each round shows a small setup (the variable values) above
/// them, and the student drops each condition chip into the box it evaluates
/// to. 2 chips belong in each box. Text lives in the .arb files (keys
/// game3…); hint N matches chip N below. Code is the same in every language.
const _boolBoxes = [GameBox('True'), GameBox('False')];

final List<GameRound> ifStatementsGame = [
  // Round 1: easy < and > checks.
  GameRound(
    intro: (l10n) => l10n.game3R1Intro,
    setup: const [CodeLine('battery = 10'), CodeLine('lives = 3')],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'battery < 20',
        box: 'True',
        hint: (l10n) => l10n.game3R1Hint1,
      ),
      GameChip(
        value: 'lives > 5',
        box: 'False',
        hint: (l10n) => l10n.game3R1Hint2,
      ),
      GameChip(
        value: 'battery > 50',
        box: 'False',
        hint: (l10n) => l10n.game3R1Hint3,
      ),
      GameChip(
        value: 'lives < 4',
        box: 'True',
        hint: (l10n) => l10n.game3R1Hint4,
      ),
    ],
  ),

  // Round 2: == and !=.
  GameRound(
    intro: (l10n) => l10n.game3R2Intro,
    setup: const [CodeLine('score = 50'), CodeLine('lives = 3')],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'lives == 3',
        box: 'True',
        hint: (l10n) => l10n.game3R2Hint1,
      ),
      GameChip(
        value: 'score == 40',
        box: 'False',
        hint: (l10n) => l10n.game3R2Hint2,
      ),
      GameChip(
        value: 'lives != 3',
        box: 'False',
        hint: (l10n) => l10n.game3R2Hint3,
      ),
      GameChip(
        value: 'score != 0',
        box: 'True',
        hint: (l10n) => l10n.game3R2Hint4,
      ),
    ],
  ),

  // Round 3: >= and <= when the values are equal (the tricky edge), plus a
  // == chip that looks close but is False (10 vs 100).
  GameRound(
    intro: (l10n) => l10n.game3R3Intro,
    setup: const [CodeLine('lives = 3'), CodeLine('score = 100')],
    boxes: _boolBoxes,
    chips: [
      GameChip(
        value: 'lives >= 3',
        box: 'True',
        hint: (l10n) => l10n.game3R3Hint1,
      ),
      GameChip(
        value: 'score <= 100',
        box: 'True',
        hint: (l10n) => l10n.game3R3Hint2,
      ),
      GameChip(
        value: 'lives <= 2',
        box: 'False',
        hint: (l10n) => l10n.game3R3Hint3,
      ),
      GameChip(
        value: 'score == 10',
        box: 'False',
        hint: (l10n) => l10n.game3R3Hint4,
      ),
    ],
  ),
];
