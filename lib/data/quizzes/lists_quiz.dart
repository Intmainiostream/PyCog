import '../../models/lesson_card.dart';
import '../../models/quiz.dart';

/// Lesson 8 quiz: Lists. 6 multiple-choice questions, built exactly like
/// Lesson 7's quiz (strings_quiz.dart). No arrow notes and no output boxes
/// here: they would give the answers away. Every answer was checked by
/// running the code in real Python (test/lesson8_test.dart checks again).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys quiz8…). Answers
/// that are pure output (`shield`, `3`...) are written here, the same in
/// every language. The quiz screen shuffles the answers.

/// The backpack on 3 lines, as on the cards (one line is too wide).
const _backpack = [
  CodeLine('items = ["sword",'),
  CodeLine('         "shield",'),
  CodeLine('         "potion"]'),
];

final List<QuizQuestion> listsQuiz = [
  // 1. items[1] is the second item.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q1Prompt,
    code: const [..._backpack, CodeLine('print(items[1])')],
    answers: [
      QuizAnswer(label: (_) => '`shield`', correct: true),
      QuizAnswer(
        label: (_) => '`sword`',
        whyWrong: (l10n) => l10n.quiz8Q1WhySword,
      ),
      QuizAnswer(
        label: (_) => '`potion`',
        whyWrong: (l10n) => l10n.quiz8Q1WhyPotion,
      ),
    ],
    explanation: (l10n) => l10n.quiz8Q1Explain,
  ),

  // 2. len(items) counts items.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q2Prompt,
    code: const [..._backpack, CodeLine('print(len(items))')],
    answers: [
      QuizAnswer(label: (_) => '`3`', correct: true),
      QuizAnswer(label: (_) => '`2`', whyWrong: (l10n) => l10n.quiz8Q2Why2),
      QuizAnswer(label: (_) => '`17`', whyWrong: (l10n) => l10n.quiz8Q2Why17),
    ],
    explanation: (l10n) => l10n.quiz8Q2Explain,
  ),

  // 3. len after an append.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q3Prompt,
    code: const [
      ..._backpack,
      CodeLine('items.append("map")'),
      CodeLine('print(len(items))'),
    ],
    answers: [
      QuizAnswer(label: (_) => '`4`', correct: true),
      QuizAnswer(label: (_) => '`3`', whyWrong: (l10n) => l10n.quiz8Q3Why3),
      QuizAnswer(label: (_) => '`1`', whyWrong: (l10n) => l10n.quiz8Q3Why1),
    ],
    explanation: (l10n) => l10n.quiz8Q3Explain,
  ),

  // 4. What a short for loop prints.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q4Prompt,
    code: const [
      CodeLine('bag = ["map", "key"]'),
      CodeLine('for item in bag:'),
      CodeLine('    print(item)'),
    ],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz8Q4Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz8Q4WrongItem,
        whyWrong: (l10n) => l10n.quiz8Q4WhyItem,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz8Q4WrongOne,
        whyWrong: (l10n) => l10n.quiz8Q4WhyOne,
      ),
    ],
    explanation: (l10n) => l10n.quiz8Q4Explain,
  ),

  // 5. Why items[3] is an error on a 3-item list.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q5Prompt,
    code: const [..._backpack, CodeLine('print(items[3])')],
    answers: [
      QuizAnswer(label: (l10n) => l10n.quiz8Q5Right, correct: true),
      QuizAnswer(
        label: (l10n) => l10n.quiz8Q5WrongBrackets,
        whyWrong: (l10n) => l10n.quiz8Q5WhyBrackets,
      ),
      QuizAnswer(
        label: (l10n) => l10n.quiz8Q5WrongEmpty,
        whyWrong: (l10n) => l10n.quiz8Q5WhyEmpty,
      ),
    ],
    explanation: (l10n) => l10n.quiz8Q5Explain,
  ),

  // 6. "sword" in items is True.
  QuizQuestion.multipleChoice(
    prompt: (l10n) => l10n.quiz8Q6Prompt,
    code: const [..._backpack, CodeLine('print("sword" in items)')],
    answers: [
      QuizAnswer(label: (_) => '`True`', correct: true),
      QuizAnswer(
        label: (_) => '`False`',
        whyWrong: (l10n) => l10n.quiz8Q6WhyFalse,
      ),
      QuizAnswer(
        label: (_) => '`sword`',
        whyWrong: (l10n) => l10n.quiz8Q6WhySword,
      ),
    ],
    explanation: (l10n) => l10n.quiz8Q6Explain,
  ),
];
