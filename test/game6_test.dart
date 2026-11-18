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

final math6 = lessons.firstWhere((l) => l.id == 'math_operators');
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
// A tiny Python evaluator for the math this game uses, so the answers are
// re-checked on every test run (not just once in Python). Same rules as
// Python: ** first (right to left), then * / // %, then + - (left to
// right), brackets first of all. `/` always gives a float.
// ---------------------------------------------------------------------------

class _Parser {
  _Parser(String code)
    : tokens = RegExp(r'\*\*|//|\d+|[-+*/%()]')
          .allMatches(code)
          .map((m) => m[0]!)
          .toList();

  final List<String> tokens;
  var _i = 0;

  String? get _peek => _i < tokens.length ? tokens[_i] : null;
  String _take() => tokens[_i++];

  num parse() {
    final value = _sum();
    if (_peek != null) throw FormatException('extra "$_peek"');
    return value;
  }

  num _sum() {
    var left = _product();
    while (_peek == '+' || _peek == '-') {
      final op = _take();
      final right = _product();
      left = op == '+' ? left + right : left - right;
    }
    return left;
  }

  num _product() {
    var left = _power();
    while (const ['*', '/', '//', '%'].contains(_peek)) {
      final op = _take();
      final right = _power();
      left = switch (op) {
        '*' => left * right,
        '/' => left / right, // always a double, like Python
        // Python's // and % round down (floor); fine for these numbers.
        '//' =>
          left is int && right is int
              ? (left / right).floor()
              : (left / right).floorToDouble(),
        _ => left % right,
      };
    }
    return left;
  }

  num _power() {
    final base = _atom();
    if (_peek != '**') return base;
    _take();
    final exponent = _power(); // right to left, like Python
    final result = math.pow(base, exponent);
    return base is int && exponent is int && exponent >= 0
        ? result.toInt()
        : result.toDouble();
  }

  num _atom() {
    final t = _take();
    if (t == '(') {
      final value = _sum();
      if (_take() != ')') throw const FormatException('missing )');
      return value;
    }
    return int.parse(t);
  }
}

/// What Python gives for [expression].
num evaluate(String expression) => _Parser(expression).parse();

/// How Python's print() shows a number: a float always keeps its ".0".
String py(num value) => value is double
    ? (value == value.roundToDouble() ? '${value.toInt()}.0' : '$value')
    : '$value';

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
        lesson: math6,
        lessonNumber: lessons.indexOf(math6) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(6),
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
  for (final c in math6.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == math6.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 6 game data', () {
    test('3 rounds of 4 boxes, one chip per box, no setup line', () {
      expect(math6.game, hasLength(3));
      for (final round in math6.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup, isEmpty);
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('the evaluator itself works on known cases', () {
      expect(evaluate('2 + 3 * 4'), 14);
      expect(evaluate('(2 + 3) * 4'), 20);
      expect(evaluate('10 - 4 - 3'), 3); // left to right
      expect(evaluate('2 ** 3 ** 2'), 512); // right to left
      expect(evaluate('10 / 2'), isA<double>());
      expect(py(evaluate('10 / 2')), '5.0');
      expect(py(evaluate('7 / 2')), '3.5');
      expect(evaluate('7 // 2'), isA<int>());
      expect(py(evaluate('7 // 2')), '3');
      expect(py(evaluate('7 % 2')), '1');
      expect(py(evaluate('2 * 3 ** 2')), '18');
      expect(() => evaluate('2 +'), throwsA(anything));
    });

    test('every chip is exactly what print() shows for its box', () {
      for (final (r, round) in math6.game.indexed) {
        for (final c in round.chips) {
          expect(
            c.value,
            py(evaluate(c.box)),
            reason: 'round ${r + 1}: ${c.box}',
          );
        }
        // No two boxes in a round give the same answer.
        final answers = round.boxes.map((b) => py(evaluate(b.name)));
        expect(answers.toSet(), hasLength(4), reason: 'round ${r + 1}');
      }
    });

    test('round 1 uses + - and * with easy numbers', () {
      final boxes = math6.game[0].boxes.map((b) => b.name).join(' ');
      for (final op in ['+', '-', '*']) {
        expect(boxes, contains(' $op '));
      }
      expect(boxes, isNot(contains('/')));
      expect(boxes, isNot(contains('%')));
      expect(boxes, isNot(contains('**')));
      for (final c in math6.game[0].chips) {
        expect(int.parse(c.value), lessThanOrEqualTo(20)); // easy answers
      }
    });

    test('round 2 uses /, // and %, with 5.0 and 5 as different chips', () {
      final r2 = math6.game[1];
      final boxes = r2.boxes.map((b) => b.name).toList();
      expect(boxes.where((b) => b.contains(' / ')), isNotEmpty);
      expect(boxes.where((b) => b.contains(' // ')), isNotEmpty);
      expect(boxes.where((b) => b.contains(' % ')), isNotEmpty);
      final values = r2.chips.map((c) => c.value);
      expect(values, containsAll(['5.0', '5']));
      // Every / box gives a decimal, every // and % box a whole number.
      for (final c in r2.chips) {
        expect(c.value.contains('.'), c.box.contains(' / '), reason: c.box);
      }
    });

    test('round 3 uses ** and brackets, with a look-alike pair', () {
      final boxes = math6.game[2].boxes.map((b) => b.name).toList();
      expect(boxes.where((b) => b.contains('**')), isNotEmpty);
      // The same numbers and signs with and without brackets, different
      // answers: 2 + 3 * 4 vs (2 + 3) * 4.
      final withBrackets = boxes.where((b) => b.contains('(')).toList();
      expect(withBrackets, isNotEmpty);
      for (final b in withBrackets) {
        final plain = b.replaceAll('(', '').replaceAll(')', '');
        expect(boxes, contains(plain));
        expect(py(evaluate(plain)), isNot(py(evaluate(b))));
      }
    });

    test('hints never name the right box, in either language', () {
      for (final round in math6.game) {
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
      for (final round in math6.game) {
        for (final b in round.boxes) {
          expect(b.name.length, lessThanOrEqualTo(11), reason: b.name);
        }
        for (final c in round.chips) {
          expect(c.value.length, lessThanOrEqualTo(3), reason: c.value);
        }
      }
    });
  });

  testWidgets('No setup code box: the boxes need no values', (tester) async {
    await pumpGame(tester);
    expect(find.byType(CodeBox), findsNothing);
    expect(box(0, '2 + 3'), findsOneWidget);
  });

  testWidgets('Correct drop: 5 snaps into 2 + 3', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '5'), box(0, '2 + 3'));
    expect(textInBox(0, '2 + 3', '5'), findsOneWidget);
    expect(chip(0, '5'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop bounces back with a one-line hint', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, '7'), box(0, '3 * 4'));
    expect(chip(0, '7'), findsOneWidget); // back in the tray
    expect(textInBox(0, '3 * 4', '7'), findsNothing);
    expect(hintText(en.game6R1Hint4), findsOneWidget);
  });

  testWidgets('Round 2: 5 on 10 / 2 bounces; 5.0 is the right chip', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await tapPlace(tester, 1, '5', '10 / 2');
    expect(chip(1, '5'), findsOneWidget);
    expect(hintText(en.game6R2Hint2), findsOneWidget);
    await tapPlace(tester, 1, '5.0', '10 / 2');
    expect(textInBox(1, '10 / 2', '5.0'), findsOneWidget);
  });

  testWidgets('Round 3: 14 on (2 + 3) * 4 bounces with the order hint', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    await tapPlace(tester, 2, '14', '(2 + 3) * 4');
    expect(chip(2, '14'), findsOneWidget);
    expect(hintText(en.game6R3Hint1), findsOneWidget);
    await tapPlace(tester, 2, '14', '2 + 3 * 4');
    expect(textInBox(2, '2 + 3 * 4', '14'), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, '12', '3 * 4');
    expect(textInBox(0, '3 * 4', '12'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game6R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game6R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, '6', '2 + 3'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(hintText(tl.game6R1Hint2), findsOneWidget);
    expect(find.text(tl.game6R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('math_operators'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.math_operators': 2},
      );
      await tapPlace(tester, 0, '5', '10 - 4');
      await tapPlace(tester, 0, '6', '3 * 4');
      await tapPlace(tester, 0, '12', '3 + 4');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('math_operators'), 2);
    });
  });

  testWidgets('Lesson 6 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: math6,
          lessonNumber: lessons.indexOf(math6) + 1,
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
    expect(find.text(en.game6R1Intro), findsOneWidget);
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
          for (final c in math6.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in math6.game[r].chips) {
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
