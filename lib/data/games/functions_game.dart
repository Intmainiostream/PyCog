import '../../models/lesson_card.dart';
import '../../models/match_game.dart';

/// Lesson 5 game: "Label the Robot Box", Functions edition.
///
/// Same reusable game screen and rules as the other games (one chip per
/// box). Each round shows its function definition(s) once at the top (the
/// optional setup line); each box is a call, and the student drops the
/// value that call gives back into it. Every box and chip was checked by
/// running the code in real Python before being written here.
///
/// Chips are written as Python values: `5` is a number, `"Hi, Ana"` is text
/// and `None` means "nothing came back". Text lives in the .arb files (keys
/// game5…); hint N matches chip N below.
final List<GameRound> functionsGame = [
  // Round 1: add(a, b) with small numbers.
  GameRound(
    intro: (l10n) => l10n.game5R1Intro,
    setup: const [CodeLine('def add(a, b):'), CodeLine('    return a + b')],
    boxes: const [
      GameBox('add(2, 3)'),
      GameBox('add(1, 1)'),
      GameBox('add(4, 0)'),
      GameBox('add(5, 5)'),
    ],
    chips: [
      GameChip(value: '5', box: 'add(2, 3)', hint: (l10n) => l10n.game5R1Hint1),
      GameChip(value: '2', box: 'add(1, 1)', hint: (l10n) => l10n.game5R1Hint2),
      GameChip(value: '4', box: 'add(4, 0)', hint: (l10n) => l10n.game5R1Hint3),
      GameChip(
        value: '10',
        box: 'add(5, 5)',
        hint: (l10n) => l10n.game5R1Hint4,
      ),
    ],
  ),

  // Round 2: a function that doubles a number.
  GameRound(
    intro: (l10n) => l10n.game5R2Intro,
    setup: const [CodeLine('def double(n):'), CodeLine('    return n * 2')],
    boxes: const [
      GameBox('double(3)'),
      GameBox('double(5)'),
      GameBox('double(0)'),
      GameBox('double(10)'),
    ],
    chips: [
      GameChip(value: '6', box: 'double(3)', hint: (l10n) => l10n.game5R2Hint1),
      GameChip(
        value: '10',
        box: 'double(5)',
        hint: (l10n) => l10n.game5R2Hint2,
      ),
      GameChip(value: '0', box: 'double(0)', hint: (l10n) => l10n.game5R2Hint3),
      GameChip(
        value: '20',
        box: 'double(10)',
        hint: (l10n) => l10n.game5R2Hint4,
      ),
    ],
  ),

  // Round 3: greet returns text; the tricky shout uses print, so it gives
  // back None (it only shows "Hi, Cog" on the screen).
  GameRound(
    intro: (l10n) => l10n.game5R3Intro,
    setup: const [
      CodeLine('def greet(name):'),
      CodeLine('    return "Hi, " + name'),
      CodeLine('def shout(name):'),
      CodeLine('    print("Hi, " + name)'),
    ],
    boxes: const [
      GameBox('greet("Ana")'),
      GameBox('greet("Ben")'),
      GameBox('shout("Cog")'),
      GameBox('greet("Cog")'),
    ],
    chips: [
      GameChip(
        value: '"Hi, Ana"',
        box: 'greet("Ana")',
        hint: (l10n) => l10n.game5R3Hint1,
      ),
      GameChip(
        value: '"Hi, Ben"',
        box: 'greet("Ben")',
        hint: (l10n) => l10n.game5R3Hint2,
      ),
      GameChip(
        value: 'None',
        box: 'shout("Cog")',
        hint: (l10n) => l10n.game5R3Hint3,
      ),
      GameChip(
        value: '"Hi, Cog"',
        box: 'greet("Cog")',
        hint: (l10n) => l10n.game5R3Hint4,
      ),
    ],
  ),
];
