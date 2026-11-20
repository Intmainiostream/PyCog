import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/fog_footer.dart';

import 'home_test.dart' show startApp, en, tl;
import 'test_helpers.dart';

final fogPaint = find.byKey(const ValueKey('fog-paint'));

double fogTime(WidgetTester tester) =>
    (tester.widget<CustomPaint>(fogPaint).painter! as FogPainter).time.value;

/// The fog alone, with or without "reduce motion".
Future<void> pumpFog(WidgetTester tester, {bool reduceMotion = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: const Scaffold(
            body: SingleChildScrollView(child: FogFooter()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// True if [text] has an emoji (or another pictograph) in it.
bool hasEmoji(String text) => text.runes.any(
  (r) =>
      (r >= 0x1F000 && r <= 0x1FAFF) || // emoji and pictographs
      (r >= 0x2600 && r <= 0x27BF) || // symbols and dingbats
      (r >= 0x2B00 && r <= 0x2BFF) || // stars, arrows
      r == 0xFE0F, // emoji style
);

void main() {
  group('Fog after the last lesson', () {
    testWidgets('it shows below the last lesson, with the text, in English '
        'and Tagalog', (tester) async {
      final (settings, _) = await startApp(tester);
      await openTrail(tester);
      final fog = find.byType(FogFooter);
      await tester.scrollUntilVisible(
        fog,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      final lastNode = find.byKey(ValueKey('lesson-node-${lessons.last.id}'));
      expect(
        tester.getTopLeft(fog).dy,
        greaterThan(tester.getCenter(lastNode).dy),
      );
      expect(find.text(en.cloudsMoreLessons), findsOneWidget);
      settings.setLocale(const Locale('tl'));
      await tester.pumpAndSettle();
      expect(find.text(tl.cloudsMoreLessons), findsOneWidget);
    });

    test('no emoji in the fog text', () {
      for (final l10n in [en, tl]) {
        expect(hasEmoji(l10n.cloudsMoreLessons), isFalse);
        expect(hasEmoji(l10n.cloudsKeepPracticing), isFalse);
      }
      expect(hasEmoji('Soon ✨'), isTrue); // the check itself works
    });

    testWidgets('no clouds, no sparkle icon: only the fog and the text', (
      tester,
    ) async {
      await pumpFog(tester);
      final fog = find.byType(FogFooter);
      expect(
        find.descendant(of: fog, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(
        find.descendant(of: fog, matching: find.byType(Image)),
        findsNothing,
      );
      expect(fogPaint, findsOneWidget);
    });
  });

  group('Movement', () {
    setUp(() => FogFooter.drift = true);
    tearDown(() => FogFooter.drift = false);

    testWidgets('the fog drifts slowly (one animation for all of it)', (
      tester,
    ) async {
      await pumpFog(tester);
      final start = fogTime(tester);
      await tester.pump(const Duration(seconds: 3));
      final later = fogTime(tester);
      expect(later, isNot(start));
      // Slow: 3 seconds is only a small part of one drift.
      expect(later - start, lessThan(0.25));
      expect(FogFooter.cycle.inSeconds, greaterThanOrEqualTo(10));
      await tester.pumpWidget(const SizedBox()); // stop it
    });

    testWidgets('with "reduce motion" on, the fog stands still', (
      tester,
    ) async {
      await pumpFog(tester, reduceMotion: true);
      final start = fogTime(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(fogTime(tester), start);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('the fog repaints alone: a RepaintBoundary, and the widget '
        'is not rebuilt while it drifts', (tester) async {
      await pumpFog(tester);
      expect(
        find.ancestor(of: fogPaint, matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
      final before = tester.widget<CustomPaint>(fogPaint);
      await tester.pump(const Duration(seconds: 1));
      // Same widget object: only the painter repainted.
      expect(identical(tester.widget<CustomPaint>(fogPaint), before), isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Taps and scrolling', () {
    testWidgets('the fog ignores touches', (tester) async {
      await pumpFog(tester);
      expect(
        find.ancestor(
          of: fogPaint,
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dragging on the fog still scrolls the trail', (tester) async {
      await startApp(tester, size: const Size(360, 640));
      await openTrail(tester);
      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byType(FogFooter),
        300,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(list).position;
      final before = position.pixels;
      await tester.drag(
        find.byKey(const ValueKey('fog-text')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, lessThan(before));
    });
  });
}
