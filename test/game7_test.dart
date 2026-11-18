import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

final strings = lessons.firstWhere((l) => l.id == 'strings');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));
Finder hintText(String hint) =>
    find.textContaining(hint.replaceAll('`', ''), findRichText: true);

// ---------------------------------------------------------------------------
// A tiny Python evaluator for the string tools this game uses, so the
// answers are re-checked on every test run (not just once in Python):
// "text" and numbers, + (join text or add numbers; mixing them is an
// error, like Python), * (repeat text or multiply), len(), [n] (counting
// from 0), .upper() and .lower(), and brackets.
// ---------------------------------------------------------------------------

class _Parser {
  _Parser(String code)
    : tokens = RegExp(r'"[^"]*"|\d+|\w+|[-+*()\[\].]')
          .allMatches(code)
          .map((m) => m[0]!)
          .toList();

  final List<String> tokens;
  var _i = 0;

  String? get _peek => _i < tokens.length ? tokens[_i] : null;
  String _take() => tokens[_i++];
  void _expect(String t) {
    if (_take() != t) throw FormatException('expected "$t"');
  }

  Object parse() {
    final value = _sum();
    if (_peek != null) throw FormatException('extra "$_peek"');
    return value;
  }

  Object _sum() {
    var left = _product();
    while (_peek == '+') {
      _take();
      final right = _product();
      left = switch ((left, right)) {
        (final String a, final String b) => a + b,
        (final int a, final int b) => a + b,
        // Python: TypeError: can only concatenate str (not "int") to str
        _ => throw const FormatException('text + number'),
      };
    }
    return left;
  }

  Object _product() {
    var left = _postfix();
    while (_peek == '*') {
      _take();
      final right = _postfix();
      left = switch ((left, right)) {
        (final String s, final int n) => s * n,
        (final int n, final String s) => s * n,
        (final int a, final int b) => a * b,
        _ => throw const FormatException('cannot multiply'),
      };
    }
    return left;
  }

  Object _postfix() {
    var value = _primary();
    while (_peek == '[' || _peek == '.') {
      if (_take() == '[') {
        final index = int.parse(_take());
        _expect(']');
        value = (value as String)[index]; // counts from 0, like Python
      } else {
        final method = _take();
        _expect('(');
        _expect(')');
        value = switch (method) {
          'upper' => (value as String).toUpperCase(),
          'lower' => (value as String).toLowerCase(),
          _ => throw FormatException('unknown method "$method"'),
        };
      }
    }
    return value;
  }

  Object _primary() {
    final t = _take();
    if (t.startsWith('"')) return t.substring(1, t.length - 1);
    if (int.tryParse(t) case final n?) return n;
    if (t == 'len') {
      _expect('(');
      final inside = _sum();
      _expect(')');
      return (inside as String).length;
    }
    if (t == '(') {
      final value = _sum();
      _expect(')');
      return value;
    }
    throw FormatException('unknown "$t"');
  }
}

/// What Python gives for [expression]: a String (text) or an int.
Object evaluate(String expression) => _Parser(expression).parse();

/// How Python's print() shows a value: text without quotes, numbers as
/// digits. ("55" and 55 look the same!)
String printed(Object value) => '$value';

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
        lesson: strings,
        lessonNumber: lessons.indexOf(strings) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(7),
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
  for (final c in strings.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == strings.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 7 game data', () {
    test('3 rounds of 4 boxes, one chip per box, no setup line', () {
      expect(strings.game, hasLength(3));
      for (final round in strings.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup, isEmpty);
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('the evaluator itself works on known cases', () {
      expect(evaluate('"Hi, " + "Cog"'), 'Hi, Cog');
      expect(evaluate('"Ha" * 3'), 'HaHaHa');
      expect(evaluate('2 * "Go"'), 'GoGo');
      expect(evaluate('len("Hi Cog")'), 6);
      expect(evaluate('"Cog"[0]'), 'C');
      expect(evaluate('"Cog"[1]'), 'o');
      expect(evaluate('"cog".upper()'), 'COG');
      expect(evaluate('("Hi" + "!").lower()'), 'hi!');
      expect(evaluate('"5" + "5"'), isA<String>());
      expect(evaluate('5 + 5'), isA<int>());
      expect(printed(evaluate('"5" + "5"')), '55');
      expect(() => evaluate('"5" + 5'), throwsFormatException);
    });

    test('every chip is exactly what print() shows for its box', () {
      for (final (r, round) in strings.game.indexed) {
        for (final c in round.chips) {
          expect(
            c.value,
            printed(evaluate(c.box)),
            reason: 'round ${r + 1}: ${c.box}',
          );
        }
      }
    });

    test('no two chips in a round look the same (number vs text)', () {
      for (final (r, round) in strings.game.indexed) {
        // Different boxes give different results...
        final results = round.boxes.map((b) => printed(evaluate(b.name)));
        expect(results.toSet(), hasLength(4), reason: 'round ${r + 1}');
        // ...so a number chip can never look like a text chip.
        final shown = round.chips.map((c) => c.value);
        expect(shown.toSet(), hasLength(4), reason: 'round ${r + 1}');
      }
    });

    test('round 1: joining with + (one without a space) and *', () {
      final r1 = strings.game[0];
      final joins = r1.boxes.where((b) => b.name.contains(' + ')).toList();
      final repeats = r1.boxes.where((b) => b.name.contains(' * ')).toList();
      expect(joins, isNotEmpty);
      expect(repeats, isNotEmpty);
      // One join has no space between the words.
      expect(joins.map((b) => evaluate(b.name) as String), contains('HiCog'));
      expect(evaluate('"Hi" + "Cog"'), isNot(contains(' ')));
    });

    test('round 2: len() and [ ], counting from 0', () {
      final boxes = strings.game[1].boxes.map((b) => b.name).toList();
      expect(boxes.where((b) => b.startsWith('len(')), isNotEmpty);
      expect(boxes.where((b) => b.contains('[0]')), isNotEmpty);
      // A len box with a space in its text: the space counts.
      expect(
        boxes.where((b) => b.startsWith('len(') && b.contains(' ')),
        isNotEmpty,
      );
    });

    test('round 3: .upper(), .lower(), and "5" + "5" vs 5 + 5', () {
      final r3 = strings.game[2];
      final boxes = r3.boxes.map((b) => b.name).toList();
      expect(boxes.where((b) => b.contains('.upper()')), isNotEmpty);
      expect(boxes.where((b) => b.contains('.lower()')), isNotEmpty);
      expect(boxes, containsAll(['"5" + "5"', '5 + 5']));
      // 55 is text; 10 is a number.
      expect(evaluate('"5" + "5"'), isA<String>());
      expect(evaluate('5 + 5'), isA<int>());
      final chip55 = r3.chips.singleWhere((c) => c.box == '"5" + "5"');
      final chip10 = r3.chips.singleWhere((c) => c.box == '5 + 5');
      expect([chip55.value, chip10.value], ['55', '10']);
    });

    test('hints never name the right box, in either language', () {
      for (final round in strings.game) {
        for (final c in round.chips) {
          for (final l10n in [en, tl]) {
            final hint = c.hint(l10n).replaceAll('`', '');
            expect(hint, isNot(contains(c.box)), reason: '${c.box}: "$hint"');
          }
          expect(c.hint(tl), isNot(c.hint(en)));
        }
      }
    });

    test('boxes and chips are short (they fit a 360px phone)', () {
      // test/code_fit_test.dart also measures the chips with real fonts.
      for (final round in strings.game) {
        for (final b in round.boxes) {
          expect(b.name.length, lessThanOrEqualTo(14), reason: b.name);
        }
        for (final c in round.chips) {
          expect(c.value.length, lessThanOrEqualTo(7), reason: c.value);
        }
      }
    });
  });

  testWidgets('No setup code box: the boxes need no values', (tester) async {
    await pumpGame(tester);
    expect(find.byType(CodeBox), findsNothing);
    expect(box(0, '"Ha" * 3'), findsOneWidget);
  });

  testWidgets('Correct drop: HaHaHa snaps into "Ha" * 3', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'HaHaHa'), box(0, '"Ha" * 3'));
    expect(textInBox(0, '"Ha" * 3', 'HaHaHa'), findsOneWidget);
    expect(chip(0, 'HaHaHa'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop: HiCog on "Hi, " + "Cog" explains the space', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'HiCog'), box(0, '"Hi, " + "Cog"'));
    expect(chip(0, 'HiCog'), findsOneWidget); // back in the tray
    expect(textInBox(0, '"Hi, " + "Cog"', 'HiCog'), findsNothing);
    expect(hintText(en.game7R1Hint2), findsOneWidget);
  });

  testWidgets('Round 2: C on "Cog"[2] bounces with the counting hint', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await tapPlace(tester, 1, 'C', '"Cog"[2]');
    expect(chip(1, 'C'), findsOneWidget);
    expect(hintText(en.game7R2Hint3), findsOneWidget);
    await tapPlace(tester, 1, 'C', '"Cog"[0]');
    expect(textInBox(1, '"Cog"[0]', 'C'), findsOneWidget);
  });

  testWidgets('Round 3: 10 on "5" + "5" bounces; 55 is text', (tester) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    await tapPlace(tester, 2, '10', '"5" + "5"');
    expect(chip(2, '10'), findsOneWidget);
    expect(hintText(en.game7R3Hint4), findsOneWidget);
    await tapPlace(tester, 2, '55', '"5" + "5"');
    expect(textInBox(2, '"5" + "5"', '55'), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, 'GoGo', '"Go" * 2');
    expect(textInBox(0, '"Go" * 2', 'GoGo'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game7R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game7R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, 'GoGo', '"Ha" * 3'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(hintText(tl.game7R1Hint4), findsOneWidget);
    expect(find.text(tl.game7R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('strings'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.strings': 2},
      );
      await tapPlace(tester, 0, 'HiCog', '"Hi, " + "Cog"');
      await tapPlace(tester, 0, 'Hi, Cog', '"Hi" + "Cog"');
      await tapPlace(tester, 0, 'HaHaHa', '"Go" * 2');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('strings'), 2);
    });
  });

  testWidgets('Lesson 7 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: strings,
          lessonNumber: lessons.indexOf(strings) + 1,
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
    expect(find.text(en.game7R1Intro), findsOneWidget);
  });

  // Small phones with the biggest text, both languages: no overflow, and
  // chips and boxes at least 48px tall.
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
          for (final c in strings.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in strings.game[r].chips) {
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
