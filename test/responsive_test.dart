// Checks the app on many screen sizes and text sizes.
//
// Any layout overflow (the yellow-black stripes) makes Flutter throw an error
// during the test, so every combination below also proves there's no overflow.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/main.dart';
import 'package:pycog/widgets/chunky_button.dart';
import 'package:pycog/widgets/sticker_switch.dart';

import 'test_helpers.dart';

const screens = {
  'small phone 360x640': Size(360, 640),
  'phone 412x915': Size(412, 915),
  'small phone landscape 640x360': Size(640, 360),
  'phone landscape 915x412': Size(915, 412),
  'tablet 800x1280': Size(800, 1280),
  'tablet landscape 1280x800': Size(1280, 800),
};

/// Every button and switch is at least 48x48 (its real size, even when it is
/// half scrolled out of view).
Future<void> expectTouchTargets(WidgetTester tester) async {
  final tappables = [
    ...find.byType(ChunkyButton).evaluate(),
    ...find.byType(StickerSwitch).evaluate(),
  ];
  expect(tappables, isNotEmpty);
  for (final element in tappables) {
    final size = element.size!;
    expect(
      size.width >= 48 && size.height >= 48,
      isTrue,
      reason: '${element.widget.runtimeType} is only $size',
    );
  }
}

void main() {
  for (final MapEntry(key: screenName, value: size) in screens.entries) {
    for (final systemScale in [1.0, 1.5]) {
      for (final appTextSize in [TextSize.medium, TextSize.large]) {
        for (final language in ['en', 'tl']) {
          final name =
              '$screenName | system text ${systemScale}x | '
              'app text ${appTextSize.name} | $language';

          testWidgets(name, (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = systemScale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            final semantics = tester.ensureSemantics();

            SharedPreferences.setMockInitialValues({
              'settings.language': language,
              'settings.textSize': appTextSize.name,
            });
            final settings = await SettingsController.load();
            await tester.pumpWidget(
              PyCogApp(
                intro: false,
                settings: settings,
                progress: await ProgressController.load(),
              ),
            );
            await tester.pumpAndSettle();
            await openTrail(tester); // app opens on the home screen

            await expectTouchTargets(tester);
            // Flutter's built-in check as well. It only runs here, before any
            // scrolling: on half-scrolled items it measures just the visible
            // sliver and reports false alarms.
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );

            // ---- Home: every lesson can be scrolled to ----
            // (Lists only build what's near the screen, so scroll first.)
            await tester.scrollUntilVisible(
              find.byKey(ValueKey('lesson-node-${lessons.first.id}')),
              200,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.ensureVisible(
              find.byKey(ValueKey('lesson-node-${lessons.last.id}')),
            );
            await tester.pumpAndSettle();

            // ---- Lesson path: labels never hit the next node or the edge ----
            for (var i = 0; i < lessons.length; i++) {
              final label = tester.getRect(
                find.byKey(ValueKey('lesson-label-${lessons[i].id}')),
              );
              expect(label.left, greaterThanOrEqualTo(0), reason: 'label $i');
              expect(label.right, lessThanOrEqualTo(size.width));
              if (i + 1 < lessons.length) {
                final nextNode = tester.getRect(
                  find.byKey(ValueKey('lesson-node-${lessons[i + 1].id}')),
                );
                expect(
                  label.bottom,
                  lessThan(nextNode.top),
                  reason: 'label $i overlaps node ${i + 1}',
                );
              }
            }

            await expectTouchTargets(tester);

            // ---- Settings panel fits / scrolls ----
            await tester.ensureVisible(find.byIcon(Icons.settings_rounded));
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(Icons.settings_rounded));
            await tester.pumpAndSettle();

            final done = find.text(language == 'tl' ? 'Tapos na' : 'Done');
            await expectTouchTargets(tester);
            await tester.ensureVisible(done);
            await tester.pumpAndSettle();
            await expectTouchTargets(tester);

            await tester.tap(done);
            await tester.pumpAndSettle();
            expect(done, findsNothing);

            semantics.dispose();
          });
        }
      }
    }
  }
}
