import 'dart:io';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

import 'test_helpers.dart';

/// Lessons from this one on (Lesson 7, Strings) must have every code line
/// fit in full on a 360px phone at normal text size: no sideways swipe.
/// (A few lines in Lessons 1 to 6 are a little too wide; they are left as
/// they are.)
const firstCheckedLessonId = 'strings';

/// Loads a font from assets/fonts. Plain widget tests draw every letter as
/// a wide square box; this test needs the real letter widths.
Future<void> loadFont(String family, String file) async {
  final bytes = File('assets/fonts/$file').readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Fredoka', 'Fredoka.ttf');
    await loadFont('Nunito', 'Nunito.ttf');
    await loadFont('JetBrainsMono', 'JetBrainsMono.ttf');
  });

  final first = lessons.indexWhere((l) => l.id == firstCheckedLessonId);

  for (final lesson in lessons.skip(first)) {
    final number = lessons.indexOf(lesson) + 1;
    testWidgets('Lesson $number: every code line fits on a 360px phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        for (final l in lessons) 'progress.stars.${l.id}': 1,
      });
      await tester.pumpWidget(
        PyCogApp(
          settings: await SettingsController.load(),
          progress: await ProgressController.load(),
        ),
      );
      await tester.pumpAndSettle();
      await openTrail(tester);
      final node = find.byKey(ValueKey('lesson-node-${lesson.id}'));
      await tester.scrollUntilVisible(
        node,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(node);
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      for (var c = 0; c < lesson.cards.length; c++) {
        // Each code line sits in its own sideways scroller; if a line fits,
        // there is nothing to scroll.
        final scrollers = tester
            .stateList<ScrollableState>(
              find.descendant(
                of: find.byType(CodeBox),
                matching: find.byType(Scrollable),
              ),
            )
            .where((s) => s.position.axis == Axis.horizontal);
        for (final s in scrollers) {
          final text = tester
              .widgetList<RichText>(
                find.descendant(
                  of: find.byWidget(s.widget),
                  matching: find.byType(RichText),
                ),
              )
              .map((r) => r.text.toPlainText())
              .join();
          expect(
            s.position.maxScrollExtent,
            0,
            reason: 'card ${c + 1}: "$text" is too wide',
          );
        }
        if (c < lesson.cards.length - 1) {
          await tester.tap(find.text(en.lessonNext));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  // Games from the same lessons on: each chip's text fits on one row at
  // 360px (a chip that is too wide wraps onto a second row), and each
  // round's setup lines fit with no sideways scrolling.
  for (final lesson in lessons.skip(first).where((l) => l.hasGame)) {
    final number = lessons.indexOf(lesson) + 1;
    testWidgets(
      'Lesson $number game: chips (one row) and setup lines fit at 360px',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final settings = await SettingsController.load();
        final en = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: GameScreen(
              lesson: lesson,
              lessonNumber: number,
              settings: settings,
              progress: await ProgressController.load(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final (r, round) in lesson.game.indexed) {
          for (final c in round.chips) {
            final chip = find.byKey(ValueKey('game-chip-$r-${c.value}'));
            final text = tester.renderObject<RenderParagraph>(
              find.descendant(of: chip, matching: find.byType(RichText)),
            );
            final oneRow = text.getFullHeightForCaret(
              const TextPosition(offset: 0),
            );
            expect(
              text.size.height,
              lessThan(oneRow * 1.5),
              reason: 'round ${r + 1}: "${c.value}" wraps',
            );
          }
          // The setup lines (if any) fit too: nothing to scroll sideways.
          for (final s
              in tester
                  .stateList<ScrollableState>(
                    find.descendant(
                      of: find.byType(CodeBox),
                      matching: find.byType(Scrollable),
                    ),
                  )
                  .where((s) => s.position.axis == Axis.horizontal)) {
            expect(
              s.position.maxScrollExtent,
              0,
              reason: 'round ${r + 1}: a setup line is too wide',
            );
          }
          // Place every chip (tap backup), then go on.
          for (final c in round.chips) {
            final chip = find.byKey(ValueKey('game-chip-$r-${c.value}'));
            await tester.ensureVisible(chip);
            await tester.tap(chip);
            await tester.pump();
            final box = find.byKey(ValueKey('game-box-$r-${c.box}'));
            await tester.ensureVisible(box);
            await tester.pumpAndSettle();
            await tester.tap(box);
            await tester.pumpAndSettle();
          }
          if (r < lesson.game.length - 1) {
            final next = find.text(en.gameNextRound);
            await tester.ensureVisible(next);
            await tester.tap(next);
            await tester.pumpAndSettle();
          }
        }
      },
    );
  }
}
