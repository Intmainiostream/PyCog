import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/home_screen.dart';
import 'package:pycog/screens/onboarding_screen.dart';
import 'package:pycog/screens/splash_screen.dart';
import 'package:pycog/widgets/chunky_button.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

final wordmark = find.byKey(const ValueKey('splash-wordmark'));
final skip = find.byKey(const ValueKey('onb-skip'));
final next = find.byKey(const ValueKey('onb-next'));

/// Starts the real app (with the splash) and stops right after the first
/// frame, so tests can watch the splash.
Future<SettingsController> launch(
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
  await tester.pumpWidget(
    PyCogApp(settings: settings, progress: await ProgressController.load()),
  );
  return settings;
}

double splashOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.ancestor(of: wordmark, matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Splash', () {
    testWidgets('the wordmark fades in, stays about 1.2 s, then fades out', (
      tester,
    ) async {
      await launch(tester, saved: {'app.onboardingSeen': true});
      expect(wordmark, findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(splashOpacity(tester), lessThan(0.1)); // starts invisible

      await tester.pump(SplashScreen.fade);
      expect(splashOpacity(tester), closeTo(1, 0.01)); // faded in
      await tester.pump(SplashScreen.hold - const Duration(milliseconds: 50));
      expect(splashOpacity(tester), closeTo(1, 0.01)); // still there
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      expect(splashOpacity(tester), lessThan(1)); // fading out
      await tester.pumpAndSettle();
      expect(wordmark, findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('screen readers hear "PyCog" on the splash', (tester) async {
      await launch(tester, saved: {'app.onboardingSeen': true});
      await tester.pump(SplashScreen.fade); // fully visible
      expect(find.bySemanticsLabel(en.appTitle), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Onboarding', () {
    testWidgets('first launch: splash, then 3 screens, then home', (
      tester,
    ) async {
      final settings = await launch(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text(en.onbTitle1), findsOneWidget);
      expect(find.text(en.onbText1), findsOneWidget);
      expect(skip, findsOneWidget);
      expect(find.text(en.onbNext), findsOneWidget);

      await tapAndSettle(tester, next);
      expect(find.text(en.onbTitle2), findsOneWidget);
      expect(find.text(en.onbText2), findsOneWidget);
      expect(skip, findsOneWidget);

      await tapAndSettle(tester, next);
      expect(find.text(en.onbTitle3), findsOneWidget);
      expect(find.text(en.onbText3), findsOneWidget);
      expect(skip, findsOneWidget);
      expect(find.text(en.onbStart), findsOneWidget);
      expect(find.text(en.onbNext), findsNothing);
      expect(settings.onboardingSeen, isFalse);

      await tapAndSettle(tester, next);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(settings.onboardingSeen, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.onboardingSeen'), isTrue);
    });

    testWidgets('Skip goes straight to home and is remembered', (tester) async {
      final settings = await launch(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, skip);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(settings.onboardingSeen, isTrue);
    });

    testWidgets('Skip works on the last screen too', (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, skip);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('later launches: splash, then home (no onboarding)', (
      tester,
    ) async {
      await launch(tester, saved: {'app.onboardingSeen': true});
      expect(wordmark, findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the language switch is on the first screen only', (
      tester,
    ) async {
      final settings = await launch(tester);
      await tester.pumpAndSettle();
      final language = find.byKey(const ValueKey('onb-language'));
      expect(language, findsOneWidget);
      await tapAndSettle(tester, find.text(en.languageTagalog));
      expect(settings.locale, SettingsController.tagalog);
      expect(find.text(tl.onbTitle1), findsOneWidget);
      expect(find.text(tl.onbSkip), findsOneWidget);

      await tapAndSettle(tester, next);
      expect(find.text(tl.onbTitle2), findsOneWidget);
      expect(language, findsNothing);
    });

    testWidgets('swiping also changes the screen', (tester) async {
      await launch(tester);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('onb-pages')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.onbTitle2), findsOneWidget);
    });
  });

  group('Fits a 360px phone', () {
    for (final lang in ['en', 'tl']) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('$lang, text x$scale: every screen fits, buttons 48px+', (
          tester,
        ) async {
          await launch(
            tester,
            saved: {'settings.language': lang, 'settings.textSize': 'large'},
            size: const Size(360, 640),
            systemScale: scale,
          );
          await tester.pumpAndSettle();
          for (var page = 0; page < OnboardingScreen.pageCount; page++) {
            expect(tester.takeException(), isNull, reason: 'page $page');
            for (final e in find.byType(ChunkyButton).evaluate()) {
              expect(e.size!.height, greaterThanOrEqualTo(48));
            }
            expect(skip.hitTestable(), findsOneWidget);
            expect(next.hitTestable(), findsOneWidget);
            await tapAndSettle(tester, next);
          }
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
