import '../../models/lesson_card.dart';

/// Lesson 1: Variables. Explanation cards only (no quiz yet).
///
/// The text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson1Card…).
/// The code below is the same in every language.
final List<LessonCard> variablesLessonCards = [
  // 1. What a variable is
  LessonCard(
    title: (l10n) => l10n.lesson1Card1Title,
    speech: (l10n) => l10n.lesson1Card1Speech,
    boxes: const [VariableBoxData('battery', '100')],
    tip: (l10n) => l10n.lesson1Card1Tip,
  ),

  // 2. Making one
  LessonCard(
    title: (l10n) => l10n.lesson1Card2Title,
    speech: (l10n) => l10n.lesson1Card2Speech,
    code: const [CodeLine('battery = 100')],
    boxes: const [VariableBoxData('battery', '100')],
    tip: (l10n) => l10n.lesson1Card2Tip,
  ),

  // 3. Different kinds of values
  LessonCard(
    title: (l10n) => l10n.lesson1Card3Title,
    speech: (l10n) => l10n.lesson1Card3Speech,
    code: const [
      CodeLine('speed = 5'),
      CodeLine('robot_name = "Cog"'),
      CodeLine('is_moving = True'),
    ],
    boxes: const [
      VariableBoxData('speed', '5'),
      VariableBoxData('robot_name', '"Cog"'),
      VariableBoxData('is_moving', 'True'),
    ],
    tip: (l10n) => l10n.lesson1Card3Tip,
  ),

  // 4. Changing it
  LessonCard(
    title: (l10n) => l10n.lesson1Card4Title,
    speech: (l10n) => l10n.lesson1Card4Speech,
    code: const [CodeLine('battery = 100'), CodeLine('battery = 80')],
    boxes: const [VariableBoxData('battery', '80', oldValue: '100')],
    tip: (l10n) => l10n.lesson1Card4Tip,
  ),

  // 5. Naming rules
  LessonCard(
    title: (l10n) => l10n.lesson1Card5Title,
    speech: (l10n) => l10n.lesson1Card5Speech,
    code: const [
      CodeLine('robot_name = "Cog"', mark: CodeMark.good),
      CodeLine('robot name = "Cog"', mark: CodeMark.bad),
      CodeLine('robot2 = "Bolt"', mark: CodeMark.good),
      CodeLine('2robot = "Bolt"', mark: CodeMark.bad),
      CodeLine('speed = 5'),
      CodeLine('Speed = 10'),
      CodeLine('battery = 100', mark: CodeMark.good),
      CodeLine('b = 100', mark: CodeMark.bad),
    ],
    tip: (l10n) => l10n.lesson1Card5Tip,
  ),
];
