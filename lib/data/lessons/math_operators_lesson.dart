import '../../models/lesson_card.dart';

/// Lesson 6: Math Operators. Explanation cards (the quiz is in
/// lib/data/quizzes/math_operators_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson6Card… for
/// cards, lesson6Note… for the "← arrow notes"). Code and `output` (what the
/// code prints) are the same in every language. Built exactly like Lesson 5
/// (functions_lesson.dart). Every `output` was checked by running the card's
/// code in real Python. Indents are 4 spaces per level.
final List<LessonCard> mathOperatorsLessonCards = [
  // 1. Python is a calculator. Real life first (adding up coins).
  LessonCard(
    title: (l10n) => l10n.lesson6Card1Title,
    speech: (l10n) => l10n.lesson6Card1Speech,
    code: [CodeLine('print(2 + 3)', note: (l10n) => l10n.lesson6NoteAdd23)],
    output: const ['5'],
    tip: (l10n) => l10n.lesson6Card1Tip,
  ),

  // 2. + and -, with score and lives.
  LessonCard(
    title: (l10n) => l10n.lesson6Card2Title,
    speech: (l10n) => l10n.lesson6Card2Speech,
    code: [
      CodeLine('score = 10 + 5', note: (l10n) => l10n.lesson6NoteScore15),
      CodeLine('lives = 3 - 1', note: (l10n) => l10n.lesson6NoteLives2),
      CodeLine('print(score)', note: (l10n) => l10n.lesson6NoteShows15),
      CodeLine('print(lives)', note: (l10n) => l10n.lesson6NoteShows2),
    ],
    output: const ['15', '2'],
    tip: (l10n) => l10n.lesson6Card2Tip,
  ),

  // 3. Big warning: * and /, and / always gives a float (Lesson 2).
  LessonCard(
    title: (l10n) => l10n.lesson6Card3Title,
    speech: (l10n) => l10n.lesson6Card3Speech,
    code: [
      CodeLine('print(4 * 3)', note: (l10n) => l10n.lesson6NoteTimes),
      CodeLine('print(10 / 2)', note: (l10n) => l10n.lesson6NoteDivide),
      CodeLine('print(type(10 / 2))', note: (l10n) => l10n.lesson6NoteFloat),
    ],
    output: const ['12', '5.0', "<class 'float'>"],
    tip: (l10n) => l10n.lesson6Card3Tip,
  ),

  // 4. // and %: 7 robots in teams of 2.
  LessonCard(
    title: (l10n) => l10n.lesson6Card4Title,
    speech: (l10n) => l10n.lesson6Card4Speech,
    code: [
      CodeLine('robots = 7', note: (l10n) => l10n.lesson6NoteRobots7),
      CodeLine('print(robots // 2)', note: (l10n) => l10n.lesson6NoteTeams),
      CodeLine('print(robots % 2)', note: (l10n) => l10n.lesson6NoteLeftOver),
    ],
    output: const ['3', '1'],
    tip: (l10n) => l10n.lesson6Card4Tip,
  ),

  // 5. Power: ** is not the same as *.
  LessonCard(
    title: (l10n) => l10n.lesson6Card5Title,
    speech: (l10n) => l10n.lesson6Card5Speech,
    code: [
      CodeLine('print(2 ** 3)', note: (l10n) => l10n.lesson6NotePower),
      CodeLine('print(2 * 3)', note: (l10n) => l10n.lesson6NoteJustTimes),
    ],
    output: const ['8', '6'],
    tip: (l10n) => l10n.lesson6Card5Tip,
  ),

  // 6. Order of operations: ✗ without ( ) gives 14 wheels, ✓ with ( ) 20.
  LessonCard(
    title: (l10n) => l10n.lesson6Card6Title,
    speech: (l10n) => l10n.lesson6Card6Speech,
    code: [
      CodeLine(
        'print(2 + 3 * 4)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson6NoteOrderBad,
      ),
      CodeLine(
        'print((2 + 3) * 4)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson6NoteOrderGood,
      ),
    ],
    output: const ['14', '20'],
    tip: (l10n) => l10n.lesson6Card6Tip,
  ),

  // 7. Math with variables: += the short way, and -= in a while loop
  // (connects to Lesson 4's battery loop).
  LessonCard(
    title: (l10n) => l10n.lesson6Card7Title,
    speech: (l10n) => l10n.lesson6Card7Speech,
    code: [
      CodeLine('score = 0', note: (l10n) => l10n.lesson6NoteScore0),
      CodeLine('score = score + 10', note: (l10n) => l10n.lesson6NoteLongWay),
      CodeLine('score += 10', note: (l10n) => l10n.lesson6NoteShortWay),
      CodeLine('print(score)', note: (l10n) => l10n.lesson6NoteShows20),
      CodeLine('battery = 3', note: (l10n) => l10n.lesson6NoteBattery3),
      CodeLine('while battery > 0:', note: (l10n) => l10n.lesson6NoteWhile),
      CodeLine(
        '    print(battery)',
        note: (l10n) => l10n.lesson6NotePrintBattery,
      ),
      CodeLine('    battery -= 1', note: (l10n) => l10n.lesson6NoteMinusShort),
    ],
    output: const ['20', '3', '2', '1'],
    tip: (l10n) => l10n.lesson6Card7Tip,
  ),

  // 8. Recap: every operator with 7 and 2.
  LessonCard(
    title: (l10n) => l10n.lesson6Card8Title,
    speech: (l10n) => l10n.lesson6Card8Speech,
    code: [
      CodeLine('print(7 + 2)', note: (l10n) => l10n.lesson6NoteRecapAdd),
      CodeLine('print(7 - 2)', note: (l10n) => l10n.lesson6NoteRecapSub),
      CodeLine('print(7 * 2)', note: (l10n) => l10n.lesson6NoteRecapTimes),
      CodeLine('print(7 / 2)', note: (l10n) => l10n.lesson6NoteRecapDivide),
      CodeLine('print(7 // 2)', note: (l10n) => l10n.lesson6NoteRecapTeams),
      CodeLine('print(7 % 2)', note: (l10n) => l10n.lesson6NoteRecapLeft),
      CodeLine('print(7 ** 2)', note: (l10n) => l10n.lesson6NoteRecapPower),
    ],
    output: const ['9', '5', '14', '3.5', '3', '1', '49'],
    tip: (l10n) => l10n.lesson6Card8Tip,
  ),
];
