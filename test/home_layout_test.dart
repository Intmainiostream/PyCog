import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/screens/trail_screen.dart';
import 'package:pycog/theme/app_theme.dart';

import 'home_test.dart' show startApp, play, minigame, coding, tapAndSettle;

final cog = find.byKey(const ValueKey('home-cog'));
final bubble = find.byKey(const ValueKey('home-bubble'));

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(411, 891),
    const Size(800, 1000),
  ]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: a small Cog, '
        'a compact bubble, narrower centered buttons', (tester) async {
      await startApp(tester, size: size);
      final cogSize = tester.getSize(cog);
      expect(cogSize.height, inInclusiveRange(80, 96));

      final buttons = [play, minigame, coding].map(tester.getRect).toList();
      final width = buttons.first.width;
      for (final b in buttons) {
        expect(b.width, width); // all three the same width
        expect(b.height, greaterThanOrEqualTo(48));
        // Centered on the screen.
        expect(b.center.dx, closeTo(size.width / 2, 1));
      }
      expect(width, lessThanOrEqualTo(AppSizes.homeButtonMaxWidth));
      final content = size.width - 2 * AppSizes.screenPadding;
      expect(width, lessThan(content * 0.8));
      if (content * AppSizes.homeButtonWidthFraction <
          AppSizes.homeButtonMaxWidth) {
        expect(
          width / content,
          closeTo(AppSizes.homeButtonWidthFraction, 0.01),
        );
      }

      // Cog and his bubble are no longer as wide as the buttons.
      expect(cogSize.width, lessThan(width));
      expect(tester.getSize(bubble).width, lessThanOrEqualTo(width));
    });
  }

  for (final lang in ['en', 'tl']) {
    testWidgets('360x640, $lang, very big text: fits, buttons 48px+', (
      tester,
    ) async {
      await startApp(
        tester,
        size: const Size(360, 640),
        systemScale: 1.5,
        saved: {'settings.language': lang, 'settings.textSize': 'large'},
      );
      expect(tester.takeException(), isNull);
      for (final b in [play, minigame, coding]) {
        await tester.ensureVisible(b);
        await tester.pumpAndSettle();
        expect(tester.getSize(b).height, greaterThanOrEqualTo(48));
        expect(b.hitTestable(), findsOneWidget);
      }
    });
  }

  testWidgets('the buttons still do the same thing', (tester) async {
    await startApp(tester, size: const Size(360, 640));
    await tapAndSettle(tester, play);
    expect(find.byType(TrailScreen), findsOneWidget);
  });
}
