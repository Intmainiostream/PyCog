import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 9 quiz: Input and Output. 6 multiple-choice questions, built
/// exactly like Lesson 8's quiz (lists_quiz.dart). No arrow notes and no
/// output boxes here: they would give the answers away. Every answer was
/// checked in real Python with the typed answer (12) fed in
/// (test/lesson9_test.dart checks again).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz9…). Answers
/// that are pure code or output are written here, the same in every
/// language. The quiz screen shuffles the answers.
final List<QuizQuestion> inputOutputQuiz = [
  // 1. input() always gives a str.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q1Prompt,
    answers: [
      QuizAnswer(label: (_) => '`str`', correct: true),
      QuizAnswer(label: (_) => '`int`', whyWrong: (l10n) => l10n.quiz9Q1WhyInt),
      QuizAnswer(
        label: (_) => '`bool`',
        whyWrong: (l10n) => l10n.quiz9Q1WhyBool,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q1Explain,
  ),

  // 2. print("Score:", 10): the comma adds a space.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q2Prompt,
    code: const [CodeLine('print("Score:", 10)')],
    answers: [
      QuizAnswer(label: (_) => '`Score: 10`', correct: true),
      QuizAnswer(
        label: (_) => '`Score:10`',
        whyWrong: (l10n) => l10n.quiz9Q2WhyNoSpace,
      ),
      QuizAnswer(
        label: (_) => '`"Score:", 10`',
        whyWrong: (l10n) => l10n.quiz9Q2WhyQuotes,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q2Explain,
  ),

  // 3. Why age + 1 is an error: age is text.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q3Prompt,
    code: const [CodeLine('age = input("Age? ")'), CodeLine('print(age + 1)')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz9Q3Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz9Q3WrongInput,
        whyWrong: (l10n) => l10n.quiz9Q3WhyInput,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz9Q3WrongPrint,
        whyWrong: (l10n) => l10n.quiz9Q3WhyPrint,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q3Explain,
  ),

  // 4. int("5") gives the number 5.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q4Prompt,
    answers: [
      QuizAnswer(label: (_) => '`5`', correct: true),
      QuizAnswer(
        label: (_) => '`"5"`',
        whyWrong: (l10n) => l10n.quiz9Q4WhyText,
      ),
      QuizAnswer(
        label: (_) => '`5.0`',
        whyWrong: (l10n) => l10n.quiz9Q4WhyFloat,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q4Explain,
  ),

  // 5. What input("Age? ") should become, to fix the error.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q5Prompt,
    code: const [CodeLine('age = input("Age? ")'), CodeLine('print(age + 1)')],
    answers: [
      QuizAnswer(label: (_) => '`int(input("Age? "))`', correct: true),
      QuizAnswer(
        label: (_) => '`str(input("Age? "))`',
        whyWrong: (l10n) => l10n.quiz9Q5WhyStr,
      ),
      QuizAnswer(
        label: (_) => '`input("Age: ")`',
        whyWrong: (l10n) => l10n.quiz9Q5WhyQuestion,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q5Explain,
  ),

  // 6. "Hi, " + name when name is "Ana".
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz9Q6Prompt,
    code: const [CodeLine('name = "Ana"'), CodeLine('print("Hi, " + name)')],
    answers: [
      QuizAnswer(label: (_) => '`Hi, Ana`', correct: true),
      QuizAnswer(
        label: (_) => '`Hi, name`',
        whyWrong: (l10n) => l10n.quiz9Q6WhyName,
      ),
      QuizAnswer(
        label: (_) => '`Hi,Ana`',
        whyWrong: (l10n) => l10n.quiz9Q6WhySpace,
      ),
    ],
    explanation: (l10n) => l10n.quiz9Q6Explain,
  ),
];
