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

final loops = lessons[3];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson4Card1Title,
  en.lesson4Card2Title,
  en.lesson4Card3Title,
  en.lesson4Card4Title,
  en.lesson4Card5Title,
  en.lesson4Card6Title,
  en.lesson4Card7Title,
  en.lesson4Card8Title,
  en.lesson4Card9Title,
];

/// Lessons 1 to 3 passed, so Lesson 4 is open.
const passed123 = {
  'progress.stars.variables': 1,
  'progress.stars.data_types': 1,
  'progress.stars.if_statements': 1,
};

Future<SettingsController> openLesson4(
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
  SharedPreferences.setMockInitialValues({...passed123, ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  final node = find.byKey(const ValueKey('lesson-node-loops'));
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
  group('Lesson 4 content', () {
    test('9 cards, 6 multiple-choice questions, no game yet', () {
      expect(loops.id, 'loops');
      expect(loops.cards, hasLength(9));
      expect(loops.quiz, hasLength(6));
      expect(loops.hasGame, isFalse);
      expect(
        loops.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
    });

    test('every code line on the cards has an arrow note', () {
      for (final card in loops.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
        }
      }
    });

    test('indents are 4 spaces per level', () {
      for (final card in loops.cards) {
        for (final line in card.code) {
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test('output boxes show what the code prints (checked in Python)', () {
      expect(loops.cards[1].output, ['Step', 'Step', 'Step']);
      expect(loops.cards[4].output, ['1', '2', '3']);
      expect(loops.cards[5].output, ['3', '2', '1']);
      expect(loops.cards[7].output, [
        'Room clear',
        'Room clear',
        'Enemy found!',
      ]);
    });

    test('card 7 shows the infinite loop (✗) and the fixed one (✓)', () {
      final card = loops.cards[6];
      final bad = card.code.where((l) => l.mark == CodeMark.bad).toList();
      final good = card.code.where((l) => l.mark == CodeMark.good).toList();
      // The fixed loop changes battery; the broken one never does.
      expect(good.map((l) => l.code), contains('    battery = battery - 1'));
      expect(
        bad.map((l) => l.code),
        isNot(contains('    battery = battery - 1')),
      );
    });

    test('the quiz covers the five required topics, with no notes', () {
      for (final q in loops.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
      }
      String answers(QuizQuestion q) =>
          q.answers.map((a) => a.label(en)).join(' ');
      // What range(3) gives.
      expect(loops.quiz.any((q) => q.prompt(en).contains('range(3)')), isTrue);
      // How many times a loop runs.
      expect(
        loops.quiz.any((q) => q.prompt(en).contains('How many times')),
        isTrue,
      );
      // What prints for a short for loop.
      expect(
        loops.quiz.any(
          (q) =>
              codeOf(q).startsWith('for ') &&
              q.prompt(en).contains('show on the screen'),
        ),
        isTrue,
      );
      // Why a while loop never stops.
      expect(
        loops.quiz.any(
          (q) =>
              codeOf(q).contains('while') &&
              q.prompt(en).contains('never stop'),
        ),
        isTrue,
      );
      // break.
      expect(loops.quiz.any((q) => q.prompt(en).contains('break')), isTrue);
      expect(answers(loops.quiz[0]), contains('`0, 1, 2`'));
    });

    test('every Lesson 4 card and question has a Tagalog version', () {
      for (final card in loops.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
      }
      for (final q in loops.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
      }
    });

    test('Lessons 1 to 3 have no output boxes (they look the same)', () {
      for (final lesson in lessons.take(3)) {
        for (final card in lesson.cards) {
          expect(card.output, isEmpty);
        }
      }
    });
  });

  group('Code colors', () {
    test('for, in, while and break are keywords', () {
      final spans = highlightPython('for step in range(3):');
      expect(
        spans.firstWhere((s) => s.text == 'for').style?.color,
        AppColors.codeKeyword,
      );
      expect(
        spans.firstWhere((s) => s.text == 'in').style?.color,
        AppColors.codeKeyword,
      );
      expect(highlightPython('while battery > 0:').first.text, 'while');
      expect(
        highlightPython('        break').any((s) => s.text == 'break'),
        isTrue,
      );
    });

    test('words inside names or strings are not keywords', () {
      // "in" inside a name, and inside a string, stays plain.
      expect(
        highlightPython('is_online = True').any((s) => s.text == 'in'),
        isFalse,
      );
      expect(
        highlightPython('print("Room clear")').any((s) => s.text == 'in'),
        isFalse,
      );
      expect(
        highlightPython('print("Keep playing!")').any((s) => s.text == 'in'),
        isFalse,
      );
    });
  });

  testWidgets('Lesson 4 is locked until Lesson 3 has a star', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.stars.variables': 1,
      'progress.stars.data_types': 1,
    });
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    final node = find.byKey(const ValueKey('lesson-node-loops'));
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
    await openLesson4(tester);
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
    expect(textHas('range(3)'), findsOneWidget);
  });

  testWidgets('Output box shows Step 3 times; label switches language', (
    tester,
  ) async {
    final settings = await openLesson4(tester);
    expect(find.byType(OutputBox), findsNothing); // card 1 has none
    await tapText(tester, en.lessonNext); // card 2

    expect(find.byType(OutputBox), findsOneWidget);
    expect(
      find.descendant(of: find.byType(OutputBox), matching: find.text('Step')),
      findsNWidgets(3),
    );
    expect(find.text(en.lessonOutputLabel), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.lessonOutputLabel), findsOneWidget);
    expect(textHas(tl.lesson4NoteFor3), findsOneWidget);
    // The code itself is unchanged (look inside the code box only: Cog's
    // speech also mentions it).
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: textHas('for step in range(3):'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Perfect quiz: Lesson 4 message, 3 stars, Lesson 5 opens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(passed123);
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
          lesson: loops,
          lessonNumber: 4,
          settings: settings,
          progress: progress,
          random: math.Random(6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var q = 0; q < loops.quiz.length; q++) {
      final key = find.byKey(
        ValueKey('answer-$q-${loops.quiz[q].correctIndex}'),
      );
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      await tapText(tester, en.quizCheck);
      final last = q == loops.quiz.length - 1;
      await tapText(tester, last ? en.quizSeeResults : en.quizNext);
    }

    expect(textHas(en.lesson4Perfect), findsOneWidget);
    expect(progress.bestStars('loops'), 3);
    expect(find.text(en.resultsUnlocked(5)), findsOneWidget);
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
        await openLesson4(
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
