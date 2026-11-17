import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 7 quiz: Strings. 6 multiple-choice questions, built exactly like
/// Lesson 6's quiz (math_operators_quiz.dart). No arrow notes and no output
/// boxes here: they would give the answers away. Every answer was checked by
/// running the code in real Python (test/lesson7_test.dart checks again).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz7…). Answers
/// that are pure output (`6`, `HaHaHa`...) are written here, the same in
/// every language. The quiz screen shuffles the answers.
final List<QuizQuestion> stringsQuiz = [
  // 1. len("Hi Cog"): the space counts.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q1Prompt,
    code: const [CodeLine('print(len("Hi Cog"))')],
    answers: [
      QuizAnswer(label: (_) => '`6`', correct: true),
      QuizAnswer(label: (_) => '`5`', whyWrong: (l10n) => l10n.quiz7Q1Why5),
      QuizAnswer(label: (_) => '`2`', whyWrong: (l10n) => l10n.quiz7Q1Why2),
    ],
    explanation: (l10n) => l10n.quiz7Q1Explain,
  ),

  // 2. "Ha" * 3 repeats, with no spaces.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q2Prompt,
    code: const [CodeLine('print("Ha" * 3)')],
    answers: [
      QuizAnswer(label: (_) => '`HaHaHa`', correct: true),
      QuizAnswer(label: (_) => '`Ha3`', whyWrong: (l10n) => l10n.quiz7Q2WhyHa3),
      QuizAnswer(
        label: (_) => '`Ha Ha Ha`',
        whyWrong: (l10n) => l10n.quiz7Q2WhySpaces,
      ),
    ],
    explanation: (l10n) => l10n.quiz7Q2Explain,
  ),

  // 3. "Hi, " + "Cog": the space inside the quotes stays.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q3Prompt,
    code: const [CodeLine('print("Hi, " + "Cog")')],
    answers: [
      QuizAnswer(label: (_) => '`Hi, Cog`', correct: true),
      QuizAnswer(
        label: (_) => '`Hi,Cog`',
        whyWrong: (l10n) => l10n.quiz7Q3WhyNoSpace,
      ),
      QuizAnswer(
        label: (_) => '`Hi, + Cog`',
        whyWrong: (l10n) => l10n.quiz7Q3WhyPlus,
      ),
    ],
    explanation: (l10n) => l10n.quiz7Q3Explain,
  ),

  // 4. "Cog"[0]: counting starts at 0.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q4Prompt,
    code: const [CodeLine('print("Cog"[0])')],
    answers: [
      QuizAnswer(label: (_) => '`C`', correct: true),
      QuizAnswer(label: (_) => '`o`', whyWrong: (l10n) => l10n.quiz7Q4WhyO),
      QuizAnswer(label: (_) => '`g`', whyWrong: (l10n) => l10n.quiz7Q4WhyG),
    ],
    explanation: (l10n) => l10n.quiz7Q4Explain,
  ),

  // 5. Why "5" + 5 is an error.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q5Prompt,
    code: const [CodeLine('print("5" + 5)')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz7Q5Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz7Q5WrongQuotes,
        whyWrong: (l10n) => l10n.quiz7Q5WhyQuotes,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz7Q5WrongPlus,
        whyWrong: (l10n) => l10n.quiz7Q5WhyPlus,
      ),
    ],
    explanation: (l10n) => l10n.quiz7Q5Explain,
  ),

  // 6. .upper() changes every letter.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz7Q6Prompt,
    code: const [CodeLine('print("cog".upper())')],
    answers: [
      QuizAnswer(label: (_) => '`COG`', correct: true),
      QuizAnswer(
        label: (_) => '`cog`',
        whyWrong: (l10n) => l10n.quiz7Q6WhyLower,
      ),
      QuizAnswer(
        label: (_) => '`Cog`',
        whyWrong: (l10n) => l10n.quiz7Q6WhyFirst,
      ),
    ],
    explanation: (l10n) => l10n.quiz7Q6Explain,
  ),
];
