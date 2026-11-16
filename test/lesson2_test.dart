import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/models/quiz.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

final dataTypes = lessons[1];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson2Card1Title,
  en.lesson2Card2Title,
  en.lesson2Card3Title,
  en.lesson2Card4Title,
  en.lesson2Card5Title,
  en.lesson2Card6Title,
  en.lesson2Card7Title,
];

/// Starts the app with Lesson 1 passed (so Lesson 2 is open) and taps
/// Lesson 2 on the trail.
Future<SettingsController> openLesson2(
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
  SharedPreferences.setMockInitialValues({
    'progress.stars.variables': 1,
    ...extra,
  });
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  final node = find.byKey(const ValueKey('lesson-node-data_types'));
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

void main() {
  group('Lesson 2 content', () {
    test('7 cards and 6 multiple-choice questions', () {
      expect(dataTypes.id, 'data_types');
      expect(dataTypes.cards, hasLength(7));
      expect(dataTypes.quiz, hasLength(6));
      expect(dataTypes.hasGame, isTrue); // see game2_test.dart
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in dataTypes.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('quiz has no arrow notes, plus the "5" and True questions', () {
      for (final q in dataTypes.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
      }
      String answers(QuizQuestion q) =>
          q.answers.map((a) => a.label(en)).join(' ');
      final all = dataTypes.quiz.map(answers).toList();
      // "5" vs 5: the question that shows room = "5" and asks its type.
      expect(
        dataTypes.quiz.any((q) => q.code.any((l) => l.code == 'room = "5"')),
        isTrue,
      );
      // True vs true: a question offering both.
      expect(
        all.any((a) => a.contains('`True`') && a.contains('`true`')),
        isTrue,
      );
    });

    test('every Lesson 2 string has an English and a Tagalog version', () {
      for (final card in dataTypes.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
      }
      for (final q in dataTypes.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
      }
    });

    test('decimal numbers are colored as one number', () {
      final spans = highlightPython('speed = 2.5');
      expect(spans.any((s) => s.text == '2.5'), isTrue);
    });
  });

  testWidgets('Lesson 2 is locked until Lesson 1 has a star', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-node-data_types')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('7 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson2(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);

    for (var i = 1; i < 7; i++) {
      await tapText(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/7'), findsOneWidget);
    }
    await tapText(tester, en.lessonBack);
    expect(find.text(titlesEn[5]), findsOneWidget);
    await tapText(tester, en.lessonNext);

    await tapText(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(textHas(en.quiz2Q1Prompt), findsOneWidget);
  });

  testWidgets('Arrow notes switch language; code stays English', (
    tester,
  ) async {
    final settings = await openLesson2(tester);
    for (var i = 0; i < 5; i++) {
      await tapText(tester, en.lessonNext); // card 6: type()
    }
    expect(textHas('print(type(speed))'), findsOneWidget);
    expect(textHas(en.lesson2NotePrintType), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(textHas(tl.lesson2NotePrintType), findsOneWidget);
    expect(textHas('print(type(speed))'), findsOneWidget);
    expect(find.text(tl.lesson2Card6Title), findsOneWidget);
  });

  testWidgets('Perfect quiz: Lesson 2 message, 3 stars saved', (tester) async {
    // A real student only reaches Lesson 2 after passing Lesson 1.
    SharedPreferences.setMockInitialValues({'progress.stars.variables': 1});
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
          lesson: dataTypes,
          lessonNumber: 2,
          settings: settings,
          progress: progress,
          random: math.Random(5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < dataTypes.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${dataTypes.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == dataTypes.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson2Perfect), findsOneWidget);
    expect(textHas('variable master'), findsNothing);
    expect(progress.bestStars('data_types'), 3);
    expect(find.text(en.resultsUnlocked(3)), findsOneWidget);
  });

  // All 7 cards on small phones with the biggest text, both languages.
  // Any overflow throws and fails the test.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All 7 cards fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await openLesson2(
          tester,
          size: size,
          systemScale: 1.5,
          extra: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 7; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          if (i < 6) await tapText(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
