import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 3 quiz: If Statements. 6 multiple-choice questions, built exactly
/// like Lesson 2's quiz (data_types_quiz.dart). No arrow notes here: they
/// would give the answers away.
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz3…). Answers
/// that are pure code or program output (`lives == 3`, `Silver!`) are written
/// here, the same in every language. The quiz screen shuffles the answers.
final List<QuizQuestion> ifStatementsQuiz = [
  // 1. = vs ==
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q1Prompt,
    answers: [
      QuizAnswer(label: (_) => '`lives == 3`', correct: true),
      QuizAnswer(
        label: (_) => '`lives = 3`',
        whyWrong: (l10n) => l10n.quiz3Q1WhyAssign,
      ),
      QuizAnswer(
        label: (_) => '`lives != 3`',
        whyWrong: (l10n) => l10n.quiz3Q1WhyNotEq,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q1Explain,
  ),

  // 2. Missing colon
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q2Prompt,
    code: const [CodeLine('if lives > 0'), CodeLine('    print("Go!")')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz3Q2Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz3Q2WrongQuotes,
        whyWrong: (l10n) => l10n.quiz3Q2WhyQuotes,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz3Q2WrongNothing,
        whyWrong: (l10n) => l10n.quiz3Q2WhyNothing,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q2Explain,
  ),

  // 3. What prints for battery = 10?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q3Prompt,
    code: const [
      CodeLine('battery = 10'),
      CodeLine('if battery < 20:'),
      CodeLine('    print("Low battery!")'),
      CodeLine('else:'),
      CodeLine('    print("Battery OK!")'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`Low battery!`', correct: true),
      QuizAnswer(
        label: (_) => '`Battery OK!`',
        whyWrong: (l10n) => l10n.quiz3Q3WhyOk,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz3Q3WrongNothing,
        whyWrong: (l10n) => l10n.quiz3Q3WhyNothing,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q3Explain,
  ),

  // 4. When does else run?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q4Prompt,
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz3Q4Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz3Q4WrongTrue,
        whyWrong: (l10n) => l10n.quiz3Q4WhyTrue,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz3Q4WrongAlways,
        whyWrong: (l10n) => l10n.quiz3Q4WhyAlways,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q4Explain,
  ),

  // 5. score >= 90 when score is 90
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q5Prompt,
    answers: [
      QuizAnswer(label: (_) => '`True`', correct: true),
      QuizAnswer(
        label: (_) => '`False`',
        whyWrong: (l10n) => l10n.quiz3Q5WhyFalse,
      ),
      QuizAnswer(
        label: (_) => '`90`',
        whyWrong: (l10n) => l10n.quiz3Q5WhyNumber,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q5Explain,
  ),

  // 6. elif: what prints for score = 75?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz3Q6Prompt,
    code: const [
      CodeLine('score = 75'),
      CodeLine('if score >= 90:'),
      CodeLine('    print("Gold!")'),
      CodeLine('elif score >= 70:'),
      CodeLine('    print("Silver!")'),
      CodeLine('else:'),
      CodeLine('    print("Try again!")'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`Silver!`', correct: true),
      QuizAnswer(
        label: (_) => '`Gold!`',
        whyWrong: (l10n) => l10n.quiz3Q6WhyGold,
      ),
      QuizAnswer(
        label: (_) => '`Try again!`',
        whyWrong: (l10n) => l10n.quiz3Q6WhyTryAgain,
      ),
    ],
    explanation: (l10n) => l10n.quiz3Q6Explain,
  ),
];
