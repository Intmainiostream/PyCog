import '../../models/lesson_card.dart';

/// Lesson 5: Functions. Explanation cards (the quiz is in
/// lib/data/quizzes/functions_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson5Card… for
/// cards, lesson5Note… for the "← arrow notes"). Code and `output` (what the
/// code prints) are the same in every language. Built exactly like Lesson 4
/// (loops_lesson.dart). Every `output` was checked by running the card's
/// code in real Python. Indents are 4 spaces per level.
final List<LessonCard> functionsLessonCards = [
  // 1. What is a function? Real life first; without one we copy and paste.
  LessonCard(
    title: (l10n) => l10n.lesson5Card1Title,
    speech: (l10n) => l10n.lesson5Card1Speech,
    code: [
      CodeLine('print("Hi, I am Cog!")', note: (l10n) => l10n.lesson5NoteWave),
      CodeLine(
        'print("Hi, I am Cog!")',
        note: (l10n) => l10n.lesson5NoteCopied,
      ),
      CodeLine(
        'print("Hi, I am Cog!")',
        note: (l10n) => l10n.lesson5NoteCopiedMore,
      ),
    ],
    output: const ['Hi, I am Cog!', 'Hi, I am Cog!', 'Hi, I am Cog!'],
    tip: (l10n) => l10n.lesson5Card1Tip,
  ),

  // 2. Making a function. This only makes it: nothing prints (no output).
  LessonCard(
    title: (l10n) => l10n.lesson5Card2Title,
    speech: (l10n) => l10n.lesson5Card2Speech,
    code: [
      CodeLine('def say_hello():', note: (l10n) => l10n.lesson5NoteMakeHello),
      CodeLine(
        '    print("Hi, I am Cog!")',
        note: (l10n) => l10n.lesson5NoteNotYet,
      ),
    ],
    tip: (l10n) => l10n.lesson5Card2Tip,
  ),

  // 3. Calling a function, 3 times.
  LessonCard(
    title: (l10n) => l10n.lesson5Card3Title,
    speech: (l10n) => l10n.lesson5Card3Speech,
    code: [
      CodeLine('def say_hello():', note: (l10n) => l10n.lesson5NoteMake),
      CodeLine(
        '    print("Hi, I am Cog!")',
        note: (l10n) => l10n.lesson5NoteInside,
      ),
      CodeLine('say_hello()', note: (l10n) => l10n.lesson5NoteCall1),
      CodeLine('say_hello()', note: (l10n) => l10n.lesson5NoteCall2),
      CodeLine('say_hello()', note: (l10n) => l10n.lesson5NoteCall3),
    ],
    output: const ['Hi, I am Cog!', 'Hi, I am Cog!', 'Hi, I am Cog!'],
    tip: (l10n) => l10n.lesson5Card3Tip,
  ),

  // 4. The def shape (notes on the colon line and the indented body).
  LessonCard(
    title: (l10n) => l10n.lesson5Card4Title,
    speech: (l10n) => l10n.lesson5Card4Speech,
    code: [
      CodeLine('def say_hello():', note: (l10n) => l10n.lesson5NoteShapeDef),
      CodeLine(
        '    print("Hi, I am Cog!")',
        note: (l10n) => l10n.lesson5NoteShapeIndent,
      ),
    ],
    tip: (l10n) => l10n.lesson5Card4Tip,
  ),

  // 5. Parameters: a box the function fills when you call it (Lesson 1).
  LessonCard(
    title: (l10n) => l10n.lesson5Card5Title,
    speech: (l10n) => l10n.lesson5Card5Speech,
    code: [
      CodeLine('def greet(name):', note: (l10n) => l10n.lesson5NoteGreetDef),
      CodeLine(
        '    print("Hi,", name)',
        note: (l10n) => l10n.lesson5NoteGreetBody,
      ),
      CodeLine('greet("Ana")', note: (l10n) => l10n.lesson5NoteCallAna),
      CodeLine('greet("Ben")', note: (l10n) => l10n.lesson5NoteCallBen),
    ],
    output: const ['Hi, Ana', 'Hi, Ben'],
    tip: (l10n) => l10n.lesson5Card5Tip,
  ),

  // 6. return: give a value back.
  LessonCard(
    title: (l10n) => l10n.lesson5Card6Title,
    speech: (l10n) => l10n.lesson5Card6Speech,
    code: [
      CodeLine('def add(a, b):', note: (l10n) => l10n.lesson5NoteAddDef),
      CodeLine('    return a + b', note: (l10n) => l10n.lesson5NoteReturn),
      CodeLine('result = add(2, 3)', note: (l10n) => l10n.lesson5NoteResult5),
      CodeLine('print(result)', note: (l10n) => l10n.lesson5NoteShows5),
    ],
    output: const ['5'],
    tip: (l10n) => l10n.lesson5Card6Tip,
  ),

  // 7. print vs return: wrong (✗, print gives nothing back) vs fixed (✓).
  LessonCard(
    title: (l10n) => l10n.lesson5Card7Title,
    speech: (l10n) => l10n.lesson5Card7Speech,
    code: [
      CodeLine(
        'def add(a, b):',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson5NoteMakeAdd,
      ),
      CodeLine(
        '    print(a + b)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson5NoteOnlyShows,
      ),
      CodeLine(
        'result = add(2, 3)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson5NoteGetsNone,
      ),
      CodeLine(
        'print(result)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson5NoteShowsNone,
      ),
      CodeLine(
        'def add(a, b):',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson5NoteMakeAdd,
      ),
      CodeLine(
        '    return a + b',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson5NoteGivesBack,
      ),
      CodeLine(
        'result = add(2, 3)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson5NoteResult5,
      ),
      CodeLine(
        'print(result)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson5NoteShows5,
      ),
    ],
    // From top to bottom: the ✗ print shows 5, then the ✗ result is None,
    // then the ✓ version shows 5.
    output: const ['5', 'None', '5'],
    tip: (l10n) => l10n.lesson5Card7Tip,
  ),

  // 8. Using what we learned: an if inside a function (Lesson 3).
  LessonCard(
    title: (l10n) => l10n.lesson5Card8Title,
    speech: (l10n) => l10n.lesson5Card8Speech,
    code: [
      CodeLine(
        'def check_battery(level):',
        note: (l10n) => l10n.lesson5NoteLevelParam,
      ),
      CodeLine('    if level < 20:', note: (l10n) => l10n.lesson5NoteCheckLow),
      CodeLine(
        '        return "Low"',
        note: (l10n) => l10n.lesson5NoteReturnLow,
      ),
      CodeLine('    else:', note: (l10n) => l10n.lesson5NoteElse),
      CodeLine('        return "OK"', note: (l10n) => l10n.lesson5NoteReturnOk),
      CodeLine(
        'print(check_battery(10))',
        note: (l10n) => l10n.lesson5NoteCall10,
      ),
      CodeLine(
        'print(check_battery(80))',
        note: (l10n) => l10n.lesson5NoteCall80,
      ),
    ],
    output: const ['Low', 'OK'],
    tip: (l10n) => l10n.lesson5Card8Tip,
  ),

  // 9. Recap: def, parameter, return and a call, on one screen.
  LessonCard(
    title: (l10n) => l10n.lesson5Card9Title,
    speech: (l10n) => l10n.lesson5Card9Speech,
    code: [
      CodeLine('def add(a, b):', note: (l10n) => l10n.lesson5NoteRecapDef),
      CodeLine('    return a + b', note: (l10n) => l10n.lesson5NoteRecapReturn),
      CodeLine('total = add(4, 1)', note: (l10n) => l10n.lesson5NoteRecapCall),
      CodeLine('print(total)', note: (l10n) => l10n.lesson5NoteShows5),
    ],
    output: const ['5'],
    tip: (l10n) => l10n.lesson5Card9Tip,
  ),
];
