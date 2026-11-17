import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/widgets/code_box.dart';
import 'package:pycog/widgets/lesson_top_bar.dart';

import 'test_helpers.dart';

final variables = lessons.first;
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// Text that may be split into colored pieces.
Finder textHas(String text) => find.textContaining(text, findRichText: true);

final titlesEn = [
  en.lesson1Card1Title,
  en.lesson1Card2Title,
  en.lesson1Card3Title,
  en.lesson1Card4Title,
  en.lesson1Card5Title,
  en.lesson1Card6Title,
];

Future<SettingsController> openLesson(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
  double systemScale = 1.0,
  Map<String, Object> saved = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues(saved);
  final settings = await SettingsController.load();
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  await tester.pumpAndSettle();
  await openTrail(tester); // app opens on the home screen
  // Lists only build what's near the screen, so scroll down to the trail.
  final node = find.byKey(const ValueKey('lesson-node-variables'));
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

Future<void> next(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('Lesson 1 has 6 cards; card 2 is about comments', () {
    expect(variables.cards, hasLength(6));
    final comments = variables.cards[1];
    expect(comments.title(en), 'Notes in code');
    expect(comments.code.map((l) => l.code), [
      '# This is a note',
      'battery = 100  # robot battery',
    ]);
    // Comment lines are notes already: no arrow notes on them.
    expect(comments.code.every((l) => l.note == null), isTrue);
  });

  test('Arrow notes never appear in the quiz (no answer giveaways)', () {
    for (final question in variables.quiz) {
      expect(question.code.every((l) => l.note == null), isTrue);
    }
  });

  test('# starts a comment that runs to the end of the line', () {
    final spans = highlightPython('battery = 100  # robot battery');
    final comment = spans.last;
    expect(comment.text, '# robot battery');
    expect(comment.style?.fontStyle, FontStyle.italic);
    // A # inside quotes is NOT a comment.
    final quoted = highlightPython('tag = "#1"');
    expect(quoted.any((s) => s.text == '"#1"'), isTrue);
    expect(quoted.any((s) => s.text?.startsWith('#') ?? false), isFalse);
  });

  testWidgets('6 cards: Next, Back, progress bar, Next: Quiz, and X', (
    tester,
  ) async {
    await openLesson(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text(titlesEn[0]), findsOneWidget);
    expect(find.text('1/6'), findsOneWidget);

    for (var i = 1; i < 6; i++) {
      await next(tester, en.lessonNext);
      expect(find.text(titlesEn[i]), findsOneWidget, reason: 'card ${i + 1}');
      expect(find.text('${i + 1}/6'), findsOneWidget);
    }
    expect(find.text(en.lessonNextQuiz), findsOneWidget);

    await next(tester, en.lessonBack);
    expect(find.text(titlesEn[4]), findsOneWidget);
    expect(find.text('5/6'), findsOneWidget);
    await next(tester, en.lessonNext);

    await next(tester, en.lessonNextQuiz);
    expect(find.byType(QuizScreen), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(QuizScreen),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();

    // X on the lesson goes back to the trail.
    await tester.tap(
      find.descendant(
        of: find.byType(LessonTopBar),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('Comment card shows # code and no arrow notes', (tester) async {
    await openLesson(tester);
    await next(tester, en.lessonNext); // card 2

    expect(find.text(en.lesson1Card2Title), findsOneWidget);
    expect(textHas('# This is a note'), findsOneWidget);
    expect(textHas('# robot battery'), findsOneWidget);
    expect(textHas('←'), findsNothing);
  });

  testWidgets('Arrow notes show, and switch language with the code kept', (
    tester,
  ) async {
    final settings = await openLesson(tester);
    await next(tester, en.lessonNext);
    await next(tester, en.lessonNext); // card 3: battery = 100

    expect(textHas('battery = 100'), findsOneWidget);
    expect(textHas('← ${en.lesson1NoteBattery100}'), findsOneWidget);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(textHas('← ${tl.lesson1NoteBattery100}'), findsOneWidget);
    expect(textHas('battery = 100'), findsOneWidget); // code unchanged
    expect(find.text(tl.lesson1Card3Title), findsOneWidget);
  });

  testWidgets('On a 360px phone a long note moves under its code line', (
    tester,
  ) async {
    await openLesson(tester, size: const Size(360, 640));
    for (var i = 0; i < 4; i++) {
      await next(tester, en.lessonNext); // card 5: battery = 80
    }
    final code = textHas('battery = 80');
    final note = textHas('← ${en.lesson1NoteBattery80}');
    await tester.ensureVisible(note);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(note).dy,
      greaterThan(tester.getBottomLeft(code).dy - 1),
      reason: 'note should be on its own line below the code',
    );
    // ...and it starts at the same left edge as the code (no badge here).
    expect(
      tester.getTopLeft(note).dx,
      moreOrLessEquals(tester.getTopLeft(code).dx, epsilon: 1),
    );
  });

  testWidgets('On a wide screen the note stays on the same line', (
    tester,
  ) async {
    await openLesson(tester, size: const Size(800, 1000));
    await next(tester, en.lessonNext);
    await next(tester, en.lessonNext); // card 3
    final code = textHas('battery = 100');
    final note = textHas('← ${en.lesson1NoteBattery100}');
    expect(
      tester.getTopLeft(note).dx,
      greaterThan(tester.getTopRight(code).dx),
    );
    expect(
      tester.getCenter(note).dy,
      moreOrLessEquals(tester.getCenter(code).dy, epsilon: 6),
    );
  });

  // All 6 cards on small and landscape phones with the biggest text, in both
  // languages. Any overflow throws and fails the test.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All 6 cards fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await openLesson(
          tester,
          size: size,
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var i = 0; i < 6; i++) {
          // Scroll to the bottom of each card (code box + tip).
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
          if (i < 5) await next(tester, l10n.lessonNext);
        }
        expect(find.text(l10n.lessonNextQuiz), findsOneWidget);
      });
    }
  }
}
