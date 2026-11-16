import '../../models/lesson_card.dart';

/// Lesson 1: Variables. Explanation cards only (the quiz and game are in
/// their own files).
///
/// The text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson1Card…
/// for cards, lesson1Note… for the "← arrow notes" after code lines).
/// The code below is the same in every language.
///
/// Arrow notes go on lesson cards only, never in quizzes (they'd give the
/// answer away), and never on `#` comment lines (those are already notes).
final List<LessonCard> variablesLessonCards = [
  // 1. What a variable is
  LessonCard(
    title: (l10n) => l10n.lesson1Card1Title,
    speech: (l10n) => l10n.lesson1Card1Speech,
    boxes: const [VariableBoxData('battery', '100')],
    tip: (l10n) => l10n.lesson1Card1Tip,
  ),

  // 2. Notes in code (comments). No arrow notes: comments are notes already.
  LessonCard(
    title: (l10n) => l10n.lesson1Card2Title,
    speech: (l10n) => l10n.lesson1Card2Speech,
    code: const [
      CodeLine('# This is a note'),
      CodeLine('battery = 100  # robot battery'),
    ],
    tip: (l10n) => l10n.lesson1Card2Tip,
  ),

  // 3. Making one
  LessonCard(
    title: (l10n) => l10n.lesson1Card3Title,
    speech: (l10n) => l10n.lesson1Card3Speech,
    code: [
      CodeLine('battery = 100', note: (l10n) => l10n.lesson1NoteBattery100),
    ],
    boxes: const [VariableBoxData('battery', '100')],
    tip: (l10n) => l10n.lesson1Card3Tip,
  ),

  // 4. Different kinds of values
  LessonCard(
    title: (l10n) => l10n.lesson1Card4Title,
    speech: (l10n) => l10n.lesson1Card4Speech,
    code: [
      CodeLine('speed = 5', note: (l10n) => l10n.lesson1NoteSpeed5),
      CodeLine('robot_name = "Cog"', note: (l10n) => l10n.lesson1NoteRobotName),
      CodeLine('is_moving = True', note: (l10n) => l10n.lesson1NoteIsMoving),
    ],
    boxes: const [
      VariableBoxData('speed', '5'),
      VariableBoxData('robot_name', '"Cog"'),
      VariableBoxData('is_moving', 'True'),
    ],
    tip: (l10n) => l10n.lesson1Card4Tip,
  ),

  // 5. Changing it
  LessonCard(
    title: (l10n) => l10n.lesson1Card5Title,
    speech: (l10n) => l10n.lesson1Card5Speech,
    code: [
      CodeLine('battery = 100', note: (l10n) => l10n.lesson1NoteBattery100),
      CodeLine('battery = 80', note: (l10n) => l10n.lesson1NoteBattery80),
    ],
    boxes: const [VariableBoxData('battery', '80', oldValue: '100')],
    tip: (l10n) => l10n.lesson1Card5Tip,
  ),

  // 6. Naming rules
  LessonCard(
    title: (l10n) => l10n.lesson1Card6Title,
    speech: (l10n) => l10n.lesson1Card6Speech,
    code: [
      CodeLine(
        'robot_name = "Cog"',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson1NoteGoodUnderscore,
      ),
      CodeLine(
        'robot name = "Cog"',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson1NoteBadSpace,
      ),
      CodeLine(
        'robot2 = "Bolt"',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson1NoteGoodNumberEnd,
      ),
      CodeLine(
        '2robot = "Bolt"',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson1NoteBadNumberStart,
      ),
      CodeLine('speed = 5', note: (l10n) => l10n.lesson1NoteSpeedSmall),
      CodeLine('Speed = 10', note: (l10n) => l10n.lesson1NoteSpeedBig),
      CodeLine(
        'battery = 100',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson1NoteGoodClear,
      ),
      CodeLine(
        'b = 100',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson1NoteBadUnclear,
      ),
    ],
    tip: (l10n) => l10n.lesson1Card6Tip,
  ),
];
