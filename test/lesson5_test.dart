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

final functions = lessons[4];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson5Card1Title,
  en.lesson5Card2Title,
  en.lesson5Card3Title,
  en.lesson5Card4Title,
  en.lesson5Card5Title,
  en.lesson5Card6Title,
  en.lesson5Card7Title,
  en.lesson5Card8Title,
  en.lesson5Card9Title,
];

/// Lessons 1 to 4 passed, so Lesson 5 is open.
const passed1234 = {
  'progress.stars.variables': 1,
  'progress.stars.data_types': 1,
  'progress.stars.if_statements': 1,
  'progress.stars.loops': 1,
};

Future<SettingsController> openLesson5(
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
  SharedPreferences.setMockInitialValues({...passed1234, ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  await openTrail(tester); // app opens on the home screen
  final node = find.byKey(const ValueKey('lesson-node-functions'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(node);
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

void main() {
  group('Lesson 5 content', () {
    test('9 cards, 6 multiple-choice questions, and a game', () {
      expect(functions.id, 'functions');
      expect(functions.cards, hasLength(9));
      expect(functions.quiz, hasLength(6));
      expect(functions.hasGame, isTrue); // see game5_test.dart
      expect(
        functions.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in functions.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('indents are 4 spaces per level', () {
      for (final card in functions.cards) {
        for (final line in card.code) {
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test('output boxes match real Python (checked by running the code)', () {
      final outputs = [for (final c in functions.cards) c.output];
      expect(outputs, [
        ['Hi, I am Cog!', 'Hi, I am Cog!', 'Hi, I am Cog!'],
        <String>[], // card 2 only makes the function: nothing prints
        ['Hi, I am Cog!', 'Hi, I am Cog!', 'Hi, I am Cog!'],
        <String>[], // card 4 shows the shape only
        ['Hi, Ana', 'Hi, Ben'],
        ['5'],
        ['5', 'None', '5'],
        ['Low', 'OK'],
        ['5'],
      ]);
    });

    test('every card whose code calls something that prints has output', () {
      for (final (i, card) in functions.cards.indexed) {
        // A card prints iff it has a top-level (unindented) print or call.
        final runs = card.code.any(
          (l) =>
              !l.code.startsWith(' ') &&
              !l.code.startsWith('def ') &&
              l.code.contains('('),
        );
        expect(card.output.isNotEmpty, runs, reason: 'card ${i + 1}');
      }
    });

    test('card 7: print (✗) gives back None; return (✓) gives back 5', () {
      final card = functions.cards[6];
      final bad = card.code.where((l) => l.mark == CodeMark.bad).toList();
      final good = card.code.where((l) => l.mark == CodeMark.good).toList();
      expect(bad.map((l) => l.code), contains('    print(a + b)'));
      expect(good.map((l) => l.code), contains('    return a + b'));
      expect(bad.map((l) => l.code), isNot(contains('    return a + b')));
    });

    test('the quiz covers the five required topics, with no notes', () {
      for (final q in functions.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
      }
      String answers(QuizQuestion q) =>
          q.answers.map((a) => a.label(en)).join(' | ');
      // def but never called.
      expect(
        functions.quiz.any(
          (q) =>
              codeOf(q).startsWith('def ') &&
              q.code.every(
                (l) => l.code.startsWith('def ') || l.code.startsWith(' '),
              ),
        ),
        isTrue,
      );
      // What a parameter is.
      expect(
        functions.quiz.any((q) => answers(q).contains('parameter')),
        isTrue,
      );
      // What prints for a short call.
      expect(
        functions.quiz.any((q) => codeOf(q).contains('greet("Cog")')),
        isTrue,
      );
      // print vs return.
      expect(
        functions.quiz.any(
          (q) =>
              answers(q).contains('`print`') && answers(q).contains('`return`'),
        ),
        isTrue,
      );
      // What add(2, 3) gives.
      final add = functions.quiz.firstWhere(
        (q) => q.prompt(en).contains('add(2, 3)'),
      );
      expect(add.answers[add.correctIndex].label(en), '`5`');
    });

    test('every Lesson 5 card and question has a Tagalog version', () {
      for (final card in functions.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
      }
      for (final q in functions.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
      }
    });
  });

  group('Code colors', () {
    test('def and return are keywords', () {
      expect(
        highlightPython('def add(a, b):').first.style?.color,
        AppColors.codeKeyword,
      );
      expect(
        highlightPython('    return a + b').any(
          (s) => s.text == 'return' && s.style?.color == AppColors.codeKeyword,
        ),
        isTrue,
      );
    });

    test('def and return inside names or strings stay plain', () {
      expect(
        highlightPython('defense = 5').any((s) => s.text == 'def'),
        isFalse,
      );
      expect(
        highlightPython('print("return home")').any((s) => s.text == 'return'),
        isFalse,
      );
    });
  });

  testWidgets('Lesson 5 is locked until Lesson 4 has a star', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.stars.variables': 1,
      'progress.stars.data_types': 1,
      'progress.stars.if_statements': 1,
    });
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    final node = find.byKey(const ValueKey('lesson-node-functions'));
    await tester.scrollUntilVisible(
      node,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(node);
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('9 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson5(tester);
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
    expect(textHas(en.quiz5Q1Prompt), findsOneWidget);
  });

  testWidgets('Card 2 has no output; card 3 shows the 3 calls', (tester) async {
    final settings = await openLesson5(tester);
    await tapText(tester, en.lessonNext); // card 2: only def
    expect(find.byType(OutputBox), findsNothing);
    expect(textHas(en.lesson5NoteNotYet), findsOneWidget);

    await tapText(tester, en.lessonNext); // card 3: def + 3 calls
    expect(
      find.descendant(
        of: find.byType(OutputBox),
        matching: find.text('Hi, I am Cog!'),
      ),
      findsNWidgets(3),
    );

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(textHas(tl.lesson5NoteCall1), findsOneWidget);
    // Code unchanged: the 3 call lines are exactly `say_hello()` (the def
    // line `def say_hello():` is a different line).
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == 'say_hello()',
        ),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('Perfect quiz: Lesson 5 message, 3 stars, nothing to unlock', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passed1234);
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
          lesson: functions,
          lessonNumber: 5,
          settings: settings,
          progress: progress,
          random: math.Random(8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < functions.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${functions.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == functions.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson5Perfect), findsOneWidget);
    expect(progress.bestStars('functions'), 3);
    // Lesson 5 is the last lesson: no "Lesson 6 is now open!" badge.
    expect(find.textContaining('is now open'), findsNothing);
    expect(progress.unlockedCount(lessons), lessons.length);
    expect(find.text(en.resultsPlayGame), findsOneWidget); // game5_test.dart
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
        await openLesson5(
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
