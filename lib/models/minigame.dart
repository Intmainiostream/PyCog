import 'lesson_card.dart';
import 'quiz.dart';

/// The four kinds of MINIGAME challenges.
enum ChallengeType {
  /// Pick the right answer.
  quiz,

  /// Code with one missing part. The student types or picks it, then it runs.
  fillBlank,

  /// Code with a mistake. The student fixes it, then it runs.
  fixBug,

  /// The student writes all the code.
  writeCode,
}

/// One hidden test for a code challenge: what input() gets, and exactly
/// what the program must show.
///
/// [output] is what the CODING output box would show, one entry per line,
/// so input() questions and the typed answers are part of it, e.g.
/// `TestCase(inputs: ['12'], output: ['Age? 12', '13'])`.
class TestCase {
  const TestCase({this.inputs = const [], required this.output});

  final List<String> inputs;
  final List<String> output;
}

/// Marks the missing part in a fill-the-blank template.
const blankMarker = '___';

/// How many hints every code challenge has (quizzes have none).
const hintsPerChallenge = 2;

/// One MINIGAME challenge. Text is [LocalizedText] (English or Tagalog);
/// code, typed inputs and outputs are plain strings (always English).
class Challenge {
  /// Pick the right answer. [answers] work like the lesson quizzes. No
  /// hints: stars come from wrong picks ([starsForWrongPicks]).
  Challenge.quiz({
    required this.id,
    required this.title,
    required this.prompt,
    required this.answers,
    this.code = const [],
    this.typed = const [],
  }) : type = ChallengeType.quiz,
       hints = const [],
       template = '',
       choices = const [],
       starter = '',
       solution = '',
       tests = const [],
       showFirstTest = false,
       requiredCode = const [],
       assert(answers.where((a) => a.correct).length == 1);

  /// Fill the blank: [template] has [blankMarker] once. With [choices] the
  /// student picks one; without, the student types it. [solution] is the
  /// right text for the blank.
  Challenge.fillBlank({
    required this.id,
    required this.title,
    required this.prompt,
    required this.hints,
    required this.template,
    required this.solution,
    required this.tests,
    this.choices = const [],
    this.showFirstTest = false,
  }) : type = ChallengeType.fillBlank,
       typed = const [],
       answers = const [],
       code = const [],
       starter = '',
       requiredCode = const [],
       assert(hints.length == hintsPerChallenge),
       assert(tests.isNotEmpty);

  /// Fix the bug: [starter] is the code with the mistake; [solution] is one
  /// fixed version.
  Challenge.fixBug({
    required this.id,
    required this.title,
    required this.prompt,
    required this.hints,
    required this.starter,
    required this.solution,
    required this.tests,
    this.showFirstTest = false,
    this.requiredCode = const [],
  }) : type = ChallengeType.fixBug,
       typed = const [],
       answers = const [],
       code = const [],
       template = '',
       choices = const [],
       assert(hints.length == hintsPerChallenge),
       assert(tests.isNotEmpty);

  /// Write it yourself: [starter] is optional code to start from (often
  /// empty); [solution] is one right program.
  Challenge.writeCode({
    required this.id,
    required this.title,
    required this.prompt,
    required this.hints,
    required this.solution,
    required this.tests,
    this.starter = '',
    this.showFirstTest = false,
    this.requiredCode = const [],
  }) : type = ChallengeType.writeCode,
       typed = const [],
       answers = const [],
       code = const [],
       template = '',
       choices = const [],
       assert(hints.length == hintsPerChallenge),
       assert(tests.isNotEmpty);

  /// Also the save key and the .arb key prefix, e.g. `mgL1C1`.
  final String id;
  final ChallengeType type;
  final LocalizedText title;

  /// What Cog asks the student to do.
  final LocalizedText prompt;

  /// Code challenges: exactly [hintsPerChallenge] hints, shown in order.
  /// Each costs a star. Quizzes: none.
  final List<LocalizedText> hints;

  /// Quiz only: code shown under the question.
  final List<CodeLine> code;

  /// Quiz only: the answer buttons (exactly one correct).
  final List<QuizAnswer> answers;

  /// Quiz only, optional: what the person types when [code] runs (its
  /// input() answers). The problem text says it, e.g. "You type `12`". The
  /// right answer is then what `print` shows (not the input() lines).
  final List<String> typed;

  /// Fill the blank only: the code, with [blankMarker] where the blank is.
  final String template;

  /// Fill the blank only: answers to pick from (empty = type it).
  final List<String> choices;

  /// Fix the bug / write it yourself: the code in the box at the start.
  final String starter;

  /// Never shown to the student. Fill the blank: the blank's text. Fix the
  /// bug / write it yourself: a whole right program. Tests run it to prove
  /// the challenge can be solved.
  final String solution;

  /// The hidden tests. The code passes only if every one matches.
  final List<TestCase> tests;

  /// When true, the first test is shown as an example before the student
  /// runs anything (so it is not hidden).
  final bool showFirstTest;

  /// Fix the bug / write it yourself, optional: pieces the student's code
  /// must contain, e.g. `speed =` or `print(speed)`, so printing a fixed
  /// answer does not pass. Each piece is a [String] or an [AnyOf] (any one
  /// of its options counts). Checked after the output is right; spaces
  /// around signs, after commas and inside brackets don't matter, `'` and
  /// `"` are the same, and `#` comments don't count. Empty = no check.
  final List<Object> requiredCode;

  /// The options of each required piece (one for a plain [String]).
  List<List<String>> get requiredOptions => [
    for (final piece in requiredCode) pieceOptions(piece),
  ];

  /// The first option of each required piece: the way the problem text
  /// names it, and what the "must use" message shows.
  List<String> get requiredFirst => [
    for (final options in requiredOptions) options.first,
  ];

  /// True for the three types whose answer is code that runs.
  bool get runsCode => type != ChallengeType.quiz;

  /// The program to run for what the student entered (the blank's text for
  /// fill the blank, the whole code otherwise).
  String programFor(String entered) => type == ChallengeType.fillBlank
      ? template.replaceFirst(blankMarker, entered)
      : entered;

  /// The program [solution] stands for.
  String get solutionProgram => programFor(solution);
}

/// A required piece with alternatives: the code needs any one of
/// [options], e.g. `AnyOf(['score += 5', 'score = score + 5'])`. The first
/// option is the one the problem text names and the message shows. Give
/// it at least two options (the data test checks this).
class AnyOf {
  const AnyOf(this.options);

  final List<String> options;
}

/// The options of a required piece: a [String] (one option) or an [AnyOf].
List<String> pieceOptions(Object piece) => switch (piece) {
  final String one => [one],
  AnyOf(:final options) => options,
  _ => throw ArgumentError('A required piece is a String or an AnyOf'),
};

/// One level of the map: up to [challengesPerLevel] challenges.
class MinigameLevel {
  const MinigameLevel({required this.number, required this.challenges});

  /// 1 to 10.
  final int number;
  final List<Challenge> challenges;
}

/// Each level holds this many challenges once it is full.
const challengesPerLevel = 10;

/// The next level opens when this many challenges in a level have at
/// least 1 star.
const challengesToUnlockNext = 7;

/// Stars for solving a challenge after using [hintsUsed] hints: 3 with no
/// hints, 2 with one, 1 with two or more. Failed runs never cost stars.
int starsForHints(int hintsUsed) {
  if (hintsUsed <= 0) return 3;
  if (hintsUsed == 1) return 2;
  return 1;
}

/// Stars for a quiz challenge after [wrongPicks] wrong answers: 3 when right
/// on the first try, 2 on the second try, 1 on any later try.
int starsForWrongPicks(int wrongPicks) {
  if (wrongPicks <= 0) return 3;
  if (wrongPicks == 1) return 2;
  return 1;
}

/// The stars a challenge is worth right now: wrong picks count for a quiz,
/// hints count for the other three types.
int starsFor(Challenge challenge, {int hintsUsed = 0, int wrongPicks = 0}) =>
    challenge.type == ChallengeType.quiz
    ? starsForWrongPicks(wrongPicks)
    : starsForHints(hintsUsed);
