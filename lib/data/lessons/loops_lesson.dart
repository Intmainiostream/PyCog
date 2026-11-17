import '../../models/lesson_card.dart';

/// Lesson 4: Loops. Explanation cards (the quiz is in
/// lib/data/quizzes/loops_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson4Card… for
/// cards, lesson4Note… for the "← arrow notes"). Code and `output` (what the
/// code prints) are the same in every language. Built exactly like Lesson 3
/// (if_statements_lesson.dart). Indents are 4 spaces per level.
final List<LessonCard> loopsLessonCards = [
  // 1. What is a loop? Real life first, then why: copying lines is a pain.
  LessonCard(
    title: (l10n) => l10n.lesson4Card1Title,
    speech: (l10n) => l10n.lesson4Card1Speech,
    code: [
      CodeLine('print("Step")', note: (l10n) => l10n.lesson4NoteCopy1),
      CodeLine('print("Step")', note: (l10n) => l10n.lesson4NoteCopy2),
      CodeLine('print("Step")', note: (l10n) => l10n.lesson4NoteCopy3),
    ],
    tip: (l10n) => l10n.lesson4Card1Tip,
  ),

  // 2. for loop with range: same output, two lines.
  LessonCard(
    title: (l10n) => l10n.lesson4Card2Title,
    speech: (l10n) => l10n.lesson4Card2Speech,
    code: [
      CodeLine('for step in range(3):', note: (l10n) => l10n.lesson4NoteFor3),
      CodeLine('    print("Step")', note: (l10n) => l10n.lesson4NotePrintStep),
    ],
    output: const ['Step', 'Step', 'Step'],
    tip: (l10n) => l10n.lesson4Card2Tip,
  ),

  // 3. The for shape (notes on the colon line and the indented line).
  LessonCard(
    title: (l10n) => l10n.lesson4Card3Title,
    speech: (l10n) => l10n.lesson4Card3Speech,
    code: [
      CodeLine(
        'for step in range(3):',
        note: (l10n) => l10n.lesson4NoteShapeFor,
      ),
      CodeLine(
        '    print("Step")',
        note: (l10n) => l10n.lesson4NoteShapeIndent,
      ),
    ],
    tip: (l10n) => l10n.lesson4Card3Tip,
  ),

  // 4. Big warning: range starts at 0 and stops BEFORE the end.
  LessonCard(
    title: (l10n) => l10n.lesson4Card4Title,
    speech: (l10n) => l10n.lesson4Card4Speech,
    code: [
      CodeLine('range(3)', note: (l10n) => l10n.lesson4NoteRange3),
      CodeLine('range(1, 4)', note: (l10n) => l10n.lesson4NoteRange14),
    ],
    tip: (l10n) => l10n.lesson4Card4Tip,
  ),

  // 5. Using the counter.
  LessonCard(
    title: (l10n) => l10n.lesson4Card5Title,
    speech: (l10n) => l10n.lesson4Card5Speech,
    code: [
      CodeLine(
        'for number in range(1, 4):',
        note: (l10n) => l10n.lesson4NoteFor14,
      ),
      CodeLine(
        '    print(number)',
        note: (l10n) => l10n.lesson4NotePrintNumber,
      ),
    ],
    output: const ['1', '2', '3'],
    tip: (l10n) => l10n.lesson4Card5Tip,
  ),

  // 6. while loop: like an if that repeats (connects to Lesson 3).
  LessonCard(
    title: (l10n) => l10n.lesson4Card6Title,
    speech: (l10n) => l10n.lesson4Card6Speech,
    code: [
      CodeLine('battery = 3', note: (l10n) => l10n.lesson4NoteBattery3),
      CodeLine('while battery > 0:', note: (l10n) => l10n.lesson4NoteWhileAsk),
      CodeLine(
        '    print(battery)',
        note: (l10n) => l10n.lesson4NotePrintBattery,
      ),
      CodeLine(
        '    battery = battery - 1',
        note: (l10n) => l10n.lesson4NoteMinus1,
      ),
    ],
    output: const ['3', '2', '1'],
    tip: (l10n) => l10n.lesson4Card6Tip,
  ),

  // 7. Infinite loop warning: wrong (✗, nothing changes) vs fixed (✓).
  LessonCard(
    title: (l10n) => l10n.lesson4Card7Title,
    speech: (l10n) => l10n.lesson4Card7Speech,
    code: [
      CodeLine(
        'battery = 3',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson4NoteBadStart,
      ),
      CodeLine(
        'while battery > 0:',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson4NoteBadAsk,
      ),
      CodeLine(
        '    print("Moving")',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson4NoteBadForever,
      ),
      CodeLine(
        'battery = 3',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson4NoteBadStart,
      ),
      CodeLine(
        'while battery > 0:',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson4NoteBadAsk,
      ),
      CodeLine(
        '    print("Moving")',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson4NoteGoodPrint,
      ),
      CodeLine(
        '    battery = battery - 1',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson4NoteGoodMinus,
      ),
    ],
    tip: (l10n) => l10n.lesson4Card7Tip,
  ),

  // 8. break: stop early when an enemy is found (uses if from Lesson 3).
  LessonCard(
    title: (l10n) => l10n.lesson4Card8Title,
    speech: (l10n) => l10n.lesson4Card8Speech,
    code: [
      CodeLine(
        'for room in range(1, 6):',
        note: (l10n) => l10n.lesson4NoteRooms,
      ),
      CodeLine('    if room == 3:', note: (l10n) => l10n.lesson4NoteIsEnemy),
      CodeLine(
        '        print("Enemy found!")',
        note: (l10n) => l10n.lesson4NoteEnemyFound,
      ),
      CodeLine('        break', note: (l10n) => l10n.lesson4NoteBreak),
      CodeLine(
        '    print("Room clear")',
        note: (l10n) => l10n.lesson4NoteRoomClear,
      ),
    ],
    output: const ['Room clear', 'Room clear', 'Enemy found!'],
    tip: (l10n) => l10n.lesson4Card8Tip,
  ),

  // 9. Recap: for vs while side by side, and when to use each.
  LessonCard(
    title: (l10n) => l10n.lesson4Card9Title,
    speech: (l10n) => l10n.lesson4Card9Speech,
    code: [
      CodeLine(
        'for step in range(3):',
        note: (l10n) => l10n.lesson4NoteRecapFor,
      ),
      CodeLine(
        '    print("Step")',
        note: (l10n) => l10n.lesson4NoteRecapForBody,
      ),
      CodeLine('battery = 3', note: (l10n) => l10n.lesson4NoteRecapStart),
      CodeLine(
        'while battery > 0:',
        note: (l10n) => l10n.lesson4NoteRecapWhile,
      ),
      CodeLine(
        '    battery = battery - 1',
        note: (l10n) => l10n.lesson4NoteRecapWhileBody,
      ),
    ],
    tip: (l10n) => l10n.lesson4Card9Tip,
  ),
];
