import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/app_info.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/about_screen.dart';
import 'package:pycog/theme/app_theme.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

final aboutText = find.byKey(const ValueKey('about-text'));
final version = find.byKey(const ValueKey('about-version'));
final notices = find.byKey(const ValueKey('about-notices'));

Future<void> pumpAbout(
  WidgetTester tester, {
  String lang = 'en',
  Size size = const Size(800, 1200),
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({'settings.language': lang});
  final settings = await SettingsController.load();
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
        home: AboutScreen(settings: settings),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the version on the About screen is the one in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':').last.trim().split('+').first, appVersion);
  });

  for (final (lang, l10n) in [('en', en), ('tl', tl)]) {
    testWidgets('$lang: title, the About text and the version', (tester) async {
      await pumpAbout(tester, lang: lang);
      expect(find.text(l10n.aboutTitle), findsOneWidget);
      expect(find.text(l10n.aboutText), findsOneWidget);
      expect(find.text(l10n.aboutVersion(appVersion)), findsOneWidget);
      expect(find.text(l10n.aboutNotices), findsOneWidget);
    });
  }

  test('the English text says what was asked', () {
    expect(
      en.aboutText,
      'PyCog was made to help students learn the basics of Python '
      'programming. It is not only about robotics, and it is not based on '
      'any DepEd curriculum. PyCog is a free app, created by Joshua.',
    );
    expect(tl.aboutText, allOf(contains('DepEd'), contains('Joshua')));
  });

  testWidgets('the notices link is small, light gray and at the very bottom', (
    tester,
  ) async {
    await pumpAbout(tester);
    final text = tester.widget<Text>(
      find.descendant(of: notices, matching: find.byType(Text)),
    );
    final style = DefaultTextStyle.of(
      tester.element(find.text(en.aboutNotices)),
    ).style.merge(text.style);
    expect(style.fontSize, lessThanOrEqualTo(12));
    expect(style.color, AppColors.textFaint);
    // Below everything else, near the bottom edge of the screen.
    expect(
      tester.getTopLeft(notices).dy,
      greaterThan(tester.getBottomLeft(version).dy - 1),
    );
    expect(
      tester.getTopLeft(version).dy,
      greaterThan(tester.getBottomLeft(aboutText).dy),
    );
    expect(tester.getBottomLeft(notices).dy, greaterThan(1200 - 80));
    // Small text, but still easy to tap.
    expect(tester.getSize(notices).height, greaterThanOrEqualTo(48));
  });

  testWidgets('the notices link opens the license page', (tester) async {
    await pumpAbout(tester);
    await tester.tap(notices);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('the bundled license files are still in the app', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final asset in [
      'assets/fonts/OFL-Fredoka.txt',
      'assets/fonts/OFL-Nunito.txt',
      'assets/fonts/OFL-JetBrainsMono.txt',
    ]) {
      expect(pubspec, contains('- $asset'));
      expect(await rootBundle.loadString(asset), isNotEmpty, reason: asset);
    }
    expect(pubspec, contains('- assets/pyodide/'));
    for (final asset in [
      'assets/pyodide/LICENSE-pyodide.txt',
      'assets/pyodide/LICENSE-cpython.txt',
    ]) {
      expect(await rootBundle.loadString(asset), isNotEmpty, reason: asset);
    }
  });

  for (final lang in ['en', 'tl']) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('360x640, $lang, text x$scale: everything fits', (
        tester,
      ) async {
        await pumpAbout(
          tester,
          lang: lang,
          size: const Size(360, 640),
          systemScale: scale,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(notices);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(notices.hitTestable(), findsOneWidget);
      });
    }
  }
}
