import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 10 quiz: Logic. 6 multiple-choice questions, built exactly like
/// Lesson 9's quiz (input_output_quiz.dart). No arrow notes and no output
/// boxes here: they would give the answers away. Every answer was checked
/// in real Python (test/lesson10_test.dart checks again).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz10…).
/// Answers that are pure code or output are written here, the same in every
/// language. The quiz screen shuffles the answers.
final List<QuizQuestion> logicQuiz = [
  // 1. True and False is False.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q1Prompt,
    code: const [CodeLine('print(True and False)')],
    answers: [
      QuizAnswer(label: (_) => '`False`', correct: true),
      QuizAnswer(
        label: (_) => '`True`',
        whyWrong: (l10n) => l10n.quiz10Q1WhyTrue,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz10Q1WrongError,
        whyWrong: (l10n) => l10n.quiz10Q1WhyError,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q1Explain,
  ),

  // 2. True or False is True.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q2Prompt,
    code: const [CodeLine('print(True or False)')],
    answers: [
      QuizAnswer(label: (_) => '`True`', correct: true),
      QuizAnswer(
        label: (_) => '`False`',
        whyWrong: (l10n) => l10n.quiz10Q2WhyFalse,
      ),
      QuizAnswer(
        label: (_) => '`True or False`',
        whyWrong: (l10n) => l10n.quiz10Q2WhyQuestion,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q2Explain,
  ),

  // 3. not True is False.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q3Prompt,
    code: const [CodeLine('print(not True)')],
    answers: [
      QuizAnswer(label: (_) => '`False`', correct: true),
      QuizAnswer(
        label: (_) => '`True`',
        whyWrong: (l10n) => l10n.quiz10Q3WhyTrue,
      ),
      QuizAnswer(
        label: (_) => '`not False`',
        whyWrong: (l10n) => l10n.quiz10Q3WhyWords,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q3Explain,
  ),

  // 4. What prints in a short if with and.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q4Prompt,
    code: const [
      CodeLine('alive = True'),
      CodeLine('charged = False'),
      CodeLine('if alive and charged:'),
      CodeLine('    print("Go!")'),
      CodeLine('else:'),
      CodeLine('    print("Stop!")'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`Stop!`', correct: true),
      QuizAnswer(label: (_) => '`Go!`', whyWrong: (l10n) => l10n.quiz10Q4WhyGo),
      QuizAnswer(
        label: (l10n) => l10n.quiz10Q4WrongBoth,
        whyWrong: (l10n) => l10n.quiz10Q4WhyBoth,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q4Explain,
  ),

  // 5. Which operator needs both sides True.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q5Prompt,
    answers: [
      QuizAnswer(label: (_) => '`and`', correct: true),
      QuizAnswer(label: (_) => '`or`', whyWrong: (l10n) => l10n.quiz10Q5WhyOr),
      QuizAnswer(
        label: (_) => '`not`',
        whyWrong: (l10n) => l10n.quiz10Q5WhyNot,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q5Explain,
  ),

  // 6. The brackets example from card 7: (True or False) and False.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz10Q6Prompt,
    answers: [
      QuizAnswer(label: (_) => '`False`', correct: true),
      QuizAnswer(
        label: (_) => '`True`',
        whyWrong: (l10n) => l10n.quiz10Q6WhyTrue,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz10Q6WrongError,
        whyWrong: (l10n) => l10n.quiz10Q6WhyError,
      ),
    ],
    explanation: (l10n) => l10n.quiz10Q6Explain,
  ),
];
