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

final math6 = lessons[5];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson6Card1Title,
  en.lesson6Card2Title,
  en.lesson6Card3Title,
  en.lesson6Card4Title,
  en.lesson6Card5Title,
  en.lesson6Card6Title,
  en.lesson6Card7Title,
  en.lesson6Card8Title,
];

/// Lessons 1 to 5 passed, so Lesson 6 is open.
const passed12345 = {
  'progress.stars.variables': 1,
  'progress.stars.data_types': 1,
  'progress.stars.if_statements': 1,
  'progress.stars.loops': 1,
  'progress.stars.functions': 1,
};

Future<void> scrollToLesson6(WidgetTester tester) async {
  final node = find.byKey(const ValueKey('lesson-node-math_operators'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<SettingsController> openLesson6(
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
  SharedPreferences.setMockInitialValues({...passed12345, ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(
      intro: false,
      settings: settings,
      progress: await ProgressController.load(),
    ),
  );
  await tester.pumpAndSettle();
  await openTrail(tester); // app opens on the home screen
  await scrollToLesson6(tester);
  await tester.tap(find.byKey(const ValueKey('lesson-node-math_operators')));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

String rightAnswer(QuizQuestion q) => q.answers[q.correctIndex].label(en);

/// How Python prints a number: a float always keeps its ".0".
String py(num value) => value is double
    ? (value == value.roundToDouble() ? '${value.toInt()}.0' : '$value')
    : '$value';

void main() {
  group('Lesson 6 content', () {
    test('8 cards, 6 multiple-choice questions, and a game', () {
      expect(math6.id, 'math_operators');
      expect(math6.title(en), 'Math Operators');
      expect(math6.cards, hasLength(8));
      expect(math6.quiz, hasLength(6));
      expect(math6.hasGame, isTrue); // see game6_test.dart
      expect(
        math6.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
      expect(lessons.indexOf(math6), 5); // right after Lesson 5
      expect(lessons[4].id, 'functions');
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in math6.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('indents are 4 spaces per level', () {
      for (final card in math6.cards) {
        for (final line in card.code) {
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test('output boxes match real Python (checked by running the code)', () {
      final outputs = [for (final c in math6.cards) c.output];
      expect(outputs, [
        ['5'],
        ['15', '2'],
        ['12', '5.0', "<class 'float'>"],
        ['3', '1'],
        ['8', '6'],
        ['14', '20'],
        ['20', '3', '2', '1'],
        ['9', '5', '14', '3.5', '3', '1', '49'],
      ]);
    });

    test('every card prints something, so every card has an output box', () {
      for (final (i, card) in math6.cards.indexed) {
        expect(card.code.any((l) => l.code.contains('print(')), isTrue);
        final prints = card.code.where((l) => l.code.contains('print(')).length;
        // Card 7's loop prints 3 times from one line; the rest print once
        // per print line.
        if (i != 6) expect(card.output, hasLength(prints), reason: 'card $i');
      }
    });

    test('recap outputs agree with the same math done again in Dart', () {
      // Dart's / also always gives a decimal, ~/ is //, % is the same for
      // positive numbers, and pow is **.
      expect(math6.cards[7].output, [
        py(7 + 2),
        py(7 - 2),
        py(7 * 2),
        py(7 / 2),
        py(7 ~/ 2),
        py(7 % 2),
        py(math.pow(7, 2)),
      ]);
      expect(math6.cards[2].output.take(2), [py(4 * 3), py(10 / 2)]);
    });

    test('card 3 warns that / gives 5.0 and links to float', () {
      final card = math6.cards[2];
      expect(card.title(en), contains('Warning'));
      expect(card.code.map((l) => l.code), contains('print(10 / 2)'));
      expect(card.output, contains('5.0'));
      expect(card.output, isNot(contains('5')));
      expect(card.speech(en), contains('Lesson 2'));
      expect(card.speech(en), contains('`float`'));
    });

    test('card 4 uses 7 robots in teams of 2', () {
      final code = math6.cards[3].code.map((l) => l.code).toList();
      expect(code, ['robots = 7', 'print(robots // 2)', 'print(robots % 2)']);
    });

    test('card 6: ✗ without ( ) gives 14, ✓ with ( ) gives 20', () {
      final card = math6.cards[5];
      expect(card.code[0].code, 'print(2 + 3 * 4)');
      expect(card.code[0].mark, CodeMark.bad);
      expect(card.code[1].code, 'print((2 + 3) * 4)');
      expect(card.code[1].mark, CodeMark.good);
      expect(card.output, [py(2 + 3 * 4), py((2 + 3) * 4)]);
    });

    test('card 7 shows the long way, the short way, and -= in a while', () {
      final code = math6.cards[6].code.map((l) => l.code).toList();
      expect(code, contains('score = score + 10'));
      expect(code, contains('score += 10'));
      expect(code, contains('while battery > 0:'));
      expect(code, contains('    battery -= 1'));
      expect(math6.cards[6].speech(en), contains('Lesson 4'));
    });

    test('the quiz covers the six required topics, with no notes', () {
      for (final q in math6.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
        expect(q.code.every((l) => l.mark == CodeMark.none), isTrue);
      }
      QuizQuestion withCode(String code) =>
          math6.quiz.singleWhere((q) => codeOf(q).contains(code));

      // Each right answer, worked out again in Dart (and checked in Python).
      expect(rightAnswer(withCode('10 / 2')), '`${py(10 / 2)}`'); // 5.0
      expect(rightAnswer(withCode('7 // 2')), '`${py(7 ~/ 2)}`'); // 3
      expect(rightAnswer(withCode('7 % 2')), '`${py(7 % 2)}`'); // 1
      expect(rightAnswer(withCode('2 + 3 * 4')), '`${py(2 + 3 * 4)}`'); // 14
      expect(rightAnswer(withCode('2 ** 3')), '`${py(math.pow(2, 3))}`'); // 8
      expect(rightAnswer(withCode('score += 10')), '`${py(5 + 10)}`'); // 15
    });

    test('no two answers in one question are the same', () {
      for (final q in math6.quiz) {
        final labels = q.answers.map((a) => a.label(en)).toList();
        expect(labels.toSet(), hasLength(labels.length));
        for (final a in q.answers.where((a) => !a.correct)) {
          expect(a.whyWrong, isNotNull);
        }
      }
    });

    test('every Lesson 6 card and question has a Tagalog version', () {
      expect(math6.title(tl), isNot(math6.title(en)));
      for (final card in math6.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
        expect(card.tip!(tl), isNot(card.tip!(en)));
      }
      for (final q in math6.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
        expect(q.explanation(tl), isNot(q.explanation(en)));
      }
      expect(math6.perfectQuizMessage!(en), contains('math master'));
      expect(math6.perfectQuizMessage!(tl), contains('Math master'));
    });
  });

  group('Code colors', () {
    test('+= and -= are colored as one sign', () {
      for (final (code, sign) in [
        ('score += 10', '+='),
        ('    battery -= 1', '-='),
      ]) {
        final spans = highlightPython(code);
        expect(
          spans.any(
            (s) => s.text == sign && s.style?.color == AppColors.codeOperator,
          ),
          isTrue,
          reason: code,
        );
        expect(spans.any((s) => s.text == '='), isFalse, reason: code);
      }
    });

    test('// and % are not comments; math signs stay plain', () {
      final spans = highlightPython('print(robots // 2)');
      expect(
        spans.any((s) => s.style?.color == AppColors.codeComment),
        isFalse,
      );
      expect(
        spans.any(
          (s) => s.text == '2' && s.style?.color == AppColors.codeNumber,
        ),
        isTrue,
      );
      // Same as Lessons 1 to 5: `-` alone is not colored.
      expect(
        highlightPython('battery = battery - 1').where((s) => s.style != null),
        hasLength(2), // `=` and `1`
      );
    });
  });

  testWidgets('Lesson 6 is locked until Lesson 5 has a star', (tester) async {
    SharedPreferences.setMockInitialValues(
      {...passed12345}..remove('progress.stars.functions'),
    );
    await tester.pumpWidget(
      PyCogApp(
        intro: false,
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    await scrollToLesson6(tester);
    expect(find.text(en.lesson6Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-node-math_operators')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('8 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson6(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/8'), findsOneWidget);

    for (var i = 1; i < 8; i++) {
      await tapText(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/8'), findsOneWidget);
    }
    await tapText(tester, en.lessonBack);
    expect(find.text(titlesEn[6]), findsOneWidget);
    await tapText(tester, en.lessonNext);

    await tapText(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(textHas(en.quiz6Q1Prompt), findsOneWidget);
  });

  testWidgets('Card 3 shows 5.0 in the output box, in both languages', (
    tester,
  ) async {
    final settings = await openLesson6(tester);
    await tapText(tester, en.lessonNext);
    await tapText(tester, en.lessonNext); // card 3
    Finder inOutput(String text) =>
        find.descendant(of: find.byType(OutputBox), matching: find.text(text));
    expect(inOutput('5.0'), findsOneWidget);
    expect(inOutput("<class 'float'>"), findsOneWidget);
    expect(textHas(en.lesson6NoteDivide), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.lesson6Card3Title), findsOneWidget);
    expect(textHas(tl.lesson6NoteDivide), findsOneWidget);
    // Code and output stay the same in Tagalog.
    expect(inOutput('5.0'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'print(10 / 2)',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Perfect quiz: math master, 3 stars, game button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passed12345);
    final settings = await SettingsController.load();
    final progress = await ProgressController.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: QuizScreen(
          lesson: math6,
          lessonNumber: 6,
          settings: settings,
          progress: progress,
          random: math.Random(6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < math6.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${math6.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == math6.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson6Perfect), findsOneWidget);
    expect(progress.bestStars('math_operators'), 3);
    // The next lesson opens, if there is one (counted from the list).
    final position = lessons.indexOf(math6) + 1; // Lesson 6
    if (position < lessons.length) {
      expect(find.text(en.resultsUnlocked(position + 1)), findsOneWidget);
      expect(progress.unlockedCount(lessons), position + 1);
    } else {
      expect(find.textContaining('is now open'), findsNothing);
      expect(progress.unlockedCount(lessons), lessons.length);
    }
    expect(find.text(en.resultsPlayGame), findsOneWidget); // game6_test
  });

  // All 8 cards on small phones with the biggest text, both languages.
  // Any overflow throws and fails the test.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All 8 cards fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await openLesson6(
          tester,
          size: size,
          systemScale: 1.5,
          extra: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          if (i < 7) await tapText(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
