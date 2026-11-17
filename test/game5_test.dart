import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/models/match_game.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

final functions = lessons[4];
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

// ---------------------------------------------------------------------------
// A tiny Python evaluator for the function shapes this game uses, so the
// answers are re-checked on every test run (not just once in Python).
// ---------------------------------------------------------------------------

/// A chip or argument as a Python value: 5 -> int, "Hi" -> String, None -> null.
Object? parseValue(String s) {
  s = s.trim();
  if (s == 'None') return null;
  if (s.startsWith('"')) return s.substring(1, s.length - 1);
  return int.parse(s);
}

Object? _term(String t, Map<String, Object?> env) =>
    env.containsKey(t.trim()) ? env[t.trim()] : parseValue(t);

/// `a + b`, `n * 2`, `"Hi, " + name` (one operator), or a single term.
Object? _evalExpr(String expr, Map<String, Object?> env) {
  final m = RegExp(r'^(.+?) ([+*]) (.+)$').firstMatch(expr);
  if (m == null) return _term(expr, env);
  final a = _term(m[1]!, env);
  final b = _term(m[3]!, env);
  if (m[2] == '+') return a is String ? '$a$b' : (a as int) + (b as int);
  return (a as int) * (b as int);
}

/// What a call like `add(2, 3)` really gives back, using the round's setup.
/// A `return` body gives its value back; a `print` body gives back None.
Object? giveBack(GameRound round, String call) {
  final defs = <String, (List<String>, bool, String)>{};
  for (var i = 0; i < round.setup.length; i++) {
    final def = RegExp(r'^def (\w+)\((.*)\):$').firstMatch(round.setup[i].code);
    if (def == null) continue;
    final body = round.setup[i + 1].code.trim();
    final params = def[2]!.split(',').map((p) => p.trim()).toList();
    final ret = RegExp(r'^return (.+)$').firstMatch(body);
    if (ret != null) {
      defs[def[1]!] = (params, true, ret[1]!);
    } else {
      // No return: the body must be a print (it gives back None).
      final prt = RegExp(r'^print\((.+)\)$').firstMatch(body)!;
      defs[def[1]!] = (params, false, prt[1]!);
    }
  }
  final c = RegExp(r'^(\w+)\((.*)\)$').firstMatch(call)!;
  final (params, returns, expr) = defs[c[1]]!;
  final args = c[2]!.split(',').map(parseValue).toList();
  final env = {for (var i = 0; i < params.length; i++) params[i]: args[i]};
  final value = _evalExpr(expr, env);
  return returns ? value : null;
}

Widget app(SettingsController settings, Widget home) => ListenableBuilder(
  listenable: settings,
  builder: (context, _) => MaterialApp(
    theme: AppTheme.light,
    locale: settings.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ),
);

Future<(SettingsController, ProgressController)> pumpGame(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  Size size = const Size(800, 1000),
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = systemScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues(saved);
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  await tester.pumpWidget(
    app(
      settings,
      GameScreen(
        lesson: functions,
        lessonNumber: 5,
        settings: settings,
        progress: progress,
        random: math.Random(4),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (settings, progress);
}

Future<void> dragChipToBox(WidgetTester tester, Finder from, Finder to) async {
  await tester.ensureVisible(to);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> tapPlace(
  WidgetTester tester,
  int round,
  String value,
  String to,
) async {
  await tester.ensureVisible(chip(round, value));
  await tester.tap(chip(round, value));
  await tester.pump();
  await tester.ensureVisible(box(round, to));
  await tester.pumpAndSettle();
  await tester.tap(box(round, to));
  await tester.pumpAndSettle();
}

/// Places every remaining chip of a round correctly, then taps Next.
Future<void> finishRound(WidgetTester tester, int r) async {
  for (final c in functions.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == functions.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 5 game data', () {
    test('3 rounds of 4 boxes, one chip per box, definitions on top', () {
      expect(functions.game, hasLength(3));
      for (final round in functions.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup.first.code, startsWith('def '));
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('the evaluator itself works on known cases', () {
      final r = functions.game[0];
      expect(giveBack(r, 'add(2, 3)'), 5);
      expect(giveBack(functions.game[2], 'shout("Cog")'), isNull);
      expect(giveBack(functions.game[2], 'greet("Ana")'), 'Hi, Ana');
    });

    test('every chip is exactly what its call gives back', () {
      for (final round in functions.game) {
        for (final c in round.chips) {
          final real = giveBack(round, c.box);
          final want = parseValue(c.value);
          expect(real, want, reason: c.box);
          expect(real.runtimeType, want.runtimeType, reason: c.box);
        }
        // No two boxes in a round give back the same value (no ambiguity).
        final results = round.boxes.map((b) => giveBack(round, b.name));
        expect(results.toSet(), hasLength(round.boxes.length));
      }
    });

    test('round rules: add, then double, then greet + one print box', () {
      bool allCall(GameRound r, String fn) =>
          r.boxes.every((b) => b.name.startsWith('$fn('));
      expect(allCall(functions.game[0], 'add'), isTrue);
      expect(allCall(functions.game[1], 'double'), isTrue);
      final r3 = functions.game[2];
      expect(r3.boxes.where((b) => b.name.startsWith('greet(')), hasLength(3));
      // Exactly one box gives back None, and its function uses print.
      final none = r3.chips.where((c) => c.value == 'None').toList();
      expect(none, hasLength(1));
      final fn = RegExp(r'^(\w+)\(').firstMatch(none.single.box)![1];
      final defLine = r3.setup.indexWhere((l) => l.code.startsWith('def $fn('));
      expect(r3.setup[defLine + 1].code.trim(), startsWith('print('));
      // Its hint says print only shows on screen, and names None.
      expect(none.single.hint(en), allOf(contains('print'), contains('None')));
    });
  });

  testWidgets('Definition shows once above the boxes', (tester) async {
    await pumpGame(tester);
    final def = find.descendant(
      of: find.byType(CodeBox),
      matching: find.textContaining('def add(a, b):', findRichText: true),
    );
    expect(def, findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(CodeBox)).dy,
      lessThan(tester.getTopLeft(box(0, 'add(2, 3)')).dy),
    );
  });

  testWidgets('Correct drop: 5 snaps into add(2, 3)', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '5'), box(0, 'add(2, 3)'));

    expect(textInBox(0, 'add(2, 3)', '5'), findsOneWidget);
    expect(chip(0, '5'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop bounces back with a one-line hint', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '10'), box(0, 'add(2, 3)'));

    expect(chip(0, '10'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'add(2, 3)', '?'), findsOneWidget); // still empty
    expect(find.text(en.game5R1Hint4), findsOneWidget);
  });

  testWidgets('Tricky box: "Hi, Cog" on shout("Cog") explains print', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('def shout(name):', findRichText: true),
      ),
      findsOneWidget,
    );

    await tapPlace(tester, 2, '"Hi, Cog"', 'shout("Cog")');
    expect(find.text(en.game5R3Hint4), findsOneWidget);
    expect(chip(2, '"Hi, Cog"'), findsOneWidget);

    await tapPlace(tester, 2, 'None', 'shout("Cog")'); // the right one
    expect(textInBox(2, 'shout("Cog")', 'None'), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, '4', 'add(4, 0)');
    expect(textInBox(0, 'add(4, 0)', '4'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game5R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game5R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, '2', 'add(5, 5)'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(find.text(tl.game5R1Hint2), findsOneWidget);
    expect(find.text(tl.game5R1Intro), findsOneWidget);
  });

  group('Stars', () {
    testWidgets('perfect: 3 bonus stars saved; unlocking unchanged', (
      tester,
    ) async {
      final (_, progress) = await pumpGame(tester);
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(3)), findsOneWidget);
      expect(progress.bestBonusStars('functions'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.functions': 2},
      );
      await tapPlace(tester, 0, '5', 'add(1, 1)');
      await tapPlace(tester, 0, '2', 'add(4, 0)');
      await tapPlace(tester, 0, '4', 'add(5, 5)');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('functions'), 2);
    });
  });

  testWidgets('Lesson 5 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: functions,
          lessonNumber: 5,
          stars: 3,
          isNewBest: true,
          unlockedLessonNumber: null,
          settings: settings,
          progress: await ProgressController.load(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.resultsPlayGame));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text(en.game5R1Intro), findsOneWidget);
  });

  // Small phones with the biggest text, both languages: no overflow, and
  // chips and boxes at least 48px tall (round 3 has the longest setup).
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('All rounds fit | $name | 1.5x + Large | $lang', (
        tester,
      ) async {
        await pumpGame(
          tester,
          size: size,
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        final l10n = lang == 'tl' ? tl : en;
        for (var r = 0; r < 3; r++) {
          for (final c in functions.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in functions.game[r].chips) {
            await tapPlace(tester, r, c.value, c.box);
          }
          final button = find.text(
            r == 2 ? l10n.gameSeeResults : l10n.gameNextRound,
          );
          expect(button, findsOneWidget);
          if (r < 2) {
            await tester.ensureVisible(button);
            await tester.tap(button);
            await tester.pumpAndSettle();
          }
        }
      });
    }
  }
}
