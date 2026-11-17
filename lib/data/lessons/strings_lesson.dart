import '../../models/lesson_card.dart';

/// Lesson 7: Strings. Explanation cards (the quiz is in
/// lib/data/quizzes/strings_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson7Card… for
/// cards, lesson7Note… for the "← arrow notes"). Code and `output` (what the
/// code prints) are the same in every language. Built exactly like Lesson 6
/// (math_operators_lesson.dart). Every `output` was checked by running the
/// card's code in real Python 3.13, including the exact error message.
final List<LessonCard> stringsLessonCards = [
  // 1. What is a string? A robot's name tag; connects to str (Lesson 2).
  LessonCard(
    title: (l10n) => l10n.lesson7Card1Title,
    speech: (l10n) => l10n.lesson7Card1Speech,
    code: [
      CodeLine('name = "Cog"', note: (l10n) => l10n.lesson7NoteName),
      CodeLine('print(name)', note: (l10n) => l10n.lesson7NotePrintName),
      CodeLine('print(type(name))', note: (l10n) => l10n.lesson7NoteType),
    ],
    output: const ['Cog', "<class 'str'>"],
    tip: (l10n) => l10n.lesson7Card1Tip,
  ),

  // 2. Single or double quotes: both ✓, mixed ✗. Nothing prints (the ✗
  // line is a SyntaxError), so there is no output box.
  LessonCard(
    title: (l10n) => l10n.lesson7Card2Title,
    speech: (l10n) => l10n.lesson7Card2Speech,
    code: [
      CodeLine(
        "greeting = 'Hi'",
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteSingle,
      ),
      CodeLine(
        'greeting = "Hi"',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteDouble,
      ),
      CodeLine(
        'greeting = "Hi\'',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson7NoteMismatch,
      ),
    ],
    tip: (l10n) => l10n.lesson7Card2Tip,
  ),

  // 3. Joining with +: the space inside the quotes matters.
  LessonCard(
    title: (l10n) => l10n.lesson7Card3Title,
    speech: (l10n) => l10n.lesson7Card3Speech,
    code: [
      CodeLine(
        'print("Hi, " + "Cog")',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteJoinGood,
      ),
      CodeLine(
        'print("Hi," + "Cog")',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson7NoteJoinBad,
      ),
    ],
    output: const ['Hi, Cog', 'Hi,Cog'],
    tip: (l10n) => l10n.lesson7Card3Tip,
  ),

  // 4. Repeating with * (connects to * in Lesson 6).
  LessonCard(
    title: (l10n) => l10n.lesson7Card4Title,
    speech: (l10n) => l10n.lesson7Card4Speech,
    code: [
      CodeLine('print("Ha" * 3)', note: (l10n) => l10n.lesson7NoteHa),
      CodeLine('print("=" * 10)', note: (l10n) => l10n.lesson7NoteBanner),
    ],
    output: const ['HaHaHa', '=========='],
    tip: (l10n) => l10n.lesson7Card4Tip,
  ),

  // 5. len(): spaces count too.
  LessonCard(
    title: (l10n) => l10n.lesson7Card5Title,
    speech: (l10n) => l10n.lesson7Card5Speech,
    code: [
      CodeLine('print(len("Cog"))', note: (l10n) => l10n.lesson7NoteLen3),
      CodeLine('print(len("Hi Cog"))', note: (l10n) => l10n.lesson7NoteLen6),
    ],
    output: const ['3', '6'],
    tip: (l10n) => l10n.lesson7Card5Tip,
  ),

  // 6. Big warning: [ ] counts from 0 (like range(3) in Lesson 4).
  LessonCard(
    title: (l10n) => l10n.lesson7Card6Title,
    speech: (l10n) => l10n.lesson7Card6Speech,
    code: [
      CodeLine('print("Cog"[0])', note: (l10n) => l10n.lesson7NoteIndex0),
      CodeLine('print("Cog"[1])', note: (l10n) => l10n.lesson7NoteIndex1),
      CodeLine('print("Cog"[2])', note: (l10n) => l10n.lesson7NoteIndex2),
    ],
    output: const ['C', 'o', 'g'],
    tip: (l10n) => l10n.lesson7Card6Tip,
  ),

  // 7. Big warning: "5" + 5 is an error (✗), then three fixes (✓).
  LessonCard(
    title: (l10n) => l10n.lesson7Card7Title,
    speech: (l10n) => l10n.lesson7Card7Speech,
    code: [
      CodeLine(
        'print("5" + 5)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson7NoteMixBad,
      ),
      CodeLine(
        'print("5" + "5")',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteBothText,
      ),
      CodeLine(
        'print(5 + 5)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteBothNumbers,
      ),
      // Two short lines (not one long one) so each fits on a 360px phone.
      CodeLine(
        'score = str(10)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteStrTen,
      ),
      CodeLine(
        'print("Score: " + score)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson7NoteJoinScore,
      ),
    ],
    // From top to bottom: the ✗ line's error (the last line of Python's
    // message, copied exactly), then what each ✓ line shows. Each part was
    // run on its own, since an error stops the program.
    output: const [
      'TypeError: can only concatenate str (not "int") to str',
      '55',
      '10',
      'Score: 10',
    ],
    tip: (l10n) => l10n.lesson7Card7Tip,
  ),

  // 8. .upper() and .lower() only.
  LessonCard(
    title: (l10n) => l10n.lesson7Card8Title,
    speech: (l10n) => l10n.lesson7Card8Speech,
    code: [
      CodeLine('print("cog".upper())', note: (l10n) => l10n.lesson7NoteUpper),
      CodeLine('print("COG".lower())', note: (l10n) => l10n.lesson7NoteLower),
    ],
    output: const ['COG', 'cog'],
    tip: (l10n) => l10n.lesson7Card8Tip,
  ),

  // 9. Recap: every string tool with a tiny example.
  LessonCard(
    title: (l10n) => l10n.lesson7Card9Title,
    speech: (l10n) => l10n.lesson7Card9Speech,
    code: [
      CodeLine(
        'print("Hi, " + "Cog")',
        note: (l10n) => l10n.lesson7NoteRecapJoin,
      ),
      CodeLine('print("Ha" * 3)', note: (l10n) => l10n.lesson7NoteRecapRepeat),
      CodeLine('print(len("Cog"))', note: (l10n) => l10n.lesson7NoteRecapLen),
      CodeLine('print("Cog"[0])', note: (l10n) => l10n.lesson7NoteRecapIndex),
      CodeLine('print(str(10))', note: (l10n) => l10n.lesson7NoteRecapStr),
      CodeLine(
        'print("cog".upper())',
        note: (l10n) => l10n.lesson7NoteRecapUpper,
      ),
      CodeLine(
        'print("COG".lower())',
        note: (l10n) => l10n.lesson7NoteRecapLower,
      ),
    ],
    output: const ['Hi, Cog', 'HaHaHa', '3', 'C', '10', 'COG', 'cog'],
    tip: (l10n) => l10n.lesson7Card9Tip,
  ),
];
