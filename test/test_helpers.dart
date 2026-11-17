import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The app now opens on the home screen (PLAY / MINIGAME / CODING). Tests
/// that work with the lesson trail call this right after starting the app:
/// it taps PLAY and waits for the trail to appear.
Future<void> openTrail(WidgetTester tester) async {
  final play = find.byKey(const ValueKey('home-play'));
  await tester.ensureVisible(play);
  await tester.pumpAndSettle();
  await tester.tap(play);
  await tester.pumpAndSettle();
}
