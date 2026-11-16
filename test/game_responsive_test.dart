// Plays round 1 of the game on many screen and text sizes.
// Any overflow (yellow-black stripes) throws during the test and fails it.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/chunky_button.dart';
import 'package:pycog/widgets/game_widgets.dart';

const screens = {
  'small phone 360x640': Size(360, 640),
  'phone 412x915': Size(412, 915),
  'small phone landscape 640x360': Size(640, 360),
  'phone landscape 915x412': Size(915, 412),
  'tablet 800x1280': Size(800, 1280),
  'tablet landscape 1280x800': Size(1280, 800),
};

void expectBigEnough(WidgetTester tester) {
  for (final type in [ChunkyButton, GameBoxView]) {
    for (final element in find.byType(type).evaluate()) {
      final size = element.size!;
      expect(
        size.width >= 48 && size.height >= 48,
        isTrue,
        reason: '$type is only $size',
      );
    }
  }
}

void main() {
  final round = lessons.first.game.first;

  for (final MapEntry(key: screenName, value: size) in screens.entries) {
    for (final systemScale in [1.0, 1.5]) {
      for (final language in ['en', 'tl']) {
        testWidgets('game | $screenName | system ${systemScale}x | $language', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = systemScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          SharedPreferences.setMockInitialValues({
            'settings.language': language,
            'settings.textSize': TextSize.large.name,
          });
          final settings = await SettingsController.load();
          final progress = await ProgressController.load();
          final l10n = lookupAppLocalizations(Locale(language));
          final scale = (systemScale * TextSize.large.scale).clamp(
            0.5,
            AppSizes.maxTextScale,
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              // Same text-size rule as the real app.
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: GameScreen(
                lesson: lessons.first,
                lessonNumber: 1,
                settings: settings,
                progress: progress,
                random: math.Random(1),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expectBigEnough(tester);

          // One wrong try (shows the hint card), then fill every box.
          Future<void> place(String value, String box) async {
            final chip = find.byKey(ValueKey('game-chip-0-$value'));
            await tester.ensureVisible(chip);
            await tester.tap(chip);
            await tester.pump();
            final target = find.byKey(ValueKey('game-box-0-$box'));
            await tester.ensureVisible(target);
            await tester.tap(target);
            await tester.pumpAndSettle();
          }

          final first = round.chips.first;
          await place(
            first.value,
            round.boxes.firstWhere((b) => b.name != first.box).name,
          );
          expect(find.text(first.hint(l10n)), findsOneWidget);
          expectBigEnough(tester);

          for (final c in round.chips) {
            await place(c.value, c.box);
          }
          expect(find.text(l10n.gameNextRound), findsOneWidget);
          expectBigEnough(tester);
        });
      }
    }
  }
}
