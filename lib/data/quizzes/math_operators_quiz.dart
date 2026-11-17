import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 6 quiz: Math Operators. 6 multiple-choice questions, built exactly
/// like Lesson 5's quiz (functions_quiz.dart). No arrow notes and no output
/// boxes here: they would give the answers away. Every answer was checked by
/// running the code in real Python (test/lesson6_test.dart checks again).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz6…). Answers
/// that are pure output (`5.0`, `3`...) are written here, the same in every
/// language. The quiz screen shuffles the answers.
final List<QuizQuestion> mathOperatorsQuiz = [
  // 1. / always gives a float: 5.0, not 5.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q1Prompt,
    code: const [CodeLine('print(10 / 2)')],
    answers: [
      QuizAnswer(label: (_) => '`5.0`', correct: true),
      QuizAnswer(label: (_) => '`5`', whyWrong: (l10n) => l10n.quiz6Q1Why5),
      QuizAnswer(label: (_) => '`20`', whyWrong: (l10n) => l10n.quiz6Q1Why20),
    ],
    explanation: (l10n) => l10n.quiz6Q1Explain,
  ),

  // 2. 7 // 2: full teams.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q2Prompt,
    code: const [CodeLine('print(7 // 2)')],
    answers: [
      QuizAnswer(label: (_) => '`3`', correct: true),
      QuizAnswer(label: (_) => '`3.5`', whyWrong: (l10n) => l10n.quiz6Q2Why35),
      QuizAnswer(label: (_) => '`1`', whyWrong: (l10n) => l10n.quiz6Q2Why1),
    ],
    explanation: (l10n) => l10n.quiz6Q2Explain,
  ),

  // 3. 7 % 2: left over.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q3Prompt,
    code: const [CodeLine('print(7 % 2)')],
    answers: [
      QuizAnswer(label: (_) => '`1`', correct: true),
      QuizAnswer(label: (_) => '`3`', whyWrong: (l10n) => l10n.quiz6Q3Why3),
      QuizAnswer(label: (_) => '`3.5`', whyWrong: (l10n) => l10n.quiz6Q3Why35),
    ],
    explanation: (l10n) => l10n.quiz6Q3Explain,
  ),

  // 4. Order of operations: * goes first.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q4Prompt,
    code: const [CodeLine('print(2 + 3 * 4)')],
    answers: [
      QuizAnswer(label: (_) => '`14`', correct: true),
      QuizAnswer(label: (_) => '`20`', whyWrong: (l10n) => l10n.quiz6Q4Why20),
      QuizAnswer(label: (_) => '`9`', whyWrong: (l10n) => l10n.quiz6Q4Why9),
    ],
    explanation: (l10n) => l10n.quiz6Q4Explain,
  ),

  // 5. Power: 2 ** 3 is 8, not 6.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q5Prompt,
    code: const [CodeLine('print(2 ** 3)')],
    answers: [
      QuizAnswer(label: (_) => '`8`', correct: true),
      QuizAnswer(label: (_) => '`6`', whyWrong: (l10n) => l10n.quiz6Q5Why6),
      QuizAnswer(label: (_) => '`9`', whyWrong: (l10n) => l10n.quiz6Q5Why9),
    ],
    explanation: (l10n) => l10n.quiz6Q5Explain,
  ),

  // 6. score += 10 adds to the old value.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz6Q6Prompt,
    code: const [
      CodeLine('score = 5'),
      CodeLine('score += 10'),
      CodeLine('print(score)'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`15`', correct: true),
      QuizAnswer(label: (_) => '`10`', whyWrong: (l10n) => l10n.quiz6Q6Why10),
      QuizAnswer(label: (_) => '`5`', whyWrong: (l10n) => l10n.quiz6Q6Why5),
    ],
    explanation: (l10n) => l10n.quiz6Q6Explain,
  ),
];
