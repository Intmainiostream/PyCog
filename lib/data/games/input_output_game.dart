import '../../models/lesson_card.dart';
import '../../models/match_game.dart';

/// Lesson 9 game: "Label the Robot Box", Input and Output edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box). Every round starts from the same two input() lines as the lesson,
/// and a `# you typed:` comment in the setup says what the person typed
/// (Ana, then 12). Each box is a line of code, and the student drops what
/// it shows into it. input() always gives text, even for 12.
///
/// Chips are written exactly as the program prints them: text without
/// quotes, numbers as digits. A line that does not work gets the `Error`
/// chip (the real error type is named only in its hint). No two chips in a
/// round look the same. Every box and chip was checked in real Python 3.13
/// with Ana and 12 fed into input(), and test/game9_test.dart checks them
/// again on every test run. Hints never name the right box. Text lives in
/// the .arb files (keys game9…); hint N matches chip N below.
const _typed = [
  CodeLine('name = input("Your name? ")'),
  CodeLine('age = input("Age? ")'),
  CodeLine('# you typed: Ana, 12'),
];

/// The chip for a line that does not work.
const errorChip = 'Error';

final List<GameRound> inputOutputGame = [
  // Round 1: print() with commas (adds a space) and joining with + (adds
  // no space).
  GameRound(
    intro: (l10n) => l10n.game9R1Intro,
    setup: _typed,
    boxes: const [
      GameBox('print("Score:", 10)'),
      GameBox('"Hi, " + name'),
      GameBox('print(name, age)'),
      GameBox('"Age:" + age'),
    ],
    chips: [
      GameChip(
        value: 'Score: 10',
        box: 'print("Score:", 10)',
        hint: (l10n) => l10n.game9R1Hint1,
      ),
      GameChip(
        value: 'Hi, Ana',
        box: '"Hi, " + name',
        hint: (l10n) => l10n.game9R1Hint2,
      ),
      GameChip(
        value: 'Ana 12',
        box: 'print(name, age)',
        hint: (l10n) => l10n.game9R1Hint3,
      ),
      GameChip(
        value: 'Age:12',
        box: '"Age:" + age',
        hint: (l10n) => l10n.game9R1Hint4,
      ),
    ],
  ),

  // Round 2: int() turns text into a whole number; float() (mentioned in
  // Lesson 9 card 6) gives a decimal.
  GameRound(
    intro: (l10n) => l10n.game9R2Intro,
    setup: _typed,
    boxes: const [
      GameBox('int("5") + 1'),
      GameBox('int(age) + 1'),
      GameBox('float(age)'),
      GameBox('int(age) * 2'),
    ],
    chips: [
      GameChip(
        value: '6',
        box: 'int("5") + 1',
        hint: (l10n) => l10n.game9R2Hint1,
      ),
      GameChip(
        value: '13',
        box: 'int(age) + 1',
        hint: (l10n) => l10n.game9R2Hint2,
      ),
      GameChip(
        value: '12.0',
        box: 'float(age)',
        hint: (l10n) => l10n.game9R2Hint3,
      ),
      GameChip(
        value: '24',
        box: 'int(age) * 2',
        hint: (l10n) => l10n.game9R2Hint4,
      ),
    ],
  ),

  // Round 3 (the trap): age is still text, so age + 1 is an error
  // (TypeError), age + age joins "12" and "12", and int(age) + 1 fixes it.
  GameRound(
    intro: (l10n) => l10n.game9R3Intro,
    setup: _typed,
    boxes: const [
      GameBox('age + 1'),
      GameBox('age + age'),
      GameBox('int(age) + 1'),
      GameBox('name + age'),
    ],
    chips: [
      GameChip(
        value: errorChip,
        box: 'age + 1',
        hint: (l10n) => l10n.game9R3Hint1,
      ),
      GameChip(
        value: '1212',
        box: 'age + age',
        hint: (l10n) => l10n.game9R3Hint2,
      ),
      GameChip(
        value: '13',
        box: 'int(age) + 1',
        hint: (l10n) => l10n.game9R3Hint3,
      ),
      GameChip(
        value: 'Ana12',
        box: 'name + age',
        hint: (l10n) => l10n.game9R3Hint4,
      ),
    ],
  ),
];
