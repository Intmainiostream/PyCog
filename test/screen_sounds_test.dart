import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/playground/python_runner.dart';
import 'package:pycog/screens/game_results_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/sound/sounds.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/chunky_button.dart';

import 'coding_screen_test.dart' as coding;
import 'fake_sounds.dart';
import 'game_test.dart' as game;
import 'home_test.dart' as home;
import 'minigame_screen_test.dart' as mg;
import 'quiz_test.dart' as quiz;

final en = lookupAppLocalizations(const Locale('en'));

Widget app(SettingsController settings, Widget screen) => MaterialApp(
  theme: AppTheme.light,
  locale: settings.locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: screen,
);

void main() {
  group('Buttons', () {
    testWidgets('one tap sound per press', (tester) async {
      final sounds = useFakeSounds();
      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ChunkyButton(onTap: () => pressed++, child: const Text('Go')),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(pressed, 1);
      expect(sounds.played, [Sfx.tap]);
    });

    testWidgets('a disabled button makes no sound', (tester) async {
      final sounds = useFakeSounds();
      await tester.pumpWidget(
        const MaterialApp(home: ChunkyButton(onTap: null, child: Text('Go'))),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(sounds.played, isEmpty);
    });

    testWidgets('home buttons tap; with "Sound effects" off, nothing plays', (
      tester,
    ) async {
      final sounds = useFakeSounds();
      final (settings, _) = await home.startApp(tester);
      await home.tapAndSettle(tester, home.play);
      expect(sounds.played, [Sfx.tap]);

      sounds.clear();
      settings.setSoundOn(false);
      await mg.goBack(tester);
      await home.tapAndSettle(tester, home.play);
      expect(sounds.played, isEmpty);
    });
  });

  group('Lesson quiz', () {
    testWidgets('right answer: correct', (tester) async {
      final sounds = useFakeSounds();
      await quiz.pumpQuiz(tester);
      await quiz.tapAnswerAndCheck(
        tester,
        0,
        quiz.variables.quiz[0].correctIndex,
      );
      expect(sounds.played.last, Sfx.correct);
      expect(sounds.played, isNot(contains(Sfx.wrong)));
    });

    testWidgets('wrong answer: wrong', (tester) async {
      final sounds = useFakeSounds();
      await quiz.pumpQuiz(tester);
      await quiz.tapAnswerAndCheck(
        tester,
        0,
        quiz.wrongIndex(quiz.variables.quiz[0]),
      );
      expect(sounds.played.last, Sfx.wrong);
      expect(sounds.played, isNot(contains(Sfx.correct)));
    });
  });

  group('Results screens', () {
    for (final stars in [1, 2, 3]) {
      testWidgets('quiz results, $stars stars: finish, then $stars star '
          'sounds', (tester) async {
        final sounds = useFakeSounds();
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsController.load();
        await tester.pumpWidget(
          app(
            settings,
            QuizResultsScreen(
              lesson: lessons.first,
              lessonNumber: 1,
              stars: stars,
              isNewBest: false,
              unlockedLessonNumber: null,
              settings: settings,
              progress: await ProgressController.load(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(sounds.played, [
          Sfx.finish,
          for (var i = 0; i < stars; i++) Sfx.star,
        ]);
      });
    }

    testWidgets('game results: one star sound per star, only once', (
      tester,
    ) async {
      final sounds = useFakeSounds();
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsController.load();
      await tester.pumpWidget(
        app(
          settings,
          GameResultsScreen(
            lesson: lessons.first,
            lessonNumber: 1,
            stars: 2,
            isNewBest: false,
            settings: settings,
            progress: await ProgressController.load(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      settings.setTextSize(TextSize.large); // redraws the screen
      await tester.pumpAndSettle();
      expect(sounds.played, [Sfx.star, Sfx.star]);
    });
  });

  group('Game', () {
    testWidgets('right box: correct; wrong box: wrong', (tester) async {
      final sounds = useFakeSounds();
      await game.pumpGame(tester);
      await home.tapAndSettle(tester, game.chip(0, '80'));
      await home.tapAndSettle(tester, game.box(0, 'wheels'));
      expect(sounds.played.last, Sfx.wrong);
      await home.tapAndSettle(tester, game.chip(0, '80'));
      await home.tapAndSettle(tester, game.box(0, 'battery'));
      expect(sounds.played.last, Sfx.correct);
    });
  });

  group('MINIGAME', () {
    testWidgets('quiz: a wrong pick is wrong; the right one is correct, '
        'then the stars', (tester) async {
      final sounds = useFakeSounds();
      await mg.pumpMap(tester);
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('100'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(sounds.played.last, Sfx.wrong);
      sounds.clear();
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(sounds.played, [
        Sfx.tap,
        Sfx.tap,
        Sfx.correct,
        Sfx.star,
        Sfx.star,
      ]);
    });

    testWidgets('a hint opens: hint', (tester) async {
      final sounds = useFakeSounds();
      await mg.pumpMap(tester);
      await mg.openChallenge(tester, 'mgL1C3');
      sounds.clear();
      await mg.tapAndSettle(tester, mg.key('mg-hint'));
      expect(sounds.played.last, Sfx.hint);
    });

    testWidgets('code challenge: a wrong run is wrong; solved is finish, then '
        'the stars', (tester) async {
      final sounds = useFakeSounds();
      await mg.pumpMap(tester);
      await mg.openChallenge(tester, 'mgL1C3');
      await tester.enterText(mg.key('mg-code'), 'speed = 5\nprint(Speed)');
      await mg.tapAndSettle(tester, mg.key('mg-run'));
      expect(sounds.played.last, Sfx.wrong);
      sounds.clear();
      await tester.enterText(mg.key('mg-code'), 'speed = 5\nprint(speed)');
      await mg.tapAndSettle(tester, mg.key('mg-run'));
      expect(sounds.played, [
        Sfx.tap,
        Sfx.finish,
        Sfx.star,
        Sfx.star,
        Sfx.star,
      ]);
    });

    testWidgets('a quiz that opens the next level: finish', (tester) async {
      final sounds = useFakeSounds();
      // 6 of Level 1 done: the 7th opens Level 2.
      await mg.pumpMap(
        tester,
        saved: {
          for (final c in [2, 3, 4, 5, 6, 7]) 'minigame.stars.mgL1C$c': 1,
        },
      );
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('80'));
      sounds.clear();
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(find.textContaining(en.mgUnlocked(2)), findsOneWidget);
      expect(sounds.played, [
        Sfx.tap,
        Sfx.finish,
        Sfx.star,
        Sfx.star,
        Sfx.star,
      ]);
    });

    testWidgets('the Level 10 ending card: victory', (tester) async {
      final sounds = useFakeSounds();
      await mg.pumpMap(
        tester,
        size: const Size(800, 2400),
        saved: {
          for (var l = 1; l <= 10; l++)
            for (var c = 1; c <= 10; c++) 'minigame.stars.mgL${l}C$c': 1,
        },
      );
      expect(sounds.played, isNot(contains(Sfx.victory)));
      await mg.tapAndSettle(tester, mg.key('mg-level-10'));
      expect(sounds.played.last, Sfx.victory);
      expect(sounds.played.where((s) => s == Sfx.victory).length, 1);
    });

    testWidgets('other full levels: no victory', (tester) async {
      final sounds = useFakeSounds();
      await mg.pumpMap(
        tester,
        saved: {for (var c = 1; c <= 10; c++) 'minigame.stars.mgL1C$c': 1},
      );
      await mg.tapAndSettle(tester, mg.key('mg-level-1'));
      expect(sounds.played, isNot(contains(Sfx.victory)));
    });
  });

  group('CODING', () {
    testWidgets('Run: run, then output when there is no error', (tester) async {
      final sounds = useFakeSounds();
      await coding.pumpCoding(tester);
      await coding.tapRun(tester);
      expect(sounds.played, [Sfx.tap, Sfx.run, Sfx.output]);
    });

    testWidgets('an error: no output sound', (tester) async {
      final sounds = useFakeSounds();
      final (engine, _) = await coding.pumpCoding(tester);
      engine.next = const PythonResult(
        stdout: '',
        error: 'NameError: name x is not defined',
        elapsed: Duration.zero,
      );
      await coding.tapRun(tester);
      expect(sounds.played, [Sfx.tap, Sfx.run]);
    });
  });
}
