import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 4 quiz: Loops. 6 multiple-choice questions, built exactly like
/// Lesson 3's quiz (if_statements_quiz.dart). No arrow notes and no output
/// boxes here: they would give the answers away.
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz4…). Answers
/// that are pure code or output (`0, 1, 2`, `5`) are written here, the same
/// in every language. The quiz screen shuffles the answers.
final List<QuizQuestion> loopsQuiz = [
  // 1. What does range(3) give?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q1Prompt,
    answers: [
      QuizAnswer(label: (_) => '`0, 1, 2`', correct: true),
      QuizAnswer(
        label: (_) => '`1, 2, 3`',
        whyWrong: (l10n) => l10n.quiz4Q1Why123,
      ),
      QuizAnswer(
        label: (_) => '`0, 1, 2, 3`',
        whyWrong: (l10n) => l10n.quiz4Q1Why0123,
      ),
    ],
    explanation: (l10n) => l10n.quiz4Q1Explain,
  ),

  // 2. How many times does the loop run?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q2Prompt,
    code: const [CodeLine('for i in range(5):'), CodeLine('    print("Jump")')],
    answers: [
      QuizAnswer(label: (_) => '`5`', correct: true),
      QuizAnswer(label: (_) => '`4`', whyWrong: (l10n) => l10n.quiz4Q2Why4),
      QuizAnswer(label: (_) => '`6`', whyWrong: (l10n) => l10n.quiz4Q2Why6),
    ],
    explanation: (l10n) => l10n.quiz4Q2Explain,
  ),

  // 3. What prints for a short for loop?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q3Prompt,
    code: const [CodeLine('for n in range(1, 4):'), CodeLine('    print(n)')],
    answers: [
      QuizAnswer(label: (_) => '`1, 2, 3`', correct: true),
      QuizAnswer(
        label: (_) => '`1, 2, 3, 4`',
        whyWrong: (l10n) => l10n.quiz4Q3Why1234,
      ),
      QuizAnswer(
        label: (_) => '`0, 1, 2, 3`',
        whyWrong: (l10n) => l10n.quiz4Q3Why0123,
      ),
    ],
    explanation: (l10n) => l10n.quiz4Q3Explain,
  ),

  // 4. Why does this while loop never stop?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q4Prompt,
    code: const [
      CodeLine('battery = 5'),
      CodeLine('while battery > 0:'),
      CodeLine('    print("Moving")'),
    ],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz4Q4Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q4WrongColon,
        whyWrong: (l10n) => l10n.quiz4Q4WhyColon,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q4WrongPrint,
        whyWrong: (l10n) => l10n.quiz4Q4WhyPrint,
      ),
    ],
    explanation: (l10n) => l10n.quiz4Q4Explain,
  ),

  // 5. What does break do?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q5Prompt,
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz4Q5Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q5WrongSkip,
        whyWrong: (l10n) => l10n.quiz4Q5WhySkip,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q5WrongRestart,
        whyWrong: (l10n) => l10n.quiz4Q5WhyRestart,
      ),
    ],
    explanation: (l10n) => l10n.quiz4Q5Explain,
  ),

  // 6. for or while? (exactly 10 times)
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz4Q6Prompt,
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz4Q6Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q6WrongWhile,
        whyWrong: (l10n) => l10n.quiz4Q6WhyWhile,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz4Q6WrongCopy,
        whyWrong: (l10n) => l10n.quiz4Q6WhyCopy,
      ),
    ],
    explanation: (l10n) => l10n.quiz4Q6Explain,
  ),
];
