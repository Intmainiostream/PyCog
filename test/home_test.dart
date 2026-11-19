import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/coding_screen.dart';
import 'package:pycog/screens/coming_soon_screen.dart';
import 'package:pycog/screens/game_results_screen.dart';
import 'package:pycog/screens/home_screen.dart';
import 'package:pycog/screens/minigame_map_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/screens/trail_screen.dart';
import 'package:pycog/widgets/chunky_button.dart';
import 'package:pycog/widgets/cloud_footer.dart';
import 'package:pycog/widgets/lesson_path.dart';

import 'test_helpers.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

final play = find.byKey(const ValueKey('home-play'));
final minigame = find.byKey(const ValueKey('home-minigame'));
final coding = find.byKey(const ValueKey('home-coding'));

Future<(SettingsController, ProgressController)> startApp(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  Size size = const Size(800, 1000),
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues(saved);
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  await tester.pumpWidget(
    PyCogApp(intro: false, settings: settings, progress: progress),
  );
  await tester.pumpAndSettle();
  return (settings, progress);
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Every chunky button on screen is at least 48x48.
void expectBigEnough(WidgetTester tester) {
  for (final e in find.byType(ChunkyButton).evaluate()) {
    expect(
      e.size!.width >= 48 && e.size!.height >= 48,
      isTrue,
      reason: 'ChunkyButton is only ${e.size}',
    );
  }
}

void main() {
  group('Home screen', () {
    testWidgets('the app opens on the home screen with 3 buttons', (
      tester,
    ) async {
      await startApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(TrailScreen), findsNothing);
      expect(find.text(en.homeGreeting), findsOneWidget);
      expect(find.text(en.homePlay), findsOneWidget);
      expect(find.text(en.homeMinigame), findsOneWidget);
      expect(find.text(en.homeCoding), findsOneWidget);
      for (final icon in [
        Icons.play_arrow_rounded,
        Icons.extension_rounded,
        Icons.code_rounded,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('stars on the home screen add up saved progress', (
      tester,
    ) async {
      final (_, progress) = await startApp(
        tester,
        saved: {'progress.stars.variables': 2, 'progress.bonus.variables': 3},
      );
      expect(find.bySemanticsLabel(en.starsCount(5)), findsOneWidget);

      // And they update live when progress changes.
      await progress.saveStars('data_types', 3);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(en.starsCount(8)), findsOneWidget);
    });

    testWidgets('PLAY opens the trail; its back arrow returns home', (
      tester,
    ) async {
      await startApp(tester);
      await tapAndSettle(tester, play);
      expect(find.byType(TrailScreen), findsOneWidget);
      expect(find.text(en.lessonsHeader), findsOneWidget);

      await tapAndSettle(tester, find.bySemanticsLabel(en.homeBackToHome));
      expect(find.byType(TrailScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('MINIGAME opens the level map; the back arrow returns', (
      tester,
    ) async {
      await startApp(tester, saved: {'minigame.stars.mgL1C1': 3});
      await tapAndSettle(tester, minigame);
      expect(find.byType(MinigameMapScreen), findsOneWidget);
      expect(find.byType(ComingSoonScreen), findsNothing);
      expect(find.text(en.mgMapTitle), findsOneWidget);
      // Saved MINIGAME stars show on Level 1.
      expect(find.text('3/30'), findsOneWidget);

      await tapAndSettle(tester, find.bySemanticsLabel(en.homeBackToHome));
      expect(find.byType(MinigameMapScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('CODING opens the playground; the back arrow returns', (
      tester,
    ) async {
      await startApp(tester);
      await tapAndSettle(tester, coding);
      expect(find.byType(CodingScreen), findsOneWidget);
      expect(find.byType(ComingSoonScreen), findsNothing);
      expect(find.text(en.codingTitle), findsOneWidget);

      await tapAndSettle(tester, find.byIcon(Icons.arrow_back_rounded).first);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('switching language updates the home screen', (tester) async {
      final (settings, _) = await startApp(tester);
      settings.setLocale(SettingsController.tagalog);
      await tester.pumpAndSettle();
      expect(find.text(tl.homePlay), findsOneWidget); // LARO
      expect(find.text(tl.homeGreeting), findsOneWidget);
    });
  });

  group('"Back to lessons" still returns to the trail', () {
    Future<void> pushOnTrail(WidgetTester tester, Widget screen) async {
      await tapAndSettle(tester, play);
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => screen));
      await tester.pumpAndSettle();
    }

    testWidgets('from the quiz results', (tester) async {
      final (settings, progress) = await startApp(tester);
      await pushOnTrail(
        tester,
        QuizResultsScreen(
          lesson: lessons.first,
          lessonNumber: 1,
          stars: 3,
          isNewBest: false,
          unlockedLessonNumber: null,
          settings: settings,
          progress: progress,
        ),
      );
      await tapAndSettle(tester, find.text(en.resultsBackToLessons));
      expect(find.byType(TrailScreen), findsOneWidget);
      expect(find.text(en.lessonsHeader), findsOneWidget);
    });

    testWidgets('from the game results', (tester) async {
      final (settings, progress) = await startApp(tester);
      await pushOnTrail(
        tester,
        GameResultsScreen(
          lesson: lessons.first,
          lessonNumber: 1,
          stars: 2,
          isNewBest: false,
          settings: settings,
          progress: progress,
        ),
      );
      await tapAndSettle(tester, find.text(en.resultsBackToLessons));
      expect(find.byType(TrailScreen), findsOneWidget);
    });
  });

  group('Clouds at the end of the trail', () {
    testWidgets('after Lesson 5, in English and Tagalog', (tester) async {
      final (settings, _) = await startApp(tester);
      await openTrail(tester);

      final path = tester.widget<LessonPath>(find.byType(LessonPath));
      expect(path.showTail, isTrue); // the path runs on into the clouds

      final clouds = find.byType(CloudFooter);
      await tester.scrollUntilVisible(
        clouds,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      // Below the last lesson.
      expect(
        tester.getTopLeft(clouds).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.byKey(ValueKey('lesson-node-${lessons.last.id}')),
              )
              .dy,
        ),
      );
      expect(find.text(en.cloudsMoreLessons), findsOneWidget);

      settings.setLocale(SettingsController.tagalog);
      await tester.pumpAndSettle();
      expect(find.text(tl.cloudsMoreLessons), findsOneWidget);
    });

    testWidgets('the clouds are not tappable', (tester) async {
      await startApp(tester);
      await openTrail(tester);
      final clouds = find.byType(CloudFooter);
      for (final type in [GestureDetector, ChunkyButton, InkWell]) {
        expect(
          find.descendant(of: clouds, matching: find.byType(type)),
          findsNothing,
        );
      }
    });
  });

  // New screens on many sizes with big text, both languages: no overflow
  // (it would throw) and 48px buttons.
  const sizes = {
    '360x640': Size(360, 640),
    '640x360': Size(640, 360),
    '800x1280': Size(800, 1280),
    '1280x800': Size(1280, 800),
  };
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final lang in ['en', 'tl']) {
      testWidgets('new screens fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await startApp(
          tester,
          size: size,
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        expectBigEnough(tester); // home

        for (final button in [minigame, coding]) {
          await tapAndSettle(tester, button);
          expectBigEnough(tester); // the level map, or the playground
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
          // (The back buttons themselves are tested above.)
          tester.state<NavigatorState>(find.byType(Navigator)).pop();
          await tester.pumpAndSettle();
        }

        await tapAndSettle(tester, play);
        expectBigEnough(tester); // trail top bar with back arrow
        await tester.scrollUntilVisible(
          find.byType(CloudFooter),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
        await tester.pumpAndSettle(); // clouds fully in view, no overflow
      });
    }
  }
}
