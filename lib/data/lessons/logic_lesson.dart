import '../../models/lesson_card.dart';

/// Lesson 10: Logic (and, or, not). Explanation cards (the quiz is in
/// lib/data/quizzes/logic_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson10Card…
/// for cards, lesson10Note… for the "← arrow notes"). Code, `output` and
/// the True/False tables are the same in every language. Built exactly like
/// Lesson 9 (input_output_lesson.dart). Every `output` and every table row
/// was checked by running it in real Python 3.13.

/// Every combination of two True/False values, top row first.
const _pairs = [
  [true, true],
  [true, false],
  [false, true],
  [false, false],
];

final List<LessonCard> logicLessonCards = [
  // 1. Combining questions: homework AND Saturday (Lesson 3's if).
  LessonCard(
    title: (l10n) => l10n.lesson10Card1Title,
    speech: (l10n) => l10n.lesson10Card1Speech,
    code: [
      CodeLine('homework = True', note: (l10n) => l10n.lesson10NoteHomework),
      CodeLine('saturday = True', note: (l10n) => l10n.lesson10NoteSaturday),
      CodeLine(
        'if homework and saturday:',
        note: (l10n) => l10n.lesson10NoteBothAsk,
      ),
      CodeLine(
        '    print("You can play!")',
        note: (l10n) => l10n.lesson10NotePlay,
      ),
    ],
    output: const ['You can play!'],
    tip: (l10n) => l10n.lesson10Card1Tip,
  ),

  // 2. and: both must be True. Table, then battery and lives.
  LessonCard(
    title: (l10n) => l10n.lesson10Card2Title,
    speech: (l10n) => l10n.lesson10Card2Speech,
    table: TruthTableData(
      headings: const ['a', 'b', 'a and b'],
      rows: [
        for (final [a, b] in _pairs) [a, b, a && b],
      ],
    ),
    code: [
      CodeLine('battery = 50', note: (l10n) => l10n.lesson10NoteBattery50),
      CodeLine('lives = 0', note: (l10n) => l10n.lesson10NoteLives0),
      CodeLine('power = battery > 20', note: (l10n) => l10n.lesson10NotePower),
      CodeLine('alive = lives > 0', note: (l10n) => l10n.lesson10NoteAlive),
      CodeLine(
        'print(power and alive)',
        note: (l10n) => l10n.lesson10NotePowerAndAlive,
      ),
    ],
    output: const ['False'],
    tip: (l10n) => l10n.lesson10Card2Tip,
  ),

  // 3. or: at least one True. Table, then a key or a secret code.
  LessonCard(
    title: (l10n) => l10n.lesson10Card3Title,
    speech: (l10n) => l10n.lesson10Card3Speech,
    table: TruthTableData(
      headings: const ['a', 'b', 'a or b'],
      rows: [
        for (final [a, b] in _pairs) [a, b, a || b],
      ],
    ),
    code: [
      CodeLine('has_key = False', note: (l10n) => l10n.lesson10NoteNoKey),
      CodeLine('has_code = True', note: (l10n) => l10n.lesson10NoteHasCode),
      CodeLine(
        'print(has_key or has_code)',
        note: (l10n) => l10n.lesson10NoteKeyOrCode,
      ),
    ],
    output: const ['True'],
    tip: (l10n) => l10n.lesson10Card3Tip,
  ),

  // 4. not: flips it. Table, then not game_over.
  LessonCard(
    title: (l10n) => l10n.lesson10Card4Title,
    speech: (l10n) => l10n.lesson10Card4Speech,
    table: const TruthTableData(
      headings: ['a', 'not a'],
      rows: [
        [true, false],
        [false, true],
      ],
    ),
    code: [
      CodeLine('game_over = False', note: (l10n) => l10n.lesson10NoteGameOn),
      CodeLine(
        'print(not game_over)',
        note: (l10n) => l10n.lesson10NoteNotOver,
      ),
      CodeLine('if not game_over:', note: (l10n) => l10n.lesson10NoteIfNot),
      CodeLine(
        '    print("Keep playing!")',
        note: (l10n) => l10n.lesson10NoteKeepPlaying,
      ),
    ],
    output: const ['True', 'Keep playing!'],
    tip: (l10n) => l10n.lesson10Card4Tip,
  ),

  // 5. and inside if / else (Lesson 3): a door needs a key and battery.
  LessonCard(
    title: (l10n) => l10n.lesson10Card5Title,
    speech: (l10n) => l10n.lesson10Card5Speech,
    code: [
      CodeLine('has_key = True', note: (l10n) => l10n.lesson10NoteHasKeyTrue),
      CodeLine('battery = 0', note: (l10n) => l10n.lesson10NoteBattery0),
      CodeLine(
        'if has_key and battery > 0:',
        note: (l10n) => l10n.lesson10NoteDoorAsk,
      ),
      CodeLine(
        '    print("Door opens!")',
        note: (l10n) => l10n.lesson10NoteDoorOpens,
      ),
      CodeLine('else:', note: (l10n) => l10n.lesson10NoteElse),
      CodeLine(
        '    print("Still locked")',
        note: (l10n) => l10n.lesson10NoteStillLocked,
      ),
    ],
    output: const ['Still locked'],
    tip: (l10n) => l10n.lesson10Card5Tip,
  ),

  // 6. Big warning: same values, and (✓ right) vs or (✗ a bug).
  LessonCard(
    title: (l10n) => l10n.lesson10Card6Title,
    speech: (l10n) => l10n.lesson10Card6Speech,
    code: [
      CodeLine('lives = 3', note: (l10n) => l10n.lesson10NoteLives3),
      CodeLine('battery = 0', note: (l10n) => l10n.lesson10NoteBatteryEmpty),
      CodeLine('alive = lives > 0', note: (l10n) => l10n.lesson10NoteAliveTrue),
      CodeLine(
        'charged = battery > 0',
        note: (l10n) => l10n.lesson10NoteChargedFalse,
      ),
      CodeLine(
        'print(alive and charged)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson10NoteAndRight,
      ),
      CodeLine(
        'print(alive or charged)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson10NoteOrWrong,
      ),
    ],
    output: const ['False', 'True'],
    tip: (l10n) => l10n.lesson10Card6Tip,
  ),

  // 7. Order: not, and, then or. Brackets change the result (Lesson 6).
  // a, b, c hold True, False, False: `print(True or False and False)` is
  // too wide for a phone. Same values, same results.
  LessonCard(
    title: (l10n) => l10n.lesson10Card7Title,
    speech: (l10n) => l10n.lesson10Card7Speech,
    code: [
      CodeLine('a = True', note: (l10n) => l10n.lesson10NoteA),
      CodeLine('b = False', note: (l10n) => l10n.lesson10NoteB),
      CodeLine('c = False', note: (l10n) => l10n.lesson10NoteC),
      CodeLine(
        'print(a or b and c)',
        note: (l10n) => l10n.lesson10NoteNoBrackets,
      ),
      CodeLine(
        'print((a or b) and c)',
        note: (l10n) => l10n.lesson10NoteBrackets,
      ),
    ],
    output: const ['True', 'False'],
    tip: (l10n) => l10n.lesson10Card7Tip,
  ),

  // 8. 1 <= level <= 3 means level >= 1 and level <= 3 (Lesson 3).
  LessonCard(
    title: (l10n) => l10n.lesson10Card8Title,
    speech: (l10n) => l10n.lesson10Card8Speech,
    code: [
      CodeLine('level = 2', note: (l10n) => l10n.lesson10NoteLevel2),
      CodeLine('low = level >= 1', note: (l10n) => l10n.lesson10NoteLow),
      CodeLine('high = level <= 3', note: (l10n) => l10n.lesson10NoteHigh),
      CodeLine(
        'print(low and high)',
        note: (l10n) => l10n.lesson10NoteLowAndHigh,
      ),
      CodeLine(
        'print(1 <= level <= 3)',
        note: (l10n) => l10n.lesson10NoteChain,
      ),
    ],
    output: const ['True', 'True'],
    tip: (l10n) => l10n.lesson10Card8Tip,
  ),

  // 9. Recap: and, or, not, and a chained comparison.
  LessonCard(
    title: (l10n) => l10n.lesson10Card9Title,
    speech: (l10n) => l10n.lesson10Card9Speech,
    code: [
      CodeLine(
        'print(True and False)',
        note: (l10n) => l10n.lesson10NoteRecapAnd,
      ),
      CodeLine(
        'print(True or False)',
        note: (l10n) => l10n.lesson10NoteRecapOr,
      ),
      CodeLine('print(not True)', note: (l10n) => l10n.lesson10NoteRecapNot),
      CodeLine(
        'print(1 <= 2 <= 3)',
        note: (l10n) => l10n.lesson10NoteRecapChain,
      ),
    ],
    output: const ['False', 'True', 'False', 'True'],
    tip: (l10n) => l10n.lesson10Card9Tip,
  ),
];
