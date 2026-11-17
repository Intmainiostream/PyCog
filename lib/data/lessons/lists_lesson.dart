import '../../models/lesson_card.dart';

/// Lesson 8: Lists. Explanation cards (the quiz is in
/// lib/data/quizzes/lists_quiz.dart).
///
/// Text lives in lib/l10n/app_en.arb and app_tl.arb (keys lesson8Card… for
/// cards, lesson8Note… for the "← arrow notes"). Code and `output` (what the
/// code prints) are the same in every language. Built exactly like Lesson 7
/// (strings_lesson.dart). Every `output` was checked by running the card's
/// code in real Python 3.13, including the exact error message.
///
/// The backpack list `items = ["sword", "shield", "potion"]` is too wide
/// for a 360px phone on one line, so it is written on 3 lines, with the
/// items lined up under the first one (Python allows this inside [ ]).
List<CodeLine> backpackLines(
  LocalizedText note1,
  LocalizedText note2,
  LocalizedText note3, {
  CodeMark mark = CodeMark.none,
}) => [
  CodeLine('items = ["sword",', mark: mark, note: note1),
  CodeLine('         "shield",', mark: mark, note: note2),
  CodeLine('         "potion"]', mark: mark, note: note3),
];

/// The backpack with "[0] is sword"-style notes (cards 3 to 9).
List<CodeLine> get _numberedBackpack => backpackLines(
  (l10n) => l10n.lesson8NoteItem0,
  (l10n) => l10n.lesson8NoteItem1,
  (l10n) => l10n.lesson8NoteItem2,
);

final List<LessonCard> listsLessonCards = [
  // 1. What is a list? A backpack; one name, many values (Lesson 1).
  // Nothing prints, so there is no output box.
  LessonCard(
    title: (l10n) => l10n.lesson8Card1Title,
    speech: (l10n) => l10n.lesson8Card1Speech,
    code: [
      CodeLine('robot = "Cog"', note: (l10n) => l10n.lesson8NoteOneValue),
      ...backpackLines(
        (l10n) => l10n.lesson8NoteOneName,
        (l10n) => l10n.lesson8NoteManyValues,
        (l10n) => l10n.lesson8NoteInOrder,
      ),
    ],
    tip: (l10n) => l10n.lesson8Card1Tip,
  ),

  // 2. Making a list: [ ], commas; strings and numbers; print(items).
  LessonCard(
    title: (l10n) => l10n.lesson8Card2Title,
    speech: (l10n) => l10n.lesson8Card2Speech,
    code: [
      ...backpackLines(
        (l10n) => l10n.lesson8NoteOpen,
        (l10n) => l10n.lesson8NoteComma,
        (l10n) => l10n.lesson8NoteClose,
      ),
      CodeLine('scores = [10, 25, 7]', note: (l10n) => l10n.lesson8NoteNumbers),
      CodeLine('print(items)', note: (l10n) => l10n.lesson8NoteShowItems),
      CodeLine('print(scores)', note: (l10n) => l10n.lesson8NoteShowScores),
    ],
    output: const ["['sword', 'shield', 'potion']", '[10, 25, 7]'],
    tip: (l10n) => l10n.lesson8Card2Tip,
  ),

  // 3. Big warning: the first item is [0] (like "Cog"[0] in Lesson 7 and
  // range in Lesson 4).
  LessonCard(
    title: (l10n) => l10n.lesson8Card3Title,
    speech: (l10n) => l10n.lesson8Card3Speech,
    code: [
      ..._numberedBackpack,
      CodeLine('print(items[0])', note: (l10n) => l10n.lesson8NotePick0),
      CodeLine('print(items[2])', note: (l10n) => l10n.lesson8NotePick2),
    ],
    output: const ['sword', 'potion'],
    tip: (l10n) => l10n.lesson8Card3Tip,
  ),

  // 4. Big warning: items[3] on 3 items is an error (✗); items[2] is the
  // last item (✓).
  LessonCard(
    title: (l10n) => l10n.lesson8Card4Title,
    speech: (l10n) => l10n.lesson8Card4Speech,
    code: [
      ..._numberedBackpack,
      CodeLine(
        'print(items[3])',
        mark: CodeMark.bad,
        note: (l10n) => l10n.lesson8NoteNoItem3,
      ),
      CodeLine(
        'print(items[2])',
        mark: CodeMark.good,
        note: (l10n) => l10n.lesson8NoteLastItem,
      ),
    ],
    // From top to bottom: the ✗ line's error (the last line of Python's
    // message, copied exactly), then what the ✓ line shows. Each part was
    // run on its own, since an error stops the program.
    output: const ['IndexError: list index out of range', 'potion'],
    tip: (l10n) => l10n.lesson8Card4Tip,
  ),

  // 5. Changing an item.
  LessonCard(
    title: (l10n) => l10n.lesson8Card5Title,
    speech: (l10n) => l10n.lesson8Card5Speech,
    code: [
      ..._numberedBackpack,
      CodeLine('items[0] = "axe"', note: (l10n) => l10n.lesson8NotePutAxe),
      CodeLine('print(items)', note: (l10n) => l10n.lesson8NoteShowAxe),
    ],
    output: const ["['axe', 'shield', 'potion']"],
    tip: (l10n) => l10n.lesson8Card5Tip,
  ),

  // 6. len(): items in a list vs characters in a string (Lesson 7).
  LessonCard(
    title: (l10n) => l10n.lesson8Card6Title,
    speech: (l10n) => l10n.lesson8Card6Speech,
    code: [
      ..._numberedBackpack,
      CodeLine('print(len(items))', note: (l10n) => l10n.lesson8NoteLenItems),
      CodeLine('print(len("sword"))', note: (l10n) => l10n.lesson8NoteLenSword),
    ],
    output: const ['3', '5'],
    tip: (l10n) => l10n.lesson8Card6Tip,
  ),

  // 7. Adding an item with append(), then print and len.
  LessonCard(
    title: (l10n) => l10n.lesson8Card7Title,
    speech: (l10n) => l10n.lesson8Card7Speech,
    code: [
      ..._numberedBackpack,
      CodeLine(
        'items.append("map")',
        note: (l10n) => l10n.lesson8NoteAppendMap,
      ),
      CodeLine('print(items)', note: (l10n) => l10n.lesson8NoteShowFour),
      CodeLine('print(len(items))', note: (l10n) => l10n.lesson8NoteLen4),
    ],
    output: const ["['sword', 'shield', 'potion', 'map']", '4'],
    tip: (l10n) => l10n.lesson8Card7Tip,
  ),

  // 8. for item in items (Lesson 4's for loop, no range needed).
  LessonCard(
    title: (l10n) => l10n.lesson8Card8Title,
    speech: (l10n) => l10n.lesson8Card8Speech,
    code: [
      ..._numberedBackpack,
      CodeLine('for item in items:', note: (l10n) => l10n.lesson8NoteForItem),
      CodeLine('    print(item)', note: (l10n) => l10n.lesson8NotePrintItem),
    ],
    output: const ['sword', 'shield', 'potion'],
    tip: (l10n) => l10n.lesson8Card8Tip,
  ),

  // 9. in gives True/False, used in an if (Lesson 3).
  LessonCard(
    title: (l10n) => l10n.lesson8Card9Title,
    speech: (l10n) => l10n.lesson8Card9Speech,
    code: [
      ..._numberedBackpack,
      CodeLine(
        'print("potion" in items)',
        note: (l10n) => l10n.lesson8NoteHasPotion,
      ),
      CodeLine('print("map" in items)', note: (l10n) => l10n.lesson8NoteHasMap),
      CodeLine(
        'if "potion" in items:',
        note: (l10n) => l10n.lesson8NoteIfPotion,
      ),
      CodeLine(
        '    print("You can heal!")',
        note: (l10n) => l10n.lesson8NoteHeal,
      ),
    ],
    output: const ['True', 'False', 'You can heal!'],
    tip: (l10n) => l10n.lesson8Card9Tip,
  ),

  // 10. Recap: make, pick, change, add, count, check, loop.
  LessonCard(
    title: (l10n) => l10n.lesson8Card10Title,
    speech: (l10n) => l10n.lesson8Card10Speech,
    code: [
      ...backpackLines(
        (l10n) => l10n.lesson8NoteRecapMake,
        (l10n) => l10n.lesson8NoteRecapComma,
        (l10n) => l10n.lesson8NoteRecapClose,
      ),
      CodeLine('print(items[0])', note: (l10n) => l10n.lesson8NoteRecapPick),
      CodeLine('items[0] = "axe"', note: (l10n) => l10n.lesson8NoteRecapChange),
      CodeLine('items.append("map")', note: (l10n) => l10n.lesson8NoteRecapAdd),
      CodeLine('print(len(items))', note: (l10n) => l10n.lesson8NoteRecapLen),
      CodeLine(
        'print("map" in items)',
        note: (l10n) => l10n.lesson8NoteRecapIn,
      ),
      CodeLine('for item in items:', note: (l10n) => l10n.lesson8NoteRecapLoop),
      CodeLine(
        '    print(item)',
        note: (l10n) => l10n.lesson8NoteRecapPrintItem,
      ),
    ],
    output: const ['sword', '4', 'True', 'axe', 'shield', 'potion', 'map'],
    tip: (l10n) => l10n.lesson8Card10Tip,
  ),
];
