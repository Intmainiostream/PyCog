import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/models/lesson_card.dart';
import 'package:pycog/models/quiz.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';
import 'package:pycog/widgets/output_box.dart';

import 'test_helpers.dart';

final listsLesson = lessons.firstWhere((l) => l.id == 'lists');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// The exact last line Python 3.13 prints for items[3] on a 3-item list.
const indexError = 'IndexError: list index out of range';

/// The backpack, written on 3 lines (one line is too wide for a phone).
const backpack = [
  'items = ["sword",',
  '         "shield",',
  '         "potion"]',
];

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson8Card1Title,
  en.lesson8Card2Title,
  en.lesson8Card3Title,
  en.lesson8Card4Title,
  en.lesson8Card5Title,
  en.lesson8Card6Title,
  en.lesson8Card7Title,
  en.lesson8Card8Title,
  en.lesson8Card9Title,
  en.lesson8Card10Title,
];

/// Every lesson before Lesson 8 passed, so Lesson 8 is open.
final passedBefore = {
  for (final l in lessons.take(lessons.indexOf(listsLesson)))
    'progress.stars.${l.id}': 1,
};

/// How Python prints a list of strings: ['a', 'b'].
String pyList(List<String> items) => '[${items.map((s) => "'$s'").join(', ')}]';

Future<void> scrollToLesson8(WidgetTester tester) async {
  final node = find.byKey(const ValueKey('lesson-node-lists'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<SettingsController> openLesson8(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
  double systemScale = 1.0,
  Map<String, Object> extra = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({...passedBefore, ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  await openTrail(tester); // app opens on the home screen
  await scrollToLesson8(tester);
  await tester.tap(find.byKey(const ValueKey('lesson-node-lists')));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

String rightAnswer(QuizQuestion q) => q.answers[q.correctIndex].label(en);

List<String> codeLines(LessonCard card) => [for (final l in card.code) l.code];

void main() {
  group('Lesson 8 content', () {
    test('10 cards, 6 multiple-choice questions, and a game', () {
      expect(listsLesson.title(en), 'Lists');
      expect(listsLesson.cards, hasLength(10));
      expect(listsLesson.quiz, hasLength(6));
      expect(listsLesson.hasGame, isTrue); // see game8_test.dart
      expect(
        listsLesson.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
      // Right after Lesson 7.
      expect(lessons.indexOf(listsLesson), 7);
      expect(lessons[6].id, 'strings');
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in listsLesson.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('every card shows the same backpack, on 3 lines', () {
      for (final (i, card) in listsLesson.cards.indexed) {
        final code = codeLines(card);
        final at = code.indexOf(backpack.first);
        expect(at, isNot(-1), reason: 'card ${i + 1}');
        expect(code.sublist(at, at + 3), backpack, reason: 'card ${i + 1}');
      }
      // On one line, it is exactly the list from the lesson plan.
      expect(
        backpack.map((l) => l.trim()).join(' '),
        'items = ["sword", "shield", "potion"]',
      );
      // The items line up under the first item.
      expect(backpack[1].indexOf('"'), backpack[0].indexOf('"'));
    });

    test('other indents are 4 spaces per level', () {
      for (final card in listsLesson.cards) {
        for (final line in card.code.where((l) => !backpack.contains(l.code))) {
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test('output boxes match real Python (checked by running the code)', () {
      final outputs = [for (final c in listsLesson.cards) c.output];
      expect(outputs, [
        <String>[], // card 1 prints nothing
        ["['sword', 'shield', 'potion']", '[10, 25, 7]'],
        ['sword', 'potion'],
        [indexError, 'potion'],
        ["['axe', 'shield', 'potion']"],
        ['3', '5'],
        ["['sword', 'shield', 'potion', 'map']", '4'],
        ['sword', 'shield', 'potion'],
        ['True', 'False', 'You can heal!'],
        ['sword', '4', 'True', 'axe', 'shield', 'potion', 'map'],
      ]);
    });

    test('a card has an output box exactly when its code prints', () {
      for (final (i, card) in listsLesson.cards.indexed) {
        final prints = card.code.any((l) => l.code.contains('print('));
        expect(card.output.isNotEmpty, prints, reason: 'card ${i + 1}');
      }
    });

    test('outputs agree with the same list steps done again in Dart', () {
      List<String> fresh() => ['sword', 'shield', 'potion'];
      final cards = listsLesson.cards;
      expect(cards[1].output.first, pyList(fresh()));
      expect(cards[2].output, [fresh()[0], fresh()[2]]);
      expect(cards[3].output.last, fresh()[fresh().length - 1]);
      expect(cards[4].output, [pyList(fresh()..[0] = 'axe')]);
      expect(cards[5].output, ['${fresh().length}', '${'sword'.length}']);
      final added = fresh()..add('map');
      expect(cards[6].output, [pyList(added), '${added.length}']);
      expect(cards[7].output, fresh());
      expect(cards[8].output.take(2), [
        '${fresh().contains('potion')}'.replaceFirst('t', 'T'),
        '${fresh().contains('map')}'.replaceFirst('f', 'F'),
      ]);
      // Recap: pick, change, add, count, check, then loop.
      final recap = fresh();
      final picked = recap[0];
      recap[0] = 'axe';
      recap.add('map');
      expect(cards[9].output, [
        picked,
        '${recap.length}',
        recap.contains('map') ? 'True' : 'False',
        ...recap,
      ]);
    });

    test('card 1 connects to variables from Lesson 1', () {
      final card = listsLesson.cards[0];
      expect(codeLines(card).first, 'robot = "Cog"');
      expect(card.speech(en), contains('Lesson 1'));
    });

    test('card 3 warns that counting starts at 0 (Lessons 4 and 7)', () {
      final card = listsLesson.cards[2];
      expect(card.title(en), contains('Warning'));
      expect(card.title(en), contains('[0]'));
      expect(card.speech(en), contains('"Cog"[0]'));
      expect(card.speech(en), contains('Lesson 7'));
      expect(card.speech(en), contains('Lesson 4'));
    });

    test('card 4: ✗ items[3] with the exact error, ✓ items[2]', () {
      final card = listsLesson.cards[3];
      final bad = card.code.singleWhere((l) => l.mark == CodeMark.bad);
      final good = card.code.singleWhere((l) => l.mark == CodeMark.good);
      expect(bad.code, 'print(items[3])');
      expect(good.code, 'print(items[2])');
      expect(card.output, [indexError, 'potion']);
    });

    test('cards 5 to 9 cover change, len, append, for and in', () {
      final cards = listsLesson.cards;
      expect(codeLines(cards[4]), contains('items[0] = "axe"'));
      expect(cards[5].speech(en), contains('Lesson 7'));
      expect(codeLines(cards[6]), contains('items.append("map")'));
      expect(codeLines(cards[6]), contains('print(len(items))'));
      expect(codeLines(cards[7]), contains('for item in items:'));
      expect(cards[7].speech(en), contains('Lesson 4'));
      expect(cards[7].speech(en), contains('range()'));
      expect(codeLines(cards[8]), contains('if "potion" in items:'));
      expect(codeLines(cards[8]), contains('    print("You can heal!")'));
      expect(cards[8].speech(en), contains('Lesson 3'));
    });

    test('the quiz covers the six required topics, with no notes', () {
      for (final q in listsLesson.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
        expect(q.code.every((l) => l.mark == CodeMark.none), isTrue);
      }
      QuizQuestion withCode(String code) =>
          listsLesson.quiz.singleWhere((q) => codeOf(q).contains(code));
      final items = ['sword', 'shield', 'potion'];

      // Each right answer, worked out again in Dart (and checked in Python).
      expect(rightAnswer(withCode('items[1]')), '`${items[1]}`');
      // len(items) with no append first.
      final len = listsLesson.quiz.singleWhere(
        (q) =>
            codeOf(q).contains('print(len(items))') &&
            !codeOf(q).contains('append'),
      );
      expect(rightAnswer(len), '`${items.length}`');
      expect(
        rightAnswer(withCode('items.append("map")')),
        '`${[...items, 'map'].length}`',
      );
      expect(rightAnswer(withCode('for item in bag:')), '`map`, then `key`');
      expect(rightAnswer(withCode('"sword" in items')), '`True`');
      expect(items.contains('sword'), isTrue);
      // Why items[3] is an error on a 3-item list.
      final tooFar = withCode('print(items[3])');
      expect(tooFar.prompt(en), contains('error'));
      expect(rightAnswer(tooFar), contains('[3]'));
      expect(rightAnswer(tooFar), contains('[2]'));
      // Every quiz with the backpack writes it on the same 3 lines.
      for (final q in listsLesson.quiz.where(
        (q) => codeOf(q).contains('items'),
      )) {
        expect(q.code.take(3).map((l) => l.code), backpack);
      }
    });

    test('no two answers in one question are the same', () {
      for (final q in listsLesson.quiz) {
        final labels = q.answers.map((a) => a.label(en)).toList();
        expect(labels.toSet(), hasLength(labels.length));
        for (final a in q.answers.where((a) => !a.correct)) {
          expect(a.whyWrong, isNotNull);
        }
      }
    });

    test('every Lesson 8 card and question has a Tagalog version', () {
      expect(listsLesson.title(tl), isNot(listsLesson.title(en)));
      for (final card in listsLesson.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
        expect(card.tip!(tl), isNot(card.tip!(en)));
      }
      for (final q in listsLesson.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
        expect(q.explanation(tl), isNot(q.explanation(en)));
      }
      expect(listsLesson.perfectQuizMessage!(en), contains('list master'));
      expect(listsLesson.perfectQuizMessage!(tl), contains('List master'));
    });
  });

  testWidgets('Lesson 8 is locked until Lesson 7 has a star', (tester) async {
    SharedPreferences.setMockInitialValues(
      {...passedBefore}..remove('progress.stars.strings'),
    );
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    await scrollToLesson8(tester);
    expect(find.text(en.lesson8Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-node-lists')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('10 cards: progress, Back, Next, then Next: Quiz', (
    tester,
  ) async {
    await openLesson8(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/10'), findsOneWidget);

    for (var i = 1; i < 10; i++) {
      await tapText(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/10'), findsOneWidget);
    }
    await tapText(tester, en.lessonBack);
    expect(find.text(titlesEn[8]), findsOneWidget);
    await tapText(tester, en.lessonNext);

    await tapText(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(textHas(en.quiz8Q1Prompt), findsOneWidget);
  });

  testWidgets('Card 1 has no output; card 4 shows the exact error', (
    tester,
  ) async {
    final settings = await openLesson8(tester);
    expect(find.byType(OutputBox), findsNothing); // card 1

    for (var i = 0; i < 3; i++) {
      await tapText(tester, en.lessonNext);
    }
    expect(find.text(titlesEn[3]), findsOneWidget); // card 4
    expect(printedLines(tester), listsLesson.cards[3].output);
    expect(textHas(en.lesson8NoteNoItem3), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.lesson8Card4Title), findsOneWidget);
    expect(textHas(tl.lesson8NoteNoItem3), findsOneWidget);
    // Code and output stay the same in Tagalog.
    expect(printedLines(tester), listsLesson.cards[3].output);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'print(items[3])',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Card 7: the 4-item list shows in full, even if it wraps', (
    tester,
  ) async {
    await openLesson8(tester, size: const Size(360, 640));
    for (var i = 0; i < 6; i++) {
      await tapText(tester, en.lessonNext);
    }
    expect(find.text(titlesEn[6]), findsOneWidget);
    expect(printedLines(tester), listsLesson.cards[6].output);
  });

  testWidgets('Perfect quiz: list master, 3 stars, game button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passedBefore);
    final settings = await SettingsController.load();
    final progress = await ProgressController.load();
    final position = lessons.indexOf(listsLesson) + 1; // Lesson 8
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: QuizScreen(
          lesson: listsLesson,
          lessonNumber: position,
          settings: settings,
          progress: progress,
          random: math.Random(8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < listsLesson.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${listsLesson.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == listsLesson.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson8Perfect), findsOneWidget);
    expect(progress.bestStars('lists'), 3);
    // The next lesson opens, if there is one (counted from the list).
    if (position < lessons.length) {
      expect(find.text(en.resultsUnlocked(position + 1)), findsOneWidget);
      expect(progress.unlockedCount(lessons), position + 1);
    } else {
      expect(find.textContaining('is now open'), findsNothing);
      expect(progress.unlockedCount(lessons), lessons.length);
    }
    expect(find.text(en.resultsPlayGame), findsOneWidget); // game8_test
  });

  // All 10 cards on small phones with the biggest text, both languages.
  // Any overflow throws and fails the test.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All 10 cards fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await openLesson8(
          tester,
          size: size,
          systemScale: 1.5,
          extra: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 10; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          if (i < 9) await tapText(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
