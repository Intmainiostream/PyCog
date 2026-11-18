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

final io = lessons.firstWhere((l) => l.id == 'input_output');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// The exact last lines Python 3.13 prints for these errors.
const typeError = 'TypeError: can only concatenate str (not "int") to str';
const valueError = "ValueError: invalid literal for int() with base 10: 'abc'";

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson9Card1Title,
  en.lesson9Card2Title,
  en.lesson9Card3Title,
  en.lesson9Card4Title,
  en.lesson9Card5Title,
  en.lesson9Card6Title,
  en.lesson9Card7Title,
  en.lesson9Card8Title,
  en.lesson9Card9Title,
];

/// Every lesson before Lesson 9 passed, so Lesson 9 is open.
final passedBefore = {
  for (final l in lessons.take(lessons.indexOf(io)))
    'progress.stars.${l.id}': 1,
};

/// What a terminal shows for a card: each printed row, with the typed
/// answer (and Enter) right after the question on its row.
List<String> terminal(LessonCard card) => [
  for (final (i, row) in card.output.indexed) row + (card.typed[i] ?? ''),
];

Future<void> scrollToLesson9(WidgetTester tester) async {
  final node = find.byKey(const ValueKey('lesson-node-input_output'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<SettingsController> openLesson9(
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
  await scrollToLesson9(tester);
  await tester.tap(find.byKey(const ValueKey('lesson-node-input_output')));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Every text in the output box after its "Output" label, top to bottom:
/// for a typed row, the question and then the typed answer; at the end,
/// the "typed by the person" key. A long printed line that wrapped onto
/// more rows (which start with the wrap indent) is joined back together.
List<String> outputTexts(WidgetTester tester) {
  final texts = <String>[];
  final indent = ' ' * outputWrapIndent;
  for (final text in outputRows(tester).map((t) => t.data!)) {
    if (text.startsWith(indent) && texts.isNotEmpty) {
      texts.last = '${texts.last} ${text.substring(outputWrapIndent)}';
    } else {
      texts.add(text);
    }
  }
  return texts;
}

/// What [outputTexts] should be for [card].
List<String> expectedTexts(LessonCard card, AppLocalizations l10n) => [
  for (final (i, row) in card.output.indexed) ...[row, ?card.typed[i]],
  if (card.typed.isNotEmpty) l10n.lesson9TypedLabel,
];

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

String rightAnswer(QuizQuestion q) => q.answers[q.correctIndex].label(en);

List<String> codeLines(LessonCard card) => [for (final l in card.code) l.code];

void main() {
  group('Lesson 9 content', () {
    test('9 cards, 6 multiple-choice questions, no game yet', () {
      expect(io.title(en), 'Input and Output');
      expect(io.cards, hasLength(9));
      expect(io.quiz, hasLength(6));
      expect(io.hasGame, isFalse);
      expect(
        io.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
      // Right after Lesson 8.
      expect(lessons.indexOf(io), 8);
      expect(lessons[7].id, 'lists');
    });

    test('every code line has an arrow note; indents are 4 spaces', () {
      for (final card in io.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test(
      'what the terminal shows matches real Python (typed answers fed in)',
      () {
        // Each row: what was printed, plus what the person typed on it.
        expect(
          [for (final c in io.cards) terminal(c)],
          [
            ['Hello!', 'Your name? Ana'],
            ['Score: 10', 'Score: 10', 'HP 50 of 100'],
            ['Your name? Ana'],
            ['Your name? Ana', 'Hi, Ana'],
            ['Age? 12', "<class 'str'>", typeError],
            ['Age? 12', '13'],
            [valueError, '42'],
            ['Name? Ana', 'Age? 12', 'Hi, Ana', 'Next year: 13'],
            ['Score: 10', 'Name? Ana', 'Age? 12', '13'],
          ],
        );
      },
    );

    test('a typed answer follows each input() question, one per input()', () {
      for (final (i, card) in io.cards.indexed) {
        final inputs = card.code
            .map((l) => 'input('.allMatches(l.code).length)
            .fold(0, (a, b) => a + b);
        expect(card.typed, hasLength(inputs), reason: 'card ${i + 1}');
        for (final MapEntry(key: row, value: answer) in card.typed.entries) {
          expect(row, lessThan(card.output.length));
          // The row is the question exactly as printed: it ends with "? ".
          expect(card.output[row], endsWith('? '), reason: 'card ${i + 1}');
          expect(answer.trim(), answer);
          expect(answer, isNotEmpty);
        }
      }
    });

    test('every card prints or asks, so every card has an output box', () {
      for (final card in io.cards) {
        final shows = card.code.any(
          (l) => l.code.contains('print(') || l.code.contains('input('),
        );
        expect(shows, isTrue);
        expect(card.output, isNotEmpty);
      }
    });

    test('lessons before Lesson 9 never use typed answers', () {
      for (final lesson in lessons.take(lessons.indexOf(io))) {
        for (final card in lesson.cards) {
          expect(card.typed, isEmpty, reason: lesson.id);
        }
      }
    });

    test('outputs agree with the same steps done again in Dart', () {
      String printed(List<Object> things) => things.join(' '); // print(a, b)
      final cards = io.cards;
      expect(cards[1].output, [
        printed(['Score:', 10]),
        'Score: ${10}',
        printed(['HP', 50, 'of', 100]),
      ]);
      expect(cards[3].output.last, 'Hi, ${cards[3].typed[0]}');
      expect(cards[5].output.last, '${int.parse(cards[5].typed[0]!) + 1}');
      expect(cards[6].output.last, '${int.parse('42')}');
      expect(cards[7].output.skip(2), [
        'Hi, ${cards[7].typed[0]}',
        printed(['Next year:', int.parse(cards[7].typed[1]!) + 1]),
      ]);
      expect(cards[8].output.last, '${int.parse(cards[8].typed[2]!) + 1}');
    });

    test('card 2 compares commas with + from Lesson 7', () {
      final card = io.cards[1];
      expect(codeLines(card).first, 'print("Score:", 10)');
      expect(codeLines(card), contains('print("Score: " + str(10))'));
      expect(card.speech(en), contains('Lesson 7'));
    });

    test('card 3: input() and the program waits for Enter', () {
      final card = io.cards[2];
      expect(codeLines(card), ['name = input("Your name? ")']);
      expect(card.typed, {0: 'Ana'});
      expect(card.speech(en), contains('Enter'));
    });

    test('card 5: input() always gives text; ✗ age + 1, exact error', () {
      final card = io.cards[4];
      expect(card.title(en), contains('Warning'));
      expect(card.typed, {0: '12'});
      final bad = card.code.singleWhere((l) => l.mark == CodeMark.bad);
      expect(bad.code, 'print(age + 1)');
      expect(card.output.last, typeError);
      expect(card.output, contains("<class 'str'>"));
      expect(card.speech(en), contains('`"5" + 5`'));
      expect(card.speech(en), contains('Lesson 7'));
    });

    test('card 6: ✓ int(input()); float() and Lesson 2 in one line', () {
      final card = io.cards[5];
      expect(card.code.map((l) => l.mark), everyElement(CodeMark.good));
      expect(codeLines(card).first, 'age = int(input("Age? "))');
      expect(card.output.last, '13');
      expect(card.speech(en), contains('`float()`'));
      expect(card.speech(en), contains('Lesson 2'));
    });

    test('card 7: int("abc") gives the exact ValueError', () {
      final card = io.cards[6];
      expect(card.code.first.code, 'print(int("abc"))');
      expect(card.code.first.mark, CodeMark.bad);
      expect(card.output.first, valueError);
    });

    test('card 8 uses input, int, print, + and a comma', () {
      final code = codeLines(io.cards[7]).join('\n');
      for (final part in ['input(', 'int(', 'print(', ' + ', '",']) {
        expect(code, contains(part));
      }
      expect(io.cards[7].typed, {0: 'Ana', 1: '12'});
    });

    test('the quiz covers the six required topics, with no notes', () {
      for (final q in io.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
        expect(q.code.every((l) => l.mark == CodeMark.none), isTrue);
      }
      QuizQuestion byPrompt(String text) =>
          io.quiz.singleWhere((q) => q.prompt(en).contains(text));
      QuizQuestion withCode(String code) =>
          io.quiz.singleWhere((q) => codeOf(q) == code);

      // What type input() always gives.
      expect(rightAnswer(byPrompt('input()')), '`str`');
      // print("Score:", 10), worked out again in Dart.
      expect(
        rightAnswer(withCode('print("Score:", 10)')),
        '`${['Score:', 10].join(' ')}`',
      );
      // Why age + 1 is an error.
      final why = byPrompt('Why does this give an error?');
      expect(codeOf(why), 'age = input("Age? ")\nprint(age + 1)');
      expect(rightAnswer(why), contains('text'));
      // What int("5") gives.
      expect(rightAnswer(byPrompt('int("5")')), '`${int.parse('5')}`');
      // Which line fixes the error.
      final fix = byPrompt('fix the error');
      expect(rightAnswer(fix), '`int(input("Age? "))`');
      // "Hi, " + name when name is "Ana".
      const name = 'Ana';
      expect(
        rightAnswer(withCode('name = "Ana"\nprint("Hi, " + name)')),
        '`Hi, $name`',
      );
    });

    test('no two answers in one question are the same', () {
      for (final q in io.quiz) {
        final labels = q.answers.map((a) => a.label(en)).toList();
        expect(labels.toSet(), hasLength(labels.length));
        for (final a in q.answers.where((a) => !a.correct)) {
          expect(a.whyWrong, isNotNull);
        }
      }
    });

    test('every Lesson 9 card and question has a Tagalog version', () {
      expect(io.title(tl), isNot(io.title(en)));
      expect(tl.lesson9TypedLabel, isNot(en.lesson9TypedLabel));
      for (final card in io.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
        expect(card.tip!(tl), isNot(card.tip!(en)));
      }
      for (final q in io.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
        expect(q.explanation(tl), isNot(q.explanation(en)));
      }
      expect(io.perfectQuizMessage!(en), contains('input master'));
      expect(io.perfectQuizMessage!(tl), contains('Input master'));
    });
  });

  group('Output box: typed answers', () {
    Future<void> pumpBox(
      WidgetTester tester,
      List<String> lines, {
      Map<int, String> typed = const {},
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: OutputBox(lines: lines, typed: typed),
          ),
        ),
      );
    }

    testWidgets('without typed answers: no chip and no key', (tester) async {
      await pumpBox(tester, ['Hello!', 'Score: 10']);
      expect(find.byIcon(Icons.keyboard_rounded), findsNothing);
      expect(find.text(en.lesson9TypedLabel), findsNothing);
      expect(outputTexts(tester), ['Hello!', 'Score: 10']);
    });

    testWidgets('a typed answer sits after the question, in a chip', (
      tester,
    ) async {
      await pumpBox(tester, ['Your name? ', 'Hi, Ana'], typed: {0: 'Ana'});
      final chip = find.byKey(const ValueKey('typed-0'));
      expect(chip, findsOneWidget);
      final answer = find.descendant(of: chip, matching: find.text('Ana'));
      expect(answer, findsOneWidget);
      // Same row as the question, to its right.
      final question = tester.getRect(find.text('Your name? '));
      final typed = tester.getRect(chip);
      expect(typed.left, greaterThanOrEqualTo(question.right - 0.5));
      expect(typed.center.dy, closeTo(question.center.dy, 4));
      // A different color from what the program printed.
      final printed = tester.widget<Text>(find.text('Hi, Ana')).style!.color;
      final typedColor = tester.widget<Text>(answer).style!.color;
      expect(typedColor, AppColors.tealDark);
      expect(typedColor, isNot(printed));
      // A keyboard icon in the chip, and the key under the rows.
      expect(
        find.descendant(
          of: chip,
          matching: find.byIcon(Icons.keyboard_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text(en.lesson9TypedLabel), findsOneWidget);
    });

    testWidgets('screen readers hear which part was typed', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBox(tester, ['Your name? '], typed: {0: 'Ana'});
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape('Your name? Ana (${en.lesson9TypedLabel})')),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  testWidgets('Lesson 9 is locked until Lesson 8 has a star', (tester) async {
    SharedPreferences.setMockInitialValues(
      {...passedBefore}..remove('progress.stars.lists'),
    );
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    await scrollToLesson9(tester);
    expect(find.text(en.lesson9Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-node-input_output')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('9 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson9(tester);
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
    // The prompt has code (`input()`), so look for it without backticks.
    expect(textHas(en.quiz9Q1Prompt.replaceAll('`', '')), findsOneWidget);
  });

  testWidgets('Every card shows its rows and typed answers, both languages', (
    tester,
  ) async {
    final settings = await openLesson9(tester);
    for (final lang in [en, tl]) {
      if (lang == tl) {
        settings.setLocale(SettingsController.tagalog);
        await tester.pumpAndSettle();
        // Back to card 1.
        for (var i = 0; i < 8; i++) {
          await tapText(tester, tl.lessonBack);
        }
      }
      for (var i = 0; i < 9; i++) {
        final card = io.cards[i];
        expect(outputTexts(tester), expectedTexts(card, lang), reason: '$i');
        if (i < 8) await tapText(tester, lang.lessonNext);
      }
    }
    // Code stays the same in Tagalog.
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'print(age + 1)',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Perfect quiz: input master, 3 stars, no game button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passedBefore);
    final settings = await SettingsController.load();
    final progress = await ProgressController.load();
    final position = lessons.indexOf(io) + 1; // Lesson 9
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: QuizScreen(
          lesson: io,
          lessonNumber: position,
          settings: settings,
          progress: progress,
          random: math.Random(9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < io.quiz.length; q++) {
      final key = find.byKey(ValueKey('answer-$q-${io.quiz[q].correctIndex}'));
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == io.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson9Perfect), findsOneWidget);
    expect(progress.bestStars('input_output'), 3);
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
        await openLesson9(
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
