import 'lesson_card.dart';

/// "Label the Robot Box": drag each value chip into the variable box it
/// belongs in. A lesson's game is a list of [GameRound]s.
///
/// Names and values are code, so they're plain strings (same in every
/// language). Cog's lines are [LocalizedText].

/// One labeled box (a variable) in a round.
class GameBox {
  const GameBox(this.name, {this.startValue});

  /// The variable name on the label, e.g. `battery`.
  final String name;

  /// If set, the box already holds this value when the round starts
  /// (the "changing it" twist). Dropping the right chip replaces it.
  final String? startValue;
}

/// One draggable value chip.
class GameChip {
  const GameChip({required this.value, required this.box, required this.hint});

  /// The value as code, e.g. `80` or `"Cog"`. Unique within a round.
  final String value;

  /// The name of the box this chip belongs in.
  final String box;

  /// Cog's one-sentence hint when this chip is dropped on the wrong box.
  final LocalizedText hint;
}

/// One round: Cog's intro (which gives the story clues) plus boxes and chips.
class GameRound {
  const GameRound({
    required this.intro,
    required this.boxes,
    required this.chips,
    this.setup = const [],
  });

  final LocalizedText intro;
  final List<GameBox> boxes;

  /// Usually one chip per box. A box may have several chips (e.g. a True
  /// box with two conditions); it accepts drops until all of its chips are in.
  final List<GameChip> chips;

  /// Optional code shown above the boxes (e.g. `battery = 10`), for rounds
  /// whose chips depend on some values. Empty = nothing shown.
  final List<CodeLine> setup;
}
