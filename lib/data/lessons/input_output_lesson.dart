import '../../models/lesson_card.dart';

/// Lesson 9: Input and Output. Explanation cards (the quiz is in
/// lib/data/quizzes/input_output_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson9Card… for
/// cards, lesson9Note… for the "← arrow notes"). Code and `output` are the
/// same in every language. Built exactly like Lesson 8 (lists_lesson.dart).
///
/// Code with `input()` needs a person to type. `output` holds what a
/// terminal shows: the question exactly as printed (with its space at the
/// end), and `typed` holds what the person types after it on that row
/// (shown in a mint "typed" chip). Every card was run in real Python 3.13
/// with these answers fed in, including the exact error messages.
final List<LessonCard> inputOutputLessonCards = [
  // 1. Programs talk to people: output (print) and input (input).
  LessonCard(
    title: (l10n) => l10n.lesson9Card1Title,
    speech: (l10n) => l10n.lesson9Card1Speech,
    code: [
      CodeLine('print("Hello!")', note: (l10n) => l10n.lesson9NotePrintHello),
      CodeLine(
        'name = input("Your name? ")',
        note: (l10n) => l10n.lesson9NoteInputName,
      ),
    ],
    output: const ['Hello!', 'Your name? '],
    typed: const {1: 'Ana'},
    tip: (l10n) => l10n.lesson9Card1Tip,
  ),

  // 2. print() with commas adds spaces; + (Lesson 7) does not.
  LessonCard(
    title: (l10n) => l10n.lesson9Card2Title,
    speech: (l10n) => l10n.lesson9Card2Speech,
    code: [
      CodeLine('print("Score:", 10)', note: (l10n) => l10n.lesson9NoteComma),
      CodeLine(
        'print("Score: " + str(10))',
        note: (l10n) => l10n.lesson9NotePlus,
      ),
      CodeLine(
        'print("HP", 50, "of", 100)',
        note: (l10n) => l10n.lesson9NoteMany,
      ),
    ],
    output: const ['Score: 10', 'Score: 10', 'HP 50 of 100'],
    tip: (l10n) => l10n.lesson9Card2Tip,
  ),

  // 3. input(): the program waits; Ana types a name.
  LessonCard(
    title: (l10n) => l10n.lesson9Card3Title,
    speech: (l10n) => l10n.lesson9Card3Speech,
    code: [
      CodeLine(
        'name = input("Your name? ")',
        note: (l10n) => l10n.lesson9NoteAsk,
      ),
    ],
    output: const ['Your name? '],
    typed: const {0: 'Ana'},
    tip: (l10n) => l10n.lesson9Card3Tip,
  ),

  // 4. Using what they typed: join with + (Lesson 7).
  LessonCard(
    title: (l10n) => l10n.lesson9Card4Title,
    speech: (l10n) => l10n.lesson9Card4Speech,
    code: [
      CodeLine(
        'name = input("Your name? ")',
        note: (l10n) => l10n.lesson9NoteNameGets,
      ),
      CodeLine('print("Hi, " + name)', note: (l10n) => l10n.lesson9NoteHiName),
    ],
    output: const ['Your name? ', 'Hi, Ana'],
    typed: const {0: 'Ana'},
    tip: (l10n) => l10n.lesson9Card4Tip,
  ),

  // 5. Big warning: input() always gives text, so age + 1 is an error (✗).
  LessonCard(
    title: (l10n) => l10n.lesson9Card5Title,
    speech: (l10n) => l10n.lesson9Card5Speech,
    code: [
      CodeLine('age = input("Age? ")', note: (l10n) => l10n.lesson9NoteAgeText),
      CodeLine('print(type(age))', note: (l10n) => l10n.lesson9NoteTypeStr),
      CodeLine(
        'print(age + 1)',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson9NoteAgeError,
      ),
    ],
    // The last line of Python's error, copied exactly.
    output: const [
      'Age? ',
      "<class 'str'>",
      'TypeError: can only concatenate str (not "int") to str',
    ],
    typed: const {0: '12'},
    tip: (l10n) => l10n.lesson9Card5Tip,
  ),

  // 6. int() turns the text into a whole number (✓).
  LessonCard(
    title: (l10n) => l10n.lesson9Card6Title,
    speech: (l10n) => l10n.lesson9Card6Speech,
    code: [
      CodeLine(
        'age = int(input("Age? "))',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson9NoteIntInput,
      ),
      CodeLine(
        'print(age + 1)',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson9NoteAgePlus,
      ),
    ],
    output: const ['Age? ', '13'],
    typed: const {0: '12'},
    tip: (l10n) => l10n.lesson9Card6Tip,
  ),

  // 7. int() needs a real number: int("abc") is an error (✗), "42" is fine
  // (✓). Each part was run on its own, since an error stops the program.
  LessonCard(
    title: (l10n) => l10n.lesson9Card7Title,
    speech: (l10n) => l10n.lesson9Card7Speech,
    code: [
      CodeLine(
        'print(int("abc"))',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson9NoteIntAbc,
      ),
      CodeLine(
        'print(int("42"))',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson9NoteInt42,
      ),
    ],
    output: const [
      "ValueError: invalid literal for int() with base 10: 'abc'",
      '42',
    ],
    tip: (l10n) => l10n.lesson9Card7Tip,
  ),

  // 8. Putting it together: name and age, then a message.
  LessonCard(
    title: (l10n) => l10n.lesson9Card8Title,
    speech: (l10n) => l10n.lesson9Card8Speech,
    code: [
      CodeLine(
        'name = input("Name? ")',
        note: (l10n) => l10n.lesson9NoteAskName,
      ),
      CodeLine(
        'age = int(input("Age? "))',
        note: (l10n) => l10n.lesson9NoteAskAge,
      ),
      CodeLine('print("Hi, " + name)', note: (l10n) => l10n.lesson9NoteSayHi),
      CodeLine(
        'print("Next year:", age + 1)',
        note: (l10n) => l10n.lesson9NoteNextYear,
      ),
    ],
    output: const ['Name? ', 'Age? ', 'Hi, Ana', 'Next year: 13'],
    typed: const {0: 'Ana', 1: '12'},
    tip: (l10n) => l10n.lesson9Card8Tip,
  ),

  // 9. Recap: print, input, int.
  LessonCard(
    title: (l10n) => l10n.lesson9Card9Title,
    speech: (l10n) => l10n.lesson9Card9Speech,
    code: [
      CodeLine(
        'print("Score:", 10)',
        note: (l10n) => l10n.lesson9NoteRecapPrint,
      ),
      CodeLine(
        'name = input("Name? ")',
        note: (l10n) => l10n.lesson9NoteRecapInput,
      ),
      CodeLine(
        'age = int(input("Age? "))',
        note: (l10n) => l10n.lesson9NoteRecapInt,
      ),
      CodeLine('print(age + 1)', note: (l10n) => l10n.lesson9NoteRecapMath),
    ],
    output: const ['Score: 10', 'Name? ', 'Age? ', '13'],
    typed: const {1: 'Ana', 2: '12'},
    tip: (l10n) => l10n.lesson9Card9Tip,
  ),
];
