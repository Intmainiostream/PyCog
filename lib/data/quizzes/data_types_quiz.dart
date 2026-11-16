import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 2 quiz: Data Types. 6 multiple-choice questions, built exactly like
/// Lesson 1's quiz (variables_quiz.dart). No arrow notes here: they would
/// give the answers away.
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz2…). Answers
/// that are pure code (`int`, `2.5`, `True`…) are written here, the same in
/// every language. The quiz screen shuffles the answers each time.
final List<QuizQuestion> dataTypesQuiz = [
  // 1. What type is 3?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q1Prompt,
    code: const [CodeLine('lives = 3')],
    answers: [
      QuizAnswer(label: (_) => '`int`', correct: true),
      QuizAnswer(
        label: (_) => '`float`',
        whyWrong: (l10n) => l10n.quiz2Q1WhyFloat,
      ),
      QuizAnswer(label: (_) => '`str`', whyWrong: (l10n) => l10n.quiz2Q1WhyStr),
    ],
    explanation: (l10n) => l10n.quiz2Q1Explain,
  ),

  // 2. Which value is a float?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q2Prompt,
    answers: [
      QuizAnswer(label: (_) => '`2.5`', correct: true),
      QuizAnswer(label: (_) => '`25`', whyWrong: (l10n) => l10n.quiz2Q2Why25),
      QuizAnswer(
        label: (_) => '`"2.5"`',
        whyWrong: (l10n) => l10n.quiz2Q2WhyQuoted,
      ),
    ],
    explanation: (l10n) => l10n.quiz2Q2Explain,
  ),

  // 3. "5" vs 5: what type is "5"?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q3Prompt,
    code: const [CodeLine('room = "5"')],
    answers: [
      QuizAnswer(label: (_) => '`str`', correct: true),
      QuizAnswer(label: (_) => '`int`', whyWrong: (l10n) => l10n.quiz2Q3WhyInt),
      QuizAnswer(
        label: (_) => '`bool`',
        whyWrong: (l10n) => l10n.quiz2Q3WhyBool,
      ),
    ],
    explanation: (l10n) => l10n.quiz2Q3Explain,
  ),

  // 4. True vs true: which is a real bool?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q4Prompt,
    answers: [
      QuizAnswer(label: (_) => '`True`', correct: true),
      QuizAnswer(
        label: (_) => '`true`',
        whyWrong: (l10n) => l10n.quiz2Q4WhyLower,
      ),
      QuizAnswer(
        label: (_) => '`"True"`',
        whyWrong: (l10n) => l10n.quiz2Q4WhyQuoted,
      ),
    ],
    explanation: (l10n) => l10n.quiz2Q4Explain,
  ),

  // 5. What does print(type(speed)) show?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q5Prompt,
    code: const [CodeLine('speed = 2.5'), CodeLine('print(type(speed))')],
    answers: [
      QuizAnswer(label: (_) => "`<class 'float'>`", correct: true),
      QuizAnswer(
        label: (_) => "`<class 'int'>`",
        whyWrong: (l10n) => l10n.quiz2Q5WhyInt,
      ),
      QuizAnswer(
        label: (_) => '`2.5`',
        whyWrong: (l10n) => l10n.quiz2Q5WhyValue,
      ),
    ],
    explanation: (l10n) => l10n.quiz2Q5Explain,
  ),

  // 6. Best type for "online or not?"
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz2Q6Prompt,
    answers: [
      QuizAnswer(label: (_) => '`bool`', correct: true),
      QuizAnswer(label: (_) => '`int`', whyWrong: (l10n) => l10n.quiz2Q6WhyInt),
      QuizAnswer(label: (_) => '`str`', whyWrong: (l10n) => l10n.quiz2Q6WhyStr),
    ],
    explanation: (l10n) => l10n.quiz2Q6Explain,
  ),
];
