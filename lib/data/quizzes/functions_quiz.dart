import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 5 quiz: Functions. 6 multiple-choice questions, built exactly like
/// Lesson 4's quiz (loops_quiz.dart). No arrow notes and no output boxes
/// here: they would give the answers away. Answers that depend on running
/// code were checked in real Python.
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz5…). Answers
/// that are pure code or output (`Hi, Cog`, `5`) are written here, the same
/// in every language. The quiz screen shuffles the answers.
final List<QuizQuestion> functionsQuiz = [
  // 1. Only def, never called: nothing shows.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q1Prompt,
    code: const [CodeLine('def say_hello():'), CodeLine('    print("Hi!")')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz5Q1Right, correct: true),
      QuizAnswer(label: (_) => '`Hi!`', whyWrong: (l10n) => l10n.quiz5Q1WhyHi),
      QuizAnswer(
        label: (l10n) => l10n.quiz5Q1WrongError,
        whyWrong: (l10n) => l10n.quiz5Q1WhyError,
      ),
    ],
    explanation: (l10n) => l10n.quiz5Q1Explain,
  ),

  // 2. What is a parameter?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q2Prompt,
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz5Q2Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz5Q2WrongFunc,
        whyWrong: (l10n) => l10n.quiz5Q2WhyFunc,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz5Q2WrongText,
        whyWrong: (l10n) => l10n.quiz5Q2WhyText,
      ),
    ],
    explanation: (l10n) => l10n.quiz5Q2Explain,
  ),

  // 3. What prints for a short call?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q3Prompt,
    code: const [
      CodeLine('def greet(name):'),
      CodeLine('    print("Hi,", name)'),
      CodeLine('greet("Cog")'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`Hi, Cog`', correct: true),
      QuizAnswer(
        label: (_) => '`Hi, name`',
        whyWrong: (l10n) => l10n.quiz5Q3WhyName,
      ),
      QuizAnswer(
        label: (_) => '`greet("Cog")`',
        whyWrong: (l10n) => l10n.quiz5Q3WhyCall,
      ),
    ],
    explanation: (l10n) => l10n.quiz5Q3Explain,
  ),

  // 4. print vs return
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q4Prompt,
    answers: [
      QuizAnswer(label: (_) => '`return`', correct: true),
      QuizAnswer(
        label: (_) => '`print`',
        whyWrong: (l10n) => l10n.quiz5Q4WhyPrint,
      ),
      QuizAnswer(label: (_) => '`def`', whyWrong: (l10n) => l10n.quiz5Q4WhyDef),
    ],
    explanation: (l10n) => l10n.quiz5Q4Explain,
  ),

  // 5. What does add(2, 3) give?
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q5Prompt,
    code: const [CodeLine('def add(a, b):'), CodeLine('    return a + b')],
    answers: [
      QuizAnswer(label: (_) => '`5`', correct: true),
      QuizAnswer(label: (_) => '`23`', whyWrong: (l10n) => l10n.quiz5Q5Why23),
      QuizAnswer(
        label: (_) => '`a + b`',
        whyWrong: (l10n) => l10n.quiz5Q5WhyExpr,
      ),
    ],
    explanation: (l10n) => l10n.quiz5Q5Explain,
  ),

  // 6. How many times does it print? (only calls print, not def)
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz5Q6Prompt,
    code: const [
      CodeLine('def say_hi():'),
      CodeLine('    print("Hi!")'),
      CodeLine('say_hi()'),
      CodeLine('say_hi()'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`2`', correct: true),
      QuizAnswer(label: (_) => '`1`', whyWrong: (l10n) => l10n.quiz5Q6Why1),
      QuizAnswer(label: (_) => '`3`', whyWrong: (l10n) => l10n.quiz5Q6Why3),
    ],
    explanation: (l10n) => l10n.quiz5Q6Explain,
  ),
];
