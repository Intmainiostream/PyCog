import '../../models/lesson_card.dart';

/// Lesson 3: If Statements. Explanation cards (the quiz is in
/// lib/data/quizzes/if_statements_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson3Card… for
/// cards, lesson3Note… for the "← arrow notes"). Code is the same in every
/// language. Built exactly like Lesson 2 (data_types_lesson.dart).
///
/// Indented lines start with 4 spaces, exactly as students should type them.
final List<LessonCard> ifStatementsLessonCards = [
  // 1. What is an if statement? (real-life choice first, then code)
  LessonCard(
    title: (l10n) => l10n.lesson3Card1Title,
    speech: (l10n) => l10n.lesson3Card1Speech,
    code: [
      CodeLine('if battery < 20:', note: (l10n) => l10n.lesson3NoteAskBattery),
      CodeLine(
        '    print("Low battery!")',
        note: (l10n) => l10n.lesson3NoteRunsIfTrue,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card1Tip,
  ),

  // 2. The shape: if + question + colon, then an indented line.
  LessonCard(
    title: (l10n) => l10n.lesson3Card2Title,
    speech: (l10n) => l10n.lesson3Card2Speech,
    code: [
      CodeLine('if lives > 0:', note: (l10n) => l10n.lesson3NoteShapeIf),
      CodeLine(
        '    print("Keep playing!")',
        note: (l10n) => l10n.lesson3NoteShapeIndent,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card2Tip,
  ),

  // 3. Comparing values: each sign with a small example and its result.
  LessonCard(
    title: (l10n) => l10n.lesson3Card3Title,
    speech: (l10n) => l10n.lesson3Card3Speech,
    code: [
      CodeLine('3 == 3', note: (l10n) => l10n.lesson3NoteEq),
      CodeLine('3 != 5', note: (l10n) => l10n.lesson3NoteNotEq),
      CodeLine('10 > 5', note: (l10n) => l10n.lesson3NoteGreater),
      CodeLine('2 < 1', note: (l10n) => l10n.lesson3NoteLess),
      CodeLine('5 >= 5', note: (l10n) => l10n.lesson3NoteGreaterEq),
      CodeLine('4 <= 3', note: (l10n) => l10n.lesson3NoteLessEq),
    ],
    tip: (l10n) => l10n.lesson3Card3Tip,
  ),

  // 4. Big warning: = puts a value in, == asks a question.
  LessonCard(
    title: (l10n) => l10n.lesson3Card4Title,
    speech: (l10n) => l10n.lesson3Card4Speech,
    code: [
      CodeLine('lives = 3', note: (l10n) => l10n.lesson3NoteAssign),
      CodeLine('lives == 3', note: (l10n) => l10n.lesson3NoteCompare),
    ],
    boxes: const [VariableBoxData('lives', '3')],
    tip: (l10n) => l10n.lesson3Card4Tip,
  ),

  // 5. else: what to do when it is False.
  LessonCard(
    title: (l10n) => l10n.lesson3Card5Title,
    speech: (l10n) => l10n.lesson3Card5Speech,
    code: [
      CodeLine('battery = 50', note: (l10n) => l10n.lesson3NoteBattery50),
      CodeLine('if battery < 20:', note: (l10n) => l10n.lesson3NoteCheck50),
      CodeLine(
        '    print("Low battery!")',
        note: (l10n) => l10n.lesson3NoteSkipped,
      ),
      CodeLine('else:', note: (l10n) => l10n.lesson3NoteElseRuns),
      CodeLine(
        '    print("Battery OK!")',
        note: (l10n) => l10n.lesson3NoteThisRuns,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card5Tip,
  ),

  // 6. elif: more than two choices (gold, silver, or try again).
  LessonCard(
    title: (l10n) => l10n.lesson3Card6Title,
    speech: (l10n) => l10n.lesson3Card6Speech,
    code: [
      CodeLine('score = 75', note: (l10n) => l10n.lesson3NoteScore75),
      CodeLine('if score >= 90:', note: (l10n) => l10n.lesson3NoteGoldCheck),
      CodeLine('    print("Gold!")', note: (l10n) => l10n.lesson3NoteSkipped),
      CodeLine(
        'elif score >= 70:',
        note: (l10n) => l10n.lesson3NoteSilverCheck,
      ),
      CodeLine(
        '    print("Silver!")',
        note: (l10n) => l10n.lesson3NoteThisRuns,
      ),
      CodeLine('else:', note: (l10n) => l10n.lesson3NoteElseSkipped),
      CodeLine(
        '    print("Try again!")',
        note: (l10n) => l10n.lesson3NoteSkipped,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card6Tip,
  ),

  // 7. Indent matters: wrong (no indent, red ✗) vs correct (green ✓).
  LessonCard(
    title: (l10n) => l10n.lesson3Card7Title,
    speech: (l10n) => l10n.lesson3Card7Speech,
    code: [
      CodeLine(
        'if lives > 0:',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson3NoteQuestion,
      ),
      CodeLine(
        'print("Keep playing!")',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson3NoteNoIndent,
      ),
      CodeLine(
        'if lives > 0:',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson3NoteQuestion,
      ),
      CodeLine(
        '    print("Keep playing!")',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson3NoteWithIndent,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card7Tip,
  ),

  // 8. Recap: the whole shape on one screen.
  LessonCard(
    title: (l10n) => l10n.lesson3Card8Title,
    speech: (l10n) => l10n.lesson3Card8Speech,
    code: [
      CodeLine('if battery < 20:', note: (l10n) => l10n.lesson3NoteRecapIf),
      CodeLine(
        '    print("Low battery!")',
        note: (l10n) => l10n.lesson3NoteRecapIfBody,
      ),
      CodeLine('elif battery < 50:', note: (l10n) => l10n.lesson3NoteRecapElif),
      CodeLine(
        '    print("Battery OK")',
        note: (l10n) => l10n.lesson3NoteRecapElifBody,
      ),
      CodeLine('else:', note: (l10n) => l10n.lesson3NoteRecapElse),
      CodeLine(
        '    print("Full power!")',
        note: (l10n) => l10n.lesson3NoteRecapElseBody,
      ),
    ],
    tip: (l10n) => l10n.lesson3Card8Tip,
  ),
];
