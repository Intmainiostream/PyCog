import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/models/lesson.dart';
import 'package:pycog/models/lesson_card.dart';
import 'package:pycog/models/quiz.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';
import 'package:pycog/widgets/truth_table.dart';

import 'test_helpers.dart';

final logic = lessons.firstWhere((l) => l.id == 'logic');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson10Card1Title,
  en.lesson10Card2Title,
  en.lesson10Card3Title,
  en.lesson10Card4Title,
  en.lesson10Card5Title,
  en.lesson10Card6Title,
  en.lesson10Card7Title,
  en.lesson10Card8Title,
  en.lesson10Card9Title,
];

/// Every lesson before [lesson] passed, so [lesson] is open.
Map<String, Object> passedBefore(Lesson lesson) => {
  for (final l in lessons.take(lessons.indexOf(lesson)))
    'progress.stars.${l.id}': 1,
};

/// How Python prints a bool.
String py(bool value) => value ? 'True' : 'False';

// Python's and / or / not, done in Dart. They are functions so the
// analyzer can't work the answers out ahead of time (and call the
// other side "dead code").
bool and_(bool a, bool b) => a && b;
bool or_(bool a, bool b) => a || b;
bool not_(bool a) => !a;
bool gt(int a, int b) => a > b;
bool le(int a, int b) => a <= b;

Future<void> scrollToLesson10(WidgetTester tester) async {
  final node = find.byKey(const ValueKey('lesson-node-logic'));
  await tester.scrollUntilVisible(
    node,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<SettingsController> openLesson10(
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
  SharedPreferences.setMockInitialValues({...passedBefore(logic), ...extra});
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  await openTrail(tester); // app opens on the home screen
  await scrollToLesson10(tester);
  await tester.tap(find.byKey(const ValueKey('lesson-node-logic')));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Answers every question of [lesson]'s quiz right and opens the results.
Future<ProgressController> perfectQuiz(
  WidgetTester tester,
  Lesson lesson,
) async {
  SharedPreferences.setMockInitialValues(passedBefore(lesson));
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
        lesson: lesson,
        lessonNumber: lessons.indexOf(lesson) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(10),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (var q = 0; q < lesson.quiz.length; q++) {
    final key = find.byKey(
      ValueKey('answer-$q-${lesson.quiz[q].correctIndex}'),
    );
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
    await tapText(tester, en.quizCheck);
    final last = q == lesson.quiz.length - 1;
    await tapText(tester, last ? en.quizSeeResults : en.quizNext);
  }
  return progress;
}

String codeOf(QuizQuestion q) => q.code.map((l) => l.code).join('\n');

String rightAnswer(QuizQuestion q) => q.answers[q.correctIndex].label(en);

List<String> codeLines(LessonCard card) => [for (final l in card.code) l.code];

void main() {
  group('Lesson 10 content', () {
    test('9 cards, 6 multiple-choice questions, no game yet', () {
      expect(logic.title(en), 'Logic');
      expect(logic.cards, hasLength(9));
      expect(logic.quiz, hasLength(6));
      expect(logic.hasGame, isFalse);
      expect(
        logic.quiz.every((q) => q.type == QuestionType.multipleChoice),
        isTrue,
      );
      // Right after Lesson 9.
      expect(lessons.indexOf(logic), 9);
      expect(lessons[8].id, 'input_output');
    });

    test('every code line has an arrow note; indents are 4 spaces', () {
      for (final card in logic.cards) {
        for (final line in card.code) {
          expect(line.note, isNotNull, reason: 'no note on "${line.code}"');
          final spaces = line.code.length - line.code.trimLeft().length;
          expect(spaces % 4, 0, reason: line.code);
        }
      }
    });

    test('output boxes match real Python (checked by running the code)', () {
      expect(
        [for (final c in logic.cards) c.output],
        [
          ['You can play!'],
          ['False'],
          ['True'],
          ['True', 'Keep playing!'],
          ['Still locked'],
          ['False', 'True'],
          ['True', 'False'],
          ['True', 'True'],
          ['False', 'True', 'False', 'True'],
        ],
      );
    });

    test('every card prints, so every card has an output box', () {
      for (final card in logic.cards) {
        expect(card.code.any((l) => l.code.contains('print(')), isTrue);
        expect(card.output, isNotEmpty);
      }
    });

    test('outputs agree with the same logic done again in Dart', () {
      final c = logic.cards;
      expect(c[1].output, [py(and_(gt(50, 20), gt(0, 0)))]);
      expect(c[2].output, [py(or_(false, true))]);
      expect(c[3].output.first, py(not_(false))); // not game_over
      expect(c[5].output, [
        py(and_(gt(3, 0), gt(0, 0))),
        py(or_(gt(3, 0), gt(0, 0))),
      ]);
      // a = True, b = False, c = False: and goes before or.
      expect(c[6].output, [
        py(or_(true, and_(false, false))),
        py(and_(or_(true, false), false)),
      ]);
      const level = 2;
      expect(c[7].output, [
        py(and_(le(1, level), le(level, 3))),
        py(and_(le(1, level), le(level, 3))), // Python's 1 <= level <= 3
      ]);
      expect(c[8].output, [
        py(and_(true, false)),
        py(or_(true, false)),
        py(not_(true)),
        py(and_(le(1, 2), le(2, 3))),
      ]);
    });

    test('cards 2, 3 and 4 have True/False tables that match Python', () {
      final tables = [for (final c in logic.cards) c.table];
      expect(tables.whereType<TruthTableData>(), hasLength(3));
      expect(
        [tables[1]?.headings, tables[2]?.headings, tables[3]?.headings],
        [
          ['a', 'b', 'a and b'],
          ['a', 'b', 'a or b'],
          ['a', 'not a'],
        ],
      );
      // Each row, as printed by real Python for `a and b` etc.
      expect(tables[1]!.rows, [
        [true, true, true],
        [true, false, false],
        [false, true, false],
        [false, false, false],
      ]);
      expect(tables[2]!.rows, [
        [true, true, true],
        [true, false, true],
        [false, true, true],
        [false, false, false],
      ]);
      expect(tables[3]!.rows, [
        [true, false],
        [false, true],
      ]);
      // And worked out again in Dart.
      for (final [a, b, r] in tables[1]!.rows) {
        expect(r, a && b);
      }
      for (final [a, b, r] in tables[2]!.rows) {
        expect(r, a || b);
      }
      for (final [a, r] in tables[3]!.rows) {
        expect(r, !a);
      }
    });

    test('lessons before Lesson 10 never have a table', () {
      for (final lesson in lessons.take(lessons.indexOf(logic))) {
        for (final card in lesson.cards) {
          expect(card.table, isNull, reason: lesson.id);
        }
      }
    });

    test('cards 1 and 5 connect to if / else from Lesson 3', () {
      expect(logic.cards[0].speech(en), contains('Lesson 3'));
      final card5 = logic.cards[4];
      expect(card5.speech(en), contains('Lesson 3'));
      expect(codeLines(card5), contains('if has_key and battery > 0:'));
      expect(codeLines(card5), contains('else:'));
    });

    test('card 6: same values; ✓ and gives False, ✗ or gives True', () {
      final card = logic.cards[5];
      expect(card.title(en), contains('Warning'));
      expect(codeLines(card).take(2), ['lives = 3', 'battery = 0']);
      final good = card.code.singleWhere((l) => l.mark == CodeMark.good);
      final bad = card.code.singleWhere((l) => l.mark == CodeMark.bad);
      expect(good.code, 'print(alive and charged)');
      expect(bad.code, 'print(alive or charged)');
      expect(card.output, ['False', 'True']);
    });

    test('card 7: brackets change the result (Lesson 6)', () {
      final card = logic.cards[6];
      expect(codeLines(card), [
        'a = True',
        'b = False',
        'c = False',
        'print(a or b and c)',
        'print((a or b) and c)',
      ]);
      // The same as the plan's True or False and False (checked in Python).
      expect(card.output, [
        py(or_(true, and_(false, false))),
        py(and_(or_(true, false), false)),
      ]);
      expect(card.speech(en), contains('Lesson 6'));
    });

    test('card 8: 1 <= level <= 3 means level >= 1 and level <= 3', () {
      final code = codeLines(logic.cards[7]);
      expect(code, contains('print(1 <= level <= 3)'));
      expect(code, contains('low = level >= 1'));
      expect(code, contains('high = level <= 3'));
    });

    test('the quiz covers the six required topics, with no notes', () {
      for (final q in logic.quiz) {
        expect(q.code.every((l) => l.note == null), isTrue);
        expect(q.code.every((l) => l.mark == CodeMark.none), isTrue);
      }
      QuizQuestion withCode(String code) =>
          logic.quiz.singleWhere((q) => codeOf(q) == code);
      QuizQuestion byPrompt(String text) =>
          logic.quiz.singleWhere((q) => q.prompt(en).contains(text));

      // Each right answer, worked out again in Dart (checked in Python).
      expect(
        rightAnswer(withCode('print(True and False)')),
        '`${py(and_(true, false))}`',
      );
      expect(
        rightAnswer(withCode('print(True or False)')),
        '`${py(or_(true, false))}`',
      );
      expect(rightAnswer(withCode('print(not True)')), '`${py(not_(true))}`');
      final shortIf = logic.quiz.singleWhere(
        (q) => codeOf(q).contains('if alive and charged:'),
      );
      // alive = True, charged = False.
      expect(rightAnswer(shortIf), and_(true, false) ? '`Go!`' : '`Stop!`');
      expect(rightAnswer(byPrompt('BOTH sides')), '`and`');
      expect(
        rightAnswer(byPrompt('(True or False) and False')),
        '`${py(and_(or_(true, false), false))}`',
      );
    });

    test('no two answers in one question are the same', () {
      for (final q in logic.quiz) {
        final labels = q.answers.map((a) => a.label(en)).toList();
        expect(labels.toSet(), hasLength(labels.length));
        for (final a in q.answers.where((a) => !a.correct)) {
          expect(a.whyWrong, isNotNull);
        }
      }
    });

    test('every Lesson 10 card and question has a Tagalog version', () {
      expect(logic.title(tl), isNot(logic.title(en)));
      for (final card in logic.cards) {
        expect(card.title(tl), isNot(card.title(en)));
        expect(card.speech(tl), isNot(card.speech(en)));
        expect(card.tip!(tl), isNot(card.tip!(en)));
      }
      for (final q in logic.quiz) {
        expect(q.prompt(tl), isNot(q.prompt(en)));
        expect(q.explanation(tl), isNot(q.explanation(en)));
      }
      expect(logic.perfectQuizMessage!(en), contains('logic master'));
      expect(logic.perfectQuizMessage!(tl), contains('Logic master'));
    });
  });

  group('Code colors', () {
    bool isKeyword(TextSpan s) =>
        s.style?.color == AppColors.codeKeyword &&
        s.style?.fontWeight == FontWeight.w800;

    test('and, or and not are bold keywords', () {
      final spans = highlightPython('print(not a or b and c)');
      expect(spans.where(isKeyword).map((s) => s.text), ['not', 'or', 'and']);
    });

    test('inside other words or strings they stay plain', () {
      for (final code in [
        'android = 1',
        'order = 2',
        'nothing = 3',
        'print("and or not")',
      ]) {
        expect(highlightPython(code).where(isKeyword), isEmpty, reason: code);
      }
    });
  });

  group('Truth table', () {
    Future<void> pumpTable(WidgetTester tester, TruthTableData data) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: TruthTable(data: data)),
          ),
        );

    testWidgets('shows the headings and a True/False chip per value', (
      tester,
    ) async {
      await pumpTable(tester, logic.cards[1].table!);
      for (final heading in ['a', 'b', 'a and b']) {
        expect(find.text(heading), findsOneWidget);
      }
      // 4 rows x 3 columns: 5 True and 7 False.
      expect(find.text('True'), findsNWidgets(5));
      expect(find.text('False'), findsNWidgets(7));
    });

    testWidgets('the words are always there, not only colors', (tester) async {
      await pumpTable(tester, logic.cards[3].table!);
      expect(find.text('True'), findsNWidgets(2));
      expect(find.text('False'), findsNWidgets(2));
    });

    testWidgets('screen readers hear each row as a sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTable(tester, logic.cards[3].table!);
      expect(
        find.bySemanticsLabel('a True, not a False. a False, not a True'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  testWidgets('Lesson 10 is locked until Lesson 9 has a star', (tester) async {
    SharedPreferences.setMockInitialValues(
      {...passedBefore(logic)}..remove('progress.stars.input_output'),
    );
    await tester.pumpWidget(
      PyCogApp(
        settings: await SettingsController.load(),
        progress: await ProgressController.load(),
      ),
    );
    await tester.pumpAndSettle();
    await openTrail(tester); // app opens on the home screen
    await scrollToLesson10(tester);
    expect(find.text(en.lesson10Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-node-logic')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text(en.lessonLocked), findsOneWidget);
  });

  testWidgets('9 cards: progress, Back, Next, then Next: Quiz', (tester) async {
    await openLesson10(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/9'), findsOneWidget);

    for (var i = 1; i < 9; i++) {
      await tapText(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/9'), findsOneWidget);
      // Only cards 2, 3 and 4 show a table.
      expect(
        find.byType(TruthTable),
        i >= 1 && i <= 3 ? findsOneWidget : findsNothing,
        reason: 'card ${i + 1}',
      );
    }
    await tapText(tester, en.lessonBack);
    expect(find.text(titlesEn[7]), findsOneWidget);
    await tapText(tester, en.lessonNext);

    await tapText(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(textHas(en.quiz10Q1Prompt), findsOneWidget);
  });

  testWidgets('Card 2: the table sits above the code, in both languages', (
    tester,
  ) async {
    final settings = await openLesson10(tester);
    await tapText(tester, en.lessonNext); // card 2
    expect(find.byType(TruthTable), findsOneWidget);
    expect(
      tester.getRect(find.byType(TruthTable)).bottom,
      lessThan(tester.getRect(find.byType(CodeBox)).top),
    );
    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.lesson10Card2Title), findsOneWidget);
    // The table and code stay the same in Tagalog.
    expect(find.text('a and b'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText() == 'print(power and alive)',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Perfect quiz: logic master, 3 stars, no game button', (
    tester,
  ) async {
    final progress = await perfectQuiz(tester, logic);
    final position = lessons.indexOf(logic) + 1; // Lesson 10
    expect(textHas(en.lesson10Perfect), findsOneWidget);
    expect(progress.bestStars('logic'), 3);
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

  // Whatever lesson is last on the trail (now Lesson 10) has no lesson
  // after it, so its results screen shows no "next lesson" badge.
  testWidgets('The last lesson on the trail shows no "next lesson" badge', (
    tester,
  ) async {
    final last = lessons.last;
    final progress = await perfectQuiz(tester, last);
    expect(find.text(en.resultsTitle), findsOneWidget);
    expect(find.textContaining('is now open'), findsNothing);
    expect(find.text(en.resultsUnlocked(lessons.length + 1)), findsNothing);
    expect(progress.unlockedCount(lessons), lessons.length);
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
        await openLesson10(
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
