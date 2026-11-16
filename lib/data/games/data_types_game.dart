import '../../models/match_game.dart';

/// Lesson 2 game: "Label the Robot Box", Data Types edition.
///
/// Same reusable game screen and rules as Lesson 1 (variables_game.dart):
/// the boxes are the 4 data types, and the student drops each value chip
/// into its type box. 3 rounds, 4 boxes each, one value per box, a little
/// harder each round. Text lives in the .arb files (keys game2…). Values
/// and type names are code, the same in every language. Chips are shuffled.
const _typeBoxes = [
  GameBox('int'),
  GameBox('float'),
  GameBox('str'),
  GameBox('bool'),
];

final List<GameRound> dataTypesGame = [
  // Round 1: one clear example of each type.
  GameRound(
    intro: (l10n) => l10n.game2R1Intro,
    boxes: _typeBoxes,
    chips: [
      GameChip(value: '7', box: 'int', hint: (l10n) => l10n.game2R1HintInt),
      GameChip(
        value: '2.5',
        box: 'float',
        hint: (l10n) => l10n.game2R1HintFloat,
      ),
      GameChip(value: '"Cog"', box: 'str', hint: (l10n) => l10n.game2R1HintStr),
      GameChip(
        value: 'True',
        box: 'bool',
        hint: (l10n) => l10n.game2R1HintBool,
      ),
    ],
  ),

  // Round 2: tricky ones. "5" in quotes is text; 0.5 is a float.
  GameRound(
    intro: (l10n) => l10n.game2R2Intro,
    boxes: _typeBoxes,
    chips: [
      GameChip(value: '100', box: 'int', hint: (l10n) => l10n.game2R2HintInt),
      GameChip(
        value: '0.5',
        box: 'float',
        hint: (l10n) => l10n.game2R2HintFloat,
      ),
      GameChip(value: '"5"', box: 'str', hint: (l10n) => l10n.game2R2HintStr),
      GameChip(
        value: 'False',
        box: 'bool',
        hint: (l10n) => l10n.game2R2HintBool,
      ),
    ],
  ),

  // Round 3: look-alikes. "True" (text) vs True (bool); 10.0 is a float.
  GameRound(
    intro: (l10n) => l10n.game2R3Intro,
    boxes: _typeBoxes,
    chips: [
      GameChip(value: '42', box: 'int', hint: (l10n) => l10n.game2R3HintInt),
      GameChip(
        value: '10.0',
        box: 'float',
        hint: (l10n) => l10n.game2R3HintFloat,
      ),
      GameChip(
        value: '"True"',
        box: 'str',
        hint: (l10n) => l10n.game2R3HintStr,
      ),
      GameChip(
        value: 'True',
        box: 'bool',
        hint: (l10n) => l10n.game2R3HintBool,
      ),
    ],
  ),
];
