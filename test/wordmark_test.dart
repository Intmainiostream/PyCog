import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/screens/trail_screen.dart';
import 'package:pycog/widgets/app_top_bar.dart';

import 'home_test.dart' show startApp, en, tl, play, minigame, coding;
import 'test_helpers.dart';

final wordmark = find.byKey(const ValueKey('app-wordmark'));

/// Width and height of a PNG file, read from its header.
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

void main() {
  test('the wordmark picture is in the app and its shape matches the code', () {
    final (w, h) = pngSize(AppTopBar.wordmarkAsset);
    expect(w / h, closeTo(AppTopBar.wordmarkAspect, 0.001));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/branding/'),
    );
  });

  testWidgets('home shows the PyCog wordmark as the title; screen readers '
      'still hear "PyCog"', (tester) async {
    await startApp(tester);
    expect(wordmark, findsOneWidget);
    expect(find.text(en.appTitle), findsNothing);
    expect(find.bySemanticsLabel(en.appTitle), findsOneWidget);
  });

  testWidgets('the lesson trail has no title (no wordmark, no "PyCog" '
      'text)', (tester) async {
    await startApp(tester);
    await openTrail(tester);
    expect(find.byType(TrailScreen), findsOneWidget);
    expect(wordmark, findsNothing);
    expect(find.text(en.appTitle), findsNothing);
  });

  testWidgets('the wordmark does not make the top bar taller, so the home '
      'buttons stay where they were', (tester) async {
    await startApp(tester, size: const Size(360, 640));
    final homeBar = tester.getSize(find.byType(AppTopBar));
    await openTrail(tester);
    final trailBar = tester.getSize(find.byType(AppTopBar));
    expect(homeBar.height, trailBar.height);
  });

  for (final lang in ['en', 'tl']) {
    testWidgets('360x640, $lang: the wordmark fits between the stars and the '
        'gear', (tester) async {
      await startApp(
        tester,
        size: const Size(360, 640),
        saved: {'settings.language': lang},
      );
      expect(tester.takeException(), isNull);
      final l10n = lang == 'en' ? en : tl;
      expect(find.text(l10n.homePlay), findsOneWidget);
      final mark = tester.getRect(wordmark);
      final bar = tester.getRect(find.byType(AppTopBar));
      expect(mark.left, greaterThanOrEqualTo(bar.left));
      expect(mark.right, lessThanOrEqualTo(bar.right));
      expect(mark.height, lessThanOrEqualTo(48));
      // The title sits above the buttons.
      for (final button in [play, minigame, coding]) {
        expect(tester.getTopLeft(button).dy, greaterThan(mark.bottom));
      }
    });
  }
}
