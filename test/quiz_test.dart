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
import 'package:pycog/models/quiz.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/theme/app_theme.dart';

import 'test_helpers.dart';

final variables = lessons.first;
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// Finds text that may be split into styled pieces (e.g. `code` words).
Finder textHas(String text) => find.textContaining(text, findRichText: true);

Finder answer(int question, int answerIndex) =>
    find.byKey(ValueKey('answer-$question-$answerIndex'));

/// Index of the first wrong answer of a question (in the data, not on screen).
int wrongIndex(QuizQuestion q, [int nth = 0]) => [
  for (var i = 0; i < q.answers.length; i++)
    if (!q.answers[i].correct) i,
][nth];

Future<(SettingsController, ProgressController)> pumpQuiz(
  WidgetTester tester, {
  Lesson? lesson,
}) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  await tester.pumpWidget(
    ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: QuizScreen(
          lesson: lesson ?? variables,
          lessonNumber: 1,
          settings: settings,
          progress: progress,
          random: math.Random(7),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, progress);
}

Future<void> tapAnswerAndCheck(WidgetTester tester, int q, int i) async {
  await tester.ensureVisible(answer(q, i));
  await tester.tap(answer(q, i));
  await tester.pump();
  await tester.tap(find.text(en.quizCheck));
  await tester.pumpAndSettle();
}

Future<void> tapNext(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Tagalog star counts show the real number', () {
    // Tagalog plural rules put 2 (and 3, 5, 7...) in the "one" category, so
    // a "=1{1 star}" branch would wrongly print "1" for 2 stars. The TL
    // strings must always include the number itself.
    test('resultsBest and starsCount', () {
      for (final n in [1, 2, 3]) {
        expect(tl.resultsBest(n), contains('$n'));
        expect(tl.starsCount(n), contains('$n'));
        expect(en.resultsBest(n), contains('$n'));
        expect(en.starsCount(n), contains('$n'));
      }
    });
  });

  group('Star scoring', () {
    test('3 stars for no mistakes', () => expect(starsForMistakes(0), 3));
    test('2 stars for 1 or 2 mistakes', () {
      expect(starsForMistakes(1), 2);
      expect(starsForMistakes(2), 2);
    });
    test('1 star for more mistakes', () {
      expect(starsForMistakes(3), 1);
      expect(starsForMistakes(10), 1);
    });
  });

  testWidgets('Right answer: turns green, Cog cheers, Next appears', (
    tester,
  ) async {
    await pumpQuiz(tester);
    final q = variables.quiz[0];

    // Check is disabled until an answer is picked.
    expect(find.text(en.quizPickAnswer), findsOneWidget);

    await tapAnswerAndCheck(tester, 0, q.correctIndex);

    expect(textHas(en.quizCheer1), findsOneWidget);
    expect(textHas(en.quiz1Q1Explain), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text(en.quizNext), findsOneWidget);
    expect(find.text(en.quizCheck), findsNothing);
  });

  testWidgets('Wrong answer: red, gentle hint, try again, no answer shown', (
    tester,
  ) async {
    await pumpQuiz(tester);
    final q = variables.quiz[0];
    final wrong = wrongIndex(q);

    await tapAnswerAndCheck(tester, 0, wrong);

    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(textHas(q.answers[wrong].whyWrong!(en)), findsOneWidget);
    expect(textHas(en.quizTryAgain), findsOneWidget);
    // The right answer is NOT revealed yet, and we can't move on.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(textHas('The right answer is'), findsNothing);
    expect(find.text(en.quizNext), findsNothing);
    expect(find.text(en.quizCheck), findsOneWidget);
  });

  testWidgets('Two wrong tries reveal the answer and allow moving on', (
    tester,
  ) async {
    await pumpQuiz(tester);
    final q = variables.quiz[0];

    await tapAnswerAndCheck(tester, 0, wrongIndex(q, 0));
    await tapAnswerAndCheck(tester, 0, wrongIndex(q, 1));

    expect(textHas('The right answer is'), findsOneWidget);
    expect(textHas(en.quiz1Q1Explain), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(2));

    await tapNext(tester, en.quizNext);
    // Now on question 2: its prompt is shown, question 1's is gone.
    expect(textHas('In this code'), findsOneWidget);
    expect(textHas(en.quiz1Q1Prompt), findsNothing);
    expect(find.text(en.quizPickAnswer), findsOneWidget);
  });

  testWidgets('Language switch updates the quiz immediately', (tester) async {
    final (settings, _) = await pumpQuiz(tester);
    final q = variables.quiz[0];
    final wrong = wrongIndex(q);
    await tapAnswerAndCheck(tester, 0, wrong);

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();

    expect(textHas(tl.quiz1Q1Prompt), findsOneWidget);
    expect(textHas(q.answers[wrong].whyWrong!(tl)), findsOneWidget);
    expect(find.text(tl.quizCheck), findsOneWidget);
    // Same state: the wrong answer is still marked.
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });

  testWidgets('True/false questions show True then False', (tester) async {
    final lesson = Lesson(
      id: 'tf_test',
      icon: Icons.quiz,
      title: (l10n) => 'Test',
      quiz: [
        QuizQuestion.trueFalse(
          prompt: (l10n) => 'Is `x = 1` a variable?',
          answerIsTrue: true,
          whyWrong: (l10n) => 'Look again!',
          explanation: (l10n) => 'Yes, x is a variable.',
        ),
      ],
    );
    await pumpQuiz(tester, lesson: lesson);

    final trueY = tester.getTopLeft(answer(0, 0)).dy;
    final falseY = tester.getTopLeft(answer(0, 1)).dy;
    expect(trueY, lessThan(falseY));
    expect(find.text(en.quizTrue), findsOneWidget);

    await tapAnswerAndCheck(tester, 0, 1);
    expect(textHas('Look again!'), findsOneWidget);
  });

  group('Saved progress', () {
    test(
      'keeps the best stars, adds them up, unlocks the next lesson',
      () async {
        final progress = await ProgressController.load();
        expect(progress.unlockedCount(lessons), 1);
        expect(progress.totalStars(lessons), 0);

        expect(await progress.saveStars('variables', 2), isTrue);
        expect(await progress.saveStars('variables', 1), isFalse); // worse
        expect(progress.bestStars('variables'), 2);
        expect(progress.unlockedCount(lessons), 2);

        expect(await progress.saveStars('variables', 3), isTrue);
        final reloaded = await ProgressController.load();
        expect(reloaded.bestStars('variables'), 3);
        expect(reloaded.totalStars(lessons), 3);
      },
    );

    testWidgets('perfect quiz saves 3 stars and the home screen shows them', (
      tester,
    ) async {
      final (settings, progress) = await pumpQuiz(tester);

      for (var q = 0; q < variables.quiz.length; q++) {
        await tapAnswerAndCheck(tester, q, variables.quiz[q].correctIndex);
        final isLast = q == variables.quiz.length - 1;
        await tapNext(tester, isLast ? en.quizSeeResults : en.quizNext);
      }

      // Results screen
      expect(find.text(en.resultsTitle), findsOneWidget);
      expect(find.bySemanticsLabel(en.starsCount(3)), findsOneWidget);
      expect(textHas(en.results3Stars), findsOneWidget);
      expect(find.text(en.resultsUnlocked(2)), findsOneWidget);
      expect(progress.bestStars('variables'), 3);

      // A fresh app start reads the saved stars.
      await tester.pumpWidget(
        PyCogApp(settings: settings, progress: await ProgressController.load()),
      );
      await tester.pumpAndSettle();
      await openTrail(tester); // app opens on the home screen
      expect(find.bySemanticsLabel(en.starsCount(3)), findsOneWidget);
      // Lessons 1 and 2 open, the rest locked.
      expect(
        find.byIcon(Icons.lock_rounded),
        findsNWidgets(lessons.length - 2),
      );
    });

    testWidgets('mistakes give fewer stars; a worse try keeps the best', (
      tester,
    ) async {
      final (_, progress) = await pumpQuiz(tester);
      await progress.saveStars('variables', 3); // an earlier perfect run

      for (var q = 0; q < variables.quiz.length; q++) {
        final question = variables.quiz[q];
        if (q < 3) await tapAnswerAndCheck(tester, q, wrongIndex(question));
        await tapAnswerAndCheck(tester, q, question.correctIndex);
        final isLast = q == variables.quiz.length - 1;
        await tapNext(tester, isLast ? en.quizSeeResults : en.quizNext);
      }

      expect(find.bySemanticsLabel(en.starsCount(1)), findsOneWidget);
      expect(textHas(en.results1Star), findsOneWidget);
      expect(find.text(en.resultsNewBest), findsNothing);
      expect(progress.bestStars('variables'), 3); // best is kept
    });
  });
}
