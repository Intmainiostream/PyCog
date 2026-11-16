import 'lesson_card.dart';

/// The kinds of quiz questions the quiz screen understands.
enum QuestionType { multipleChoice, trueFalse }

/// One answer button in a quiz question.
class QuizAnswer {
  const QuizAnswer({required this.label, this.correct = false, this.whyWrong});

  /// Button text. Wrap code in backticks, e.g. (_) => '`robot_name`'.
  final LocalizedText label;
  final bool correct;

  /// What Cog says if a student picks this (wrong) answer: a gentle hint,
  /// one or two short sentences, without giving the right answer away.
  final LocalizedText? whyWrong;
}

/// One quiz question.
class QuizQuestion {
  /// A multiple-choice question with 3 or 4 answers (exactly one correct).
  /// The answer buttons are shuffled every time the quiz starts.
  QuizQuestion.multipleChoice({
    required this.prompt,
    required this.answers,
    required this.explanation,
    this.code = const [],
  }) : type = QuestionType.multipleChoice,
       assert(answers.length == 3 || answers.length == 4),
       assert(answers.where((a) => a.correct).length == 1);

  /// A true/false question. The buttons always show True first, then False.
  QuizQuestion.trueFalse({
    required this.prompt,
    required bool answerIsTrue,
    required LocalizedText whyWrong,
    required this.explanation,
    this.code = const [],
  }) : type = QuestionType.trueFalse,
       answers = [
         QuizAnswer(
           label: (l10n) => l10n.quizTrue,
           correct: answerIsTrue,
           whyWrong: answerIsTrue ? null : whyWrong,
         ),
         QuizAnswer(
           label: (l10n) => l10n.quizFalse,
           correct: !answerIsTrue,
           whyWrong: answerIsTrue ? whyWrong : null,
         ),
       ];

  final QuestionType type;

  /// The question Cog asks (in the speech bubble).
  final LocalizedText prompt;

  /// Optional code shown under the question.
  final List<CodeLine> code;

  final List<QuizAnswer> answers;

  /// Why the right answer is right. Shown after a correct answer, and when
  /// the answer is revealed after 2 wrong tries.
  final LocalizedText explanation;

  int get correctIndex => answers.indexWhere((a) => a.correct);

  /// Multiple-choice answers are shuffled; true/false stay in order.
  bool get shuffleAnswers => type == QuestionType.multipleChoice;
}

/// After this many wrong tries on one question, the answer is revealed.
const maxTriesPerQuestion = 2;

/// Stars for a finished quiz: 3 for no mistakes, 2 for 1-2 mistakes,
/// 1 for more. (Finishing always earns at least 1 star.)
int starsForMistakes(int mistakes) {
  if (mistakes <= 0) return 3;
  if (mistakes <= 2) return 2;
  return 1;
}
