import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/screens/home_screen.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/trail_screen.dart';
import 'package:pycog/widgets/app_top_bar.dart';
import 'package:pycog/widgets/cog_art.dart';
import 'package:pycog/widgets/lesson_path.dart';
import 'package:pycog/widgets/speech_bubble.dart';
import 'package:pycog/widgets/star_counter.dart';

import 'home_test.dart' show startApp, en, tl;
import 'test_helpers.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(900, 500)]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: no Cog, no '
        'speech bubble, no "PyCog" title; the rest stays', (tester) async {
      await startApp(tester, size: size);
      await openTrail(tester);
      expect(find.byType(TrailScreen), findsOneWidget);
      expect(find.byType(CogArt), findsNothing);
      expect(find.byType(SpeechBubble), findsNothing);
      expect(find.text(en.cogGreeting), findsNothing);
      expect(find.text(en.appTitle), findsNothing);
      // Still there: back arrow, stars, gear, the "Lessons" header, the path.
      expect(find.bySemanticsLabel(en.homeBackToHome), findsOneWidget);
      expect(find.bySemanticsLabel(en.settingsTooltip), findsOneWidget);
      expect(find.byType(StarCounter), findsOneWidget);
      expect(find.text(en.lessonsHeader), findsOneWidget);
      expect(find.byType(LessonPath), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the top bar: back on the left, gear on the right, the header '
      'right under it', (tester) async {
    await startApp(tester, size: const Size(360, 640));
    await openTrail(tester);
    final bar = tester.getRect(find.byType(AppTopBar));
    final back = tester.getRect(find.bySemanticsLabel(en.homeBackToHome));
    final gear = tester.getRect(find.bySemanticsLabel(en.settingsTooltip));
    expect(back.left, lessThan(bar.width / 3));
    expect(gear.right, greaterThan(bar.width * 2 / 3));
    final header = tester.getRect(find.text(en.lessonsHeader));
    expect(header.top - bar.bottom, lessThan(40)); // no big empty gap
  });

  testWidgets('Tagalog, big text: fits', (tester) async {
    await startApp(
      tester,
      size: const Size(360, 640),
      systemScale: 1.5,
      saved: {'settings.language': 'tl', 'settings.textSize': 'large'},
    );
    await openTrail(tester);
    expect(find.text(tl.lessonsHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cog is still in the lessons themselves', (tester) async {
    await startApp(tester);
    await openTrail(tester);
    await tester.tap(find.byKey(const ValueKey('lesson-node-variables')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byType(CogArt), findsOneWidget);
  });

  testWidgets('back to home still works', (tester) async {
    await startApp(tester);
    await openTrail(tester);
    await tester.tap(find.bySemanticsLabel(en.homeBackToHome));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
