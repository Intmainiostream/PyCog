import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 1 quiz: Variables.
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz1…).
/// Answers that are pure code (like `80`) are written here, since code is the
/// same in every language. Answer order here doesn't matter: the quiz screen
/// shuffles multiple-choice answers each time.
final List<QuizQuestion> variablesQuiz = [
  // 1. What is a variable?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz1Q1Prompt,
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz1Q1Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q1WrongRobot,
        whyWrong: (l10n) => l10n.quiz1Q1WhyRobot,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q1WrongCommand,
        whyWrong: (l10n) => l10n.quiz1Q1WhyCommand,
      ),
    ],
    explanation: (l10n) => l10n.quiz1Q1Explain,
  ),

  // 2. What does = do?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz1Q2Prompt,
    code: const [CodeLine('speed = 5')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz1Q2Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q2WrongCheck,
        whyWrong: (l10n) => l10n.quiz1Q2WhyCheck,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q2WrongDelete,
        whyWrong: (l10n) => l10n.quiz1Q2WhyDelete,
      ),
    ],
    explanation: (l10n) => l10n.quiz1Q2Explain,
  ),

  // 3. What kind of value is "Cog"?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz1Q3Prompt,
    code: const [CodeLine('"Cog"')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz1Q3Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q3WrongNumber,
        whyWrong: (l10n) => l10n.quiz1Q3WhyNumber,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz1Q3WrongBool,
        whyWrong: (l10n) => l10n.quiz1Q3WhyBool,
      ),
    ],
    explanation: (l10n) => l10n.quiz1Q3Explain,
  ),

  // 4. battery = 100, then battery = 80
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz1Q4Prompt,
    code: const [CodeLine('battery = 100'), CodeLine('battery = 80')],
    answers: [
      QuizAnswer(label: (_) => '`80`', correct: true),
      QuizAnswer(label: (_) => '`100`', whyWrong: (l10n) => l10n.quiz1Q4Why100),
      QuizAnswer(label: (_) => '`180`', whyWrong: (l10n) => l10n.quiz1Q4Why180),
    ],
    explanation: (l10n) => l10n.quiz1Q4Explain,
  ),

  // 5. Good variable name
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz1Q5Prompt,
    answers: [
      QuizAnswer(label: (_) => '`robot_name`', correct: true),
      QuizAnswer(
        label: (_) => '`2speed`',
        whyWrong: (l10n) => l10n.quiz1Q5WhyNumberStart,
      ),
      QuizAnswer(
        label: (_) => '`my speed`',
        whyWrong: (l10n) => l10n.quiz1Q5WhySpace,
      ),
    ],
    explanation: (l10n) => l10n.quiz1Q5Explain,
  ),
];
