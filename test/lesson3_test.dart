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

final ifs = lessons[2];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson3Card1Title,
  en.lesson3Card2Title,
  en.lesson3Card3Title,
  en.lesson3Card4Title,
  en.lesson3Card5Title,
  en.lesson3Card6Title,
  en.lesson3Card7Title,
  en.lesson3Card8Title,
];

/// Lessons 1 and 2 passed, so Lesson 3 is open.
const passed12 = {
  'progress.stars.variables': 1,
  'progress.stars.data_types': 1,
};

/// Starts the app and taps Lesson 3 on the trail.
Future<SettingsController> openLesson3(
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
  SharedPreferences.setMockInitialValues({...passed12, ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  final node = find.byKey(const ValueKey('lesson-node-if_statements'));
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

/// All code lines of a question as one string (for content checks).
String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

void main() {
  group('Lesson 3 content', () {
    test('8 cards, 6 multiple-choice questions, and a game', () {
      expect(ifs.id, 'if_statements');
      expect(ifs.cards, hasLength(8));
      expect(ifs.quiz, hasLength(6));
      expect(ifs.hasGame, isTrue); // see game3_test.dart
      expect(
        ifs.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in ifs.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('indented lines use exactly 4 spaces', () {
      for (final card in ifs.cards) {
        for (final line in card.code) {
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces == 0 || spaces == 4, isTrue, reason: line.code);
        }
      }
    });

    test('card 7 shows a wrong (✗) and a right (✓) indent example', () {
      final indent = ifs.cards[6];
      final bad = indent.code.where((l) => l.mark == CodeMark.bad).toList();
      final good = indent.code.where((l) => l.mark == CodeMark.good).toList();
      expect(bad.map((l) => l.code), contains('print("Keep playing!")'));
      expect(good.map((l) => l.code), contains('    print("Keep playing!")'));
    });

    test('the quiz covers the four required topics, with no notes', () {
      for (final q in ifs.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
      }
      String answers(QuizQuestion q) =>
          q.answers.map((a) => a.label(en)).join(' ');
      // = vs ==
      expect(
        ifs.quiz.any(
          (q) =>
              answers(q).contains('`lives == 3`') &&
              answers(q).contains('`lives = 3`'),
        ),
        isTrue,
      );
      // Missing colon: an if line without ':'.
      expect(
        ifs.quiz.any(
          (q) => q.code.any(
            (l) => l.code.startsWith('if ') && !l.code.endsWith(':'),
          ),
        ),
        isTrue,
      );
      // What prints for a given battery value.
      expect(ifs.quiz.any((q) => codeOf(q).contains('battery = 10')), isTrue);
      // else.
      expect(ifs.quiz.any((q) => q.prompt(en).contains('else')), isTrue);
    });

    test('every Lesson 3 card and question has a Tagalog version', () {
      for (final card in ifs.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
      }
      for (final q in ifs.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
      }
    });
  });

  group('Code colors', () {
    test('if/elif/else are keywords; >= and == are one sign each', () {
      final spans = highlightPython('if score >= 90:');
      final ifSpan = spans.firstWhere((s) => s.text == 'if');
      expect(ifSpan.style?.color, AppColors.codeKeyword);
      expect(spans.any((s) => s.text == '>='), isTrue);
      expect(highlightPython('lives == 3').any((s) => s.text == '=='), isTrue);
      expect(highlightPython('elif x < 5:').first.text, 'elif');
    });

    test('Lesson 1 lines still color the same way', () {
      final spans = highlightPython('battery = 100  # robot battery');
      expect(spans.map((s) => s.text), [
        'battery ',
        '=',
        ' ',
        '100',
        '  ',
        '# robot battery',
      ]);
      // "if" inside a word is not a keyword.
      expect(
        highlightPython('is_flying = False').any((s) => s.text == 'if'),
        isFalse,
      );
    });
  });

  testWidgets('Lesson 3 is locked until Lesson 2 has a star', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.stars.variables': 1});
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    final node = find.byKey(const ValueKey('lesson-node-if_statements'));
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

  testWidgets('8 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson3(tester);
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
    expect(textHas(en.quiz3Q1Prompt), findsOneWidget);
  });

  testWidgets('Arrow notes switch language; code stays English', (
    tester,
  ) async {
    final settings = await openLesson3(tester);
    for (var i = 0; i < 3; i++) {
      await tapText(tester, en.lessonNext); // card 4: = vs ==
    }
    expect(textHas('lives == 3'), findsOneWidget);
    expect(textHas(en.lesson3NoteCompare), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(textHas(tl.lesson3NoteCompare), findsOneWidget);
    expect(textHas('lives == 3'), findsOneWidget);
    expect(find.text(tl.lesson3Card4Title), findsOneWidget);
  });

  testWidgets('Perfect quiz: Lesson 3 message, 3 stars, Lesson 4 opens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passed12);
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
          lesson: ifs,
          lessonNumber: 3,
          settings: settings,
          progress: progress,
          random: math.Random(4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < ifs.quiz.length; q++) {
      final key = find.byKey(ValueKey('answer-$q-${ifs.quiz[q].correctIndex}'));
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == ifs.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson3Perfect), findsOneWidget);
    expect(progress.bestStars('if_statements'), 3);
    expect(find.text(en.resultsUnlocked(4)), findsOneWidget);
    expect(find.text(en.resultsPlayGame), findsOneWidget); // game3_test.dart
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
        await openLesson3(
          tester,
          size: size,
          systemScale: 1.5,
          extra: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -4000),
          );
          await tester.pumpAndSettle();
          if (i < 7) await tapText(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
