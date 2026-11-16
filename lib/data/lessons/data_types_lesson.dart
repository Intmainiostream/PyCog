import '../../models/lesson_card.dart';

/// Lesson 2: Data Types. Explanation cards (the quiz is in
/// lib/data/quizzes/data_types_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson2Card…
/// for cards, lesson2Note… for the "← arrow notes"). Code is the same in
/// every language. Built exactly like Lesson 1 (variables_lesson.dart).
final List<LessonCard> dataTypesLessonCards = [
  // 1. What is a data type?
  LessonCard(
    title: (l10n) => l10n.lesson2Card1Title,
    speech: (l10n) => l10n.lesson2Card1Speech,
    code: [
      CodeLine('age = 15', note: (l10n) => l10n.lesson2NoteAge),
      CodeLine('name = "Cog"', note: (l10n) => l10n.lesson2NoteName),
    ],
    boxes: const [
      VariableBoxData('age', '15'),
      VariableBoxData('name', '"Cog"'),
    ],
    tip: (l10n) => l10n.lesson2Card1Tip,
  ),

  // 2. int: whole numbers
  LessonCard(
    title: (l10n) => l10n.lesson2Card2Title,
    speech: (l10n) => l10n.lesson2Card2Speech,
    code: [
      CodeLine('lives = 3', note: (l10n) => l10n.lesson2NoteLives3),
      CodeLine('steps = 250', note: (l10n) => l10n.lesson2NoteSteps),
    ],
    tip: (l10n) => l10n.lesson2Card2Tip,
  ),

  // 3. float: numbers with a decimal point
  LessonCard(
    title: (l10n) => l10n.lesson2Card3Title,
    speech: (l10n) => l10n.lesson2Card3Speech,
    code: [
      CodeLine('speed = 2.5', note: (l10n) => l10n.lesson2NoteSpeed),
      CodeLine('price = 10.0', note: (l10n) => l10n.lesson2NotePrice),
    ],
    tip: (l10n) => l10n.lesson2Card3Tip,
  ),

  // 4. str: text in quotes, and "5" (text) vs 5 (number)
  LessonCard(
    title: (l10n) => l10n.lesson2Card4Title,
    speech: (l10n) => l10n.lesson2Card4Speech,
    code: [
      CodeLine('robot = "Cog"', note: (l10n) => l10n.lesson2NoteRobot),
      CodeLine('room = "5"', note: (l10n) => l10n.lesson2NoteRoom),
      CodeLine('lives = 5', note: (l10n) => l10n.lesson2NoteLives5),
    ],
    tip: (l10n) => l10n.lesson2Card4Tip,
  ),

  // 5. bool: only True or False (capital T and F)
  LessonCard(
    title: (l10n) => l10n.lesson2Card5Title,
    speech: (l10n) => l10n.lesson2Card5Speech,
    code: [
      CodeLine(
        'is_online = True',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson2NoteOnline,
      ),
      CodeLine(
        'is_flying = False',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson2NoteFlying,
      ),
      CodeLine(
        'is_online = true',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson2NoteSmallT,
      ),
    ],
    tip: (l10n) => l10n.lesson2Card5Tip,
  ),

  // 6. type(): ask Python what the type is
  LessonCard(
    title: (l10n) => l10n.lesson2Card6Title,
    speech: (l10n) => l10n.lesson2Card6Speech,
    code: [
      CodeLine('speed = 2.5', note: (l10n) => l10n.lesson2NoteSpeedIs),
      CodeLine('print(type(speed))', note: (l10n) => l10n.lesson2NotePrintType),
    ],
    tip: (l10n) => l10n.lesson2Card6Tip,
  ),

  // 7. Recap: all 4 types side by side
  LessonCard(
    title: (l10n) => l10n.lesson2Card7Title,
    speech: (l10n) => l10n.lesson2Card7Speech,
    boxes: const [
      VariableBoxData('lives', '3'),
      VariableBoxData('speed', '2.5'),
      VariableBoxData('robot', '"Cog"'),
      VariableBoxData('is_online', 'True'),
    ],
    code: [
      CodeLine('lives = 3', note: (l10n) => l10n.lesson2NoteRecapInt),
      CodeLine('speed = 2.5', note: (l10n) => l10n.lesson2NoteRecapFloat),
      CodeLine('robot = "Cog"', note: (l10n) => l10n.lesson2NoteRecapStr),
      CodeLine('is_online = True', note: (l10n) => l10n.lesson2NoteRecapBool),
    ],
    tip: (l10n) => l10n.lesson2Card7Tip,
  ),
];
