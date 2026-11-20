import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/screens/about_screen.dart';
import 'package:pycog/screens/coding_screen.dart';
import 'package:pycog/widgets/settings_sheet.dart';

import 'home_test.dart' as home;

final aboutRow = find.byKey(const ValueKey('settings-about'));

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_rounded).first);
  await tester.pumpAndSettle();
  expect(find.byType(SettingsSheet), findsOneWidget);
}

void main() {
  for (final lang in ['en', 'tl']) {
    testWidgets('$lang: Settings has an "About PyCog" row that opens the '
        'About screen', (tester) async {
      final l10n = lang == 'en' ? home.en : home.tl;
      await home.startApp(tester, saved: {'settings.language': lang});
      await openSettings(tester);
      expect(
        find.descendant(of: aboutRow, matching: find.text(l10n.aboutTitle)),
        findsOneWidget,
      );
      await tester.ensureVisible(aboutRow);
      await tester.pumpAndSettle();
      await tester.tap(aboutRow);
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text(l10n.aboutText), findsOneWidget);
    });
  }

  testWidgets('the licenses page is still reachable from About', (
    tester,
  ) async {
    await home.startApp(tester);
    await openSettings(tester);
    await tester.ensureVisible(aboutRow);
    await tester.pumpAndSettle();
    await tester.tap(aboutRow);
    await tester.pumpAndSettle();
    final notices = find.byKey(const ValueKey('about-notices'));
    await tester.ensureVisible(notices);
    await tester.pumpAndSettle();
    await tester.tap(notices);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('About is in one place only: not on CODING any more', (
    tester,
  ) async {
    await home.startApp(tester);
    await home.tapAndSettle(tester, home.coding);
    expect(find.byType(CodingScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('coding-about')), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text(home.en.aboutTitle), findsNothing);
  });

  for (final lang in ['en', 'tl']) {
    testWidgets('360x640, $lang, big text: Settings with the About row fits', (
      tester,
    ) async {
      await home.startApp(
        tester,
        size: const Size(360, 640),
        systemScale: 1.5,
        saved: {'settings.language': lang, 'settings.textSize': 'large'},
      );
      await openSettings(tester);
      await tester.ensureVisible(aboutRow);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(aboutRow).height, greaterThanOrEqualTo(48));
    });
  }
}
