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

final strings = lessons.firstWhere((l) => l.id == 'strings');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// The exact last line Python 3.13 prints for `print("5" + 5)`.
const typeError = 'TypeError: can only concatenate str (not "int") to str';

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson7Card1Title,
  en.lesson7Card2Title,
  en.lesson7Card3Title,
  en.lesson7Card4Title,
  en.lesson7Card5Title,
  en.lesson7Card6Title,
  en.lesson7Card7Title,
  en.lesson7Card8Title,
  en.lesson7Card9Title,
];

/// Every lesson before Lesson 7 passed, so Lesson 7 is open.
final passedBefore = {
  for (final l in lessons.take(lessons.indexOf(strings)))
    'progress.stars.${l.id}': 1,
};

Future<void> scrollToLesson7(WidgetTester tester) async {
  final node = find.byKey(const ValueKey('lesson-node-strings'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<SettingsController> openLesson7(
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
  await scrollToLesson7(tester);
  await tester.tap(find.byKey(const ValueKey('lesson-node-strings')));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

String rightAnswer(QuizQuestion q) => q.answers[q.correctIndex].label(en);

/// The rows shown in the output box, as Text widgets, top to bottom.
List<Text> outputRows(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(OutputBox), matching: find.byType(Text)),
    )
    .skip(1) // the "Output" label
    .toList();

/// The printed lines in the output box, one per row.
List<String> printedLines(WidgetTester tester) =>
    outputRows(tester).map((t) => t.data!).toList();

/// Python's + on two strings, done in Dart.
String join(String a, String b) => a + b;

List<String> codeLines(LessonCard card) => [for (final l in card.code) l.code];

void main() {
  group('Lesson 7 content', () {
    test('9 cards, 6 multiple-choice questions, no game yet', () {
      expect(strings.title(en), 'Strings');
      expect(strings.cards, hasLength(9));
      expect(strings.quiz, hasLength(6));
      expect(strings.hasGame, isFalse);
      expect(
        strings.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
      // Right after Lesson 6.
      expect(lessons.indexOf(strings), 6);
      expect(lessons[5].id, 'math_operators');
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in strings.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('output boxes match real Python (checked by running the code)', () {
      final outputs = [for (final c in strings.cards) c.output];
      expect(outputs, [
        ['Cog', "<class 'str'>"],
        <String>[], // card 2 prints nothing (and its ✗ line is an error)
        ['Hi, Cog', 'Hi,Cog'],
        ['HaHaHa', '=========='],
        ['3', '6'],
        ['C', 'o', 'g'],
        [typeError, '55', '10', 'Score: 10'],
        ['COG', 'cog'],
        ['Hi, Cog', 'HaHaHa', '3', 'C', '10', 'COG', 'cog'],
      ]);
    });

    test('a card has an output box exactly when its code prints', () {
      for (final (i, card) in strings.cards.indexed) {
        final prints = card.code.where((l) => l.code.contains('print(')).length;
        expect(card.output, hasLength(prints), reason: 'card ${i + 1}');
      }
    });

    test('outputs agree with the same string tools done again in Dart', () {
      expect(strings.cards[2].output, [
        join('Hi, ', 'Cog'),
        join('Hi,', 'Cog'),
      ]);
      expect(strings.cards[3].output, ['Ha' * 3, '=' * 10]);
      expect(strings.cards[4].output, [
        '${'Cog'.length}',
        '${'Hi Cog'.length}',
      ]);
      expect(strings.cards[5].output, ['Cog'[0], 'Cog'[1], 'Cog'[2]]);
      expect(strings.cards[6].output.skip(1), [
        join('5', '5'),
        '${5 + 5}',
        join('Score: ', '${10}'),
      ]);
      expect(strings.cards[7].output, [
        'cog'.toUpperCase(),
        'COG'.toLowerCase(),
      ]);
    });

    test('card 1 connects to str from Lesson 2', () {
      final card = strings.cards[0];
      expect(codeLines(card).first, 'name = "Cog"');
      expect(card.speech(en), contains('Lesson 2'));
      expect(card.output, contains("<class 'str'>"));
    });

    test("card 2: 'Hi' and \"Hi\" are ✓, \"Hi' is ✗", () {
      final card = strings.cards[1];
      expect(codeLines(card), [
        "greeting = 'Hi'",
        'greeting = "Hi"',
        'greeting = "Hi\'',
      ]);
      expect(card.code.map((l) => l.mark), [
        CodeMark.good,
        CodeMark.good,
        CodeMark.bad,
      ]);
    });

    test('card 3: the space inside the quotes matters', () {
      final card = strings.cards[2];
      expect(card.code[0].code, 'print("Hi, " + "Cog")');
      expect(card.code[0].mark, CodeMark.good);
      expect(card.code[1].code, 'print("Hi," + "Cog")');
      expect(card.code[1].mark, CodeMark.bad);
    });

    test('card 4 connects * to Lesson 6; card 6 is a warning about 0', () {
      expect(strings.cards[3].speech(en), contains('Lesson 6'));
      final card6 = strings.cards[5];
      expect(card6.title(en), contains('Warning'));
      expect(card6.speech(en), contains('range(3)'));
      expect(card6.speech(en), contains('Lesson 4'));
    });

    test('card 7: ✗ error with the exact message, then three ✓ fixes', () {
      final card = strings.cards[6];
      expect(card.title(en), contains('Warning'));
      expect(card.code.first.code, 'print("5" + 5)');
      expect(card.code.first.mark, CodeMark.bad);
      expect(card.code.skip(1).map((l) => l.mark), everyElement(CodeMark.good));
      expect(codeLines(card).skip(1), [
        'print("5" + "5")',
        'print(5 + 5)',
        'score = str(10)',
        'print("Score: " + score)',
      ]);
      expect(card.output.first, typeError);
      expect(card.speech(en), contains('`str()` turns a number into text'));
    });

    test('card 8 only uses .upper() and .lower()', () {
      final code = codeLines(strings.cards[7]).join('\n');
      expect(code, contains('.upper()'));
      expect(code, contains('.lower()'));
      expect(RegExp(r'\.\w+\(').allMatches(code), hasLength(2));
    });

    test('the quiz covers the six required topics, with no notes', () {
      for (final q in strings.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
        expect(q.code.every((l) => l.mark == CodeMark.none), isTrue);
      }
      QuizQuestion withCode(String code) =>
          strings.quiz.singleWhere((q) => codeOf(q).contains(code));

      // Each right answer, worked out again in Dart (and checked in Python).
      expect(rightAnswer(withCode('len("Hi Cog")')), '`${'Hi Cog'.length}`');
      expect(rightAnswer(withCode('"Ha" * 3')), '`${'Ha' * 3}`');
      expect(
        rightAnswer(withCode('"Hi, " + "Cog"')),
        '`${join('Hi, ', 'Cog')}`',
      );
      expect(rightAnswer(withCode('"Cog"[0]')), '`${'Cog'[0]}`');
      expect(rightAnswer(withCode('.upper()')), '`${'cog'.toUpperCase()}`');
      // Why "5" + 5 is an error: text and a number do not mix.
      final mix = withCode('print("5" + 5)');
      expect(mix.prompt(en), contains('error'));
      expect(rightAnswer(mix), contains('text'));
      expect(rightAnswer(mix), contains('number'));
    });

    test('no two answers in one question are the same', () {
      for (final q in strings.quiz) {
        final labels = q.answers.map((a) => a.label(en)).toList();
        expect(labels.toSet(), hasLength(labels.length));
        for (final a in q.answers.where((a) => !a.correct)) {
          expect(a.whyWrong, isNotNull);
        }
      }
    });

    test('every Lesson 7 card and question has a Tagalog version', () {
      expect(strings.title(tl), isNot(strings.title(en)));
      for (final card in strings.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
        expect(card.tip!(tl), isNot(card.tip!(en)));
      }
      for (final q in strings.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
        expect(q.explanation(tl), isNot(q.explanation(en)));
      }
      expect(strings.perfectQuizMessage!(en), contains('string master'));
      expect(strings.perfectQuizMessage!(tl), contains('String master'));
    });
  });

  group('Code colors', () {
    bool isString(TextSpan s) => s.style?.color == AppColors.codeString;

    test("'single' and \"double\" quoted strings are both colored", () {
      expect(
        highlightPython("greeting = 'Hi'").where(isString).map((s) => s.text),
        ["'Hi'"],
      );
      expect(
        highlightPython('greeting = "Hi"').where(isString).map((s) => s.text),
        ['"Hi"'],
      );
    });

    test("the wrong \"Hi' is not colored as a string", () {
      expect(highlightPython('greeting = "Hi\'').where(isString), isEmpty);
    });

    test('a quote inside the other kind stays part of one string', () {
      expect(
        highlightPython('print("It\'s Cog")')
            .where(isString)
            .map((s) => s.text),
        ['"It\'s Cog"'],
      );
    });
  });

  testWidgets('Lesson 7 is locked until Lesson 6 has a star', (tester) async {
    SharedPreferences.setMockInitialValues(
      {...passedBefore}..remove('progress.stars.math_operators'),
    );
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    await scrollToLesson7(tester);
    expect(find.text(en.lesson7Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-node-strings')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('9 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson7(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/9'), findsOneWidget);

    for (var i = 1; i < 9; i++) {
      await tapText(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/9'), findsOneWidget);
    }
    await tapText(tester, en.lessonBack);
    expect(find.text(titlesEn[7]), findsOneWidget);
    await tapText(tester, en.lessonNext);

    await tapText(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(textHas(en.quiz7Q1Prompt), findsOneWidget);
  });

  testWidgets('Card 2 has no output box; card 7 shows the exact error', (
    tester,
  ) async {
    final settings = await openLesson7(tester);
    await tapText(tester, en.lessonNext); // card 2
    expect(find.byType(OutputBox), findsNothing);
    expect(textHas(en.lesson7NoteMismatch), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tapText(tester, en.lessonNext);
    }
    expect(find.text(titlesEn[6]), findsOneWidget); // card 7
    // Every printed line, in order (the error copied exactly).
    expect(printedLines(tester), strings.cards[6].output);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.lesson7Card7Title), findsOneWidget);
    expect(textHas(tl.lesson7NoteMixBad), findsOneWidget);
    // Code and output stay the same in Tagalog.
    expect(printedLines(tester), strings.cards[6].output);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'print("5" + 5)',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Perfect quiz: string master, 3 stars, no game button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passedBefore);
    final settings = await SettingsController.load();
    final progress = await ProgressController.load();
    final position = lessons.indexOf(strings) + 1; // Lesson 7
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: QuizScreen(
          lesson: strings,
          lessonNumber: position,
          settings: settings,
          progress: progress,
          random: math.Random(7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < strings.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${strings.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == strings.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson7Perfect), findsOneWidget);
    expect(progress.bestStars('strings'), 3);
    // The next lesson opens, if there is one (counted from the list).
    if (position < lessons.length) {
      expect(find.text(en.resultsUnlocked(position + 1)), findsOneWidget);
      expect(progress.unlockedCount(lessons), position + 1);
    } else {
      expect(find.textContaining('is now open'), findsNothing);
      expect(progress.unlockedCount(lessons), lessons.length);
    }
    expect(find.text(en.resultsPlayGame), findsNothing); // no game yet
  });

  // All 9 cards on small phones with the biggest text, both languages.
  // Any overflow throws and fails the test.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All 9 cards fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await openLesson7(
          tester,
          size: size,
          systemScale: 1.5,
          extra: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 9; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          if (i < 8) await tapText(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
