import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/minigame_progress.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/game_results_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/screens/quiz_screen.dart';
import 'package:pycog/theme/app_theme.dart';

import 'minigame_screen_test.dart' as mg;

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));
final recordKept = find.byKey(const ValueKey('results-record-kept'));

Future<ProgressController> lessonsWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return ProgressController.load();
}

Future<MinigameProgress> minigameWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return MinigameProgress.load();
}

Widget app(SettingsController settings, Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: settings.locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: home,
);

void main() {
  group('The first record is permanent', () {
    test('quiz: a better replay and a worse replay change nothing', () async {
      final progress = await lessonsWith({});
      expect(await progress.saveStars('variables', 2), isTrue);
      expect(await progress.saveStars('variables', 3), isFalse);
      expect(await progress.saveStars('variables', 1), isFalse);
      expect(progress.bestStars('variables'), 2);
      // After the app opens again too.
      expect((await ProgressController.load()).bestStars('variables'), 2);
    });

    test('lesson game: the same', () async {
      final progress = await lessonsWith({});
      expect(await progress.saveBonusStars('loops', 1), isTrue);
      expect(await progress.saveBonusStars('loops', 3), isFalse);
      expect(progress.bestBonusStars('loops'), 1);
    });

    test('MINIGAME challenge: the same', () async {
      final progress = await minigameWith({});
      expect(await progress.saveStars('mgL1C1', 3), isTrue);
      expect(await progress.saveStars('mgL1C1', 1), isFalse);
      expect(progress.bestStars('mgL1C1'), 3);
    });

    test(
      'a run with no star locks nothing; a later run becomes the record',
      () async {
        final progress = await lessonsWith({});
        expect(await progress.saveStars('variables', 0), isFalse);
        expect(progress.bestStars('variables'), 0);
        expect(progress.unlockedCount(lessons), 1);
        expect(await progress.saveStars('variables', 1), isTrue);
        expect(progress.unlockedCount(lessons), 2);

        final mg = await minigameWith({});
        expect(await mg.saveStars('mgL1C1', 0), isFalse);
        expect(await mg.saveStars('mgL1C1', 2), isTrue);
      },
    );

    test(
      'stars saved by earlier versions become the record (nothing lost)',
      () async {
        final progress = await lessonsWith({
          'progress.stars.variables': 1,
          'progress.bonus.variables': 2,
        });
        expect(progress.bestStars('variables'), 1);
        expect(await progress.saveStars('variables', 3), isFalse);
        expect(await progress.saveBonusStars('variables', 3), isFalse);
        expect(progress.bestStars('variables'), 1);
        expect(progress.bestBonusStars('variables'), 2);
        expect(progress.totalStars(lessons), 3);
        expect(progress.unlockedCount(lessons), 2);

        final mg = await minigameWith({'minigame.stars.mgL1C2': 1});
        expect(await mg.saveStars('mgL1C2', 3), isFalse);
        expect(mg.bestStars('mgL1C2'), 1);
      },
    );

    testWidgets('a quit quiz saves nothing', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsController.load();
      final progress = await ProgressController.load();
      await tester.pumpWidget(
        app(
          settings,
          QuizScreen(
            lesson: lessons.first,
            lessonNumber: 1,
            settings: settings,
            progress: progress,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox()); // the student leaves
      expect(progress.bestStars(lessons.first.id), 0);
      expect(progress.unlockedCount(lessons), 1);
    });
  });

  group('The replay note', () {
    for (final (lang, l10n) in [('en', en), ('tl', tl)]) {
      testWidgets('$lang: quiz results after a replay say the first score '
          'stays', (tester) async {
        SharedPreferences.setMockInitialValues({
          'settings.language': lang,
          'progress.stars.variables': 2,
        });
        final settings = await SettingsController.load();
        await tester.pumpWidget(
          app(
            settings,
            QuizResultsScreen(
              lesson: lessons.first,
              lessonNumber: 1,
              stars: 3,
              isNewBest: false,
              unlockedLessonNumber: null,
              settings: settings,
              progress: await ProgressController.load(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.recordKept), findsOneWidget);
        expect(find.text(l10n.resultsBest(2)), findsOneWidget); // the record
        expect(find.text(l10n.resultsNewBest), findsNothing);
      });
    }

    testWidgets('the first run shows "New record!" and no note', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'progress.bonus.variables': 2});
      final settings = await SettingsController.load();
      await tester.pumpWidget(
        app(
          settings,
          GameResultsScreen(
            lesson: lessons.first,
            lessonNumber: 1,
            stars: 2,
            isNewBest: true,
            settings: settings,
            progress: await ProgressController.load(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.resultsNewBest), findsOneWidget);
      expect(recordKept, findsNothing);
    });

    testWidgets('MINIGAME: solving again keeps the record and says so', (
      tester,
    ) async {
      final (progress, _) = await mg.pumpMap(
        tester,
        saved: {'minigame.stars.mgL1C1': 1},
      );
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect(find.textContaining(en.mgPassed(3)), findsOneWidget);
      expect(find.textContaining(en.recordKept), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 1);
    });
  });
}
