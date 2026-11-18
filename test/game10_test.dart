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

final logic = lessons.firstWhere((l) => l.id == 'logic');
final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

Finder chip(int round, String value) =>
    find.byKey(ValueKey('game-chip-$round-$value'));
Finder box(int round, String name) =>
    find.byKey(ValueKey('game-box-$round-$name'));
Finder textInBox(int round, String name, String text) =>
    find.descendant(of: box(round, name), matching: find.text(text));

// ---------------------------------------------------------------------------
// A tiny Python evaluator for the checks this game uses (and, or, not,
// comparisons, brackets), so the answers are re-checked on every test run,
// not just once in Python. Same order as Python: not, then and, then or.
// ---------------------------------------------------------------------------

/// Python's truth test for the values used here (bools and ints).
bool truthy(Object? v) => v is bool ? v : (v as int) != 0;

class _Parser {
  _Parser(String code, this.env)
    : tokens = RegExp(r'\(|\)|>=|<=|==|!=|>|<|\w+')
          .allMatches(code)
          .map((m) => m[0]!)
          .toList();

  final List<String> tokens;
  final Map<String, Object> env;
  var _i = 0;

  String? get _peek => _i < tokens.length ? tokens[_i] : null;
  String _take() => tokens[_i++];

  Object? parse() {
    final value = _or();
    if (_peek != null) throw FormatException('extra "$_peek"');
    return value;
  }

  // Python's `a or b` gives a if a is truthy, else b (and the same idea for
  // `and`), so these return the real operand, like Python.
  Object? _or() {
    var left = _and();
    while (_peek == 'or') {
      _take();
      final right = _and();
      left = truthy(left) ? left : right;
    }
    return left;
  }

  Object? _and() {
    var left = _not();
    while (_peek == 'and') {
      _take();
      final right = _not();
      left = truthy(left) ? right : left;
    }
    return left;
  }

  Object? _not() {
    if (_peek == 'not') {
      _take();
      return !truthy(_not());
    }
    return _compare();
  }

  Object? _compare() {
    final left = _atom();
    const ops = ['>', '<', '>=', '<=', '==', '!='];
    if (!ops.contains(_peek)) return left;
    final op = _take();
    final right = _atom();
    if (op == '==') return left == right;
    if (op == '!=') return left != right;
    final (a, b) = (left as int, right as int);
    return switch (op) {
      '>' => a > b,
      '<' => a < b,
      '>=' => a >= b,
      _ => a <= b,
    };
  }

  Object? _atom() {
    final t = _take();
    if (t == '(') {
      final value = _or();
      if (_take() != ')') throw const FormatException('missing )');
      return value;
    }
    if (t == 'True') return true;
    if (t == 'False') return false;
    if (int.tryParse(t) case final n?) return n;
    if (!env.containsKey(t)) throw FormatException('unknown name "$t"');
    return env[t];
  }
}

/// The round's values, from setup lines like `battery = 50`.
Map<String, Object> valuesOf(GameRound round) => {
  for (final line in round.setup)
    if (RegExp(r'^(\w+) = (.+)$').firstMatch(line.code) case final m?)
      m[1]!: switch (m[2]!) {
        'True' => true,
        'False' => false,
        final n => int.parse(n),
      },
};

/// What Python gives for [check] with the round's values.
Object? evaluate(String check, Map<String, Object> env) =>
    _Parser(check, env).parse();

/// The check read left to right (wrong!), for `A or B and C`: (A or B) and C.
String leftToRight(String check) {
  final m = RegExp(r'^(.+) or (.+) and (.+)$').firstMatch(check)!;
  return '(${m[1]} or ${m[2]}) and ${m[3]}';
}

int operatorCount(String check) =>
    RegExp(r'\b(and|or|not)\b').allMatches(check).length;

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
        lesson: logic,
        lessonNumber: lessons.indexOf(logic) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(10),
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
  for (final c in logic.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == logic.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 10 game data', () {
    test('3 rounds: True and False boxes, 4 chips, values on top', () {
      expect(logic.game, hasLength(3));
      for (final round in logic.game) {
        expect(round.boxes.map((b) => b.name), ['True', 'False']);
        expect(round.chips, hasLength(4));
        expect(round.setup, isNotEmpty);
        final values = round.chips.map((c) => c.value);
        expect(values.toSet(), hasLength(4)); // unique within a round
        // At least one chip in each box.
        expect(round.chips.where((c) => c.box == 'True'), isNotEmpty);
        expect(round.chips.where((c) => c.box == 'False'), isNotEmpty);
      }
    });

    test('the evaluator itself works on known cases', () {
      const env = {'a': true, 'b': false, 'n': 5};
      expect(evaluate('True or False and False', env), isTrue);
      expect(evaluate('(True or False) and False', env), isFalse);
      expect(evaluate('not a or b', env), isFalse);
      expect(evaluate('not (b or b)', env), isTrue);
      expect(evaluate('n > 3 and not b', env), isTrue);
      expect(evaluate('n >= 5 and n <= 5', env), isTrue);
      expect(evaluate('n != 5 or b', env), isFalse);
      expect(() => evaluate('missing and a', env), throwsFormatException);
    });

    test('every chip is in the box Python gives with its round values', () {
      for (final (r, round) in logic.game.indexed) {
        final env = valuesOf(round);
        expect(env, hasLength(round.setup.length), reason: 'round $r');
        for (final c in round.chips) {
          final real = evaluate(c.value, env);
          expect(real, isA<bool>(), reason: c.value);
          // Box names use Python's spelling: True / False.
          expect(
            c.box,
            real == true ? 'True' : 'False',
            reason: 'round ${r + 1}: ${c.value}',
          );
        }
      }
    });

    test('round 1 uses and, or and not, one operator per chip', () {
      final checks = logic.game[0].chips.map((c) => c.value).toList();
      for (final word in ['and', 'or', 'not']) {
        expect(
          checks.where((c) => RegExp('\\b$word\\b').hasMatch(c)),
          isNotEmpty,
          reason: word,
        );
      }
      expect(checks.every((c) => operatorCount(c) == 1), isTrue);
    });

    test('round 2: the same checks, new values, some answers change', () {
      final r1 = logic.game[0], r2 = logic.game[1];
      expect(r2.chips.map((c) => c.value), r1.chips.map((c) => c.value));
      expect(valuesOf(r2), isNot(valuesOf(r1)));
      final changed = [
        for (var i = 0; i < 4; i++)
          if (r1.chips[i].box != r2.chips[i].box) r1.chips[i].value,
      ];
      expect(changed, isNotEmpty);
    });

    test('round 3: two operators per chip, and one order chip', () {
      final r3 = logic.game[2];
      expect(r3.chips.every((c) => operatorCount(c.value) == 2), isTrue);
      // The order chip: `A or B and C` (no brackets). Read left to right it
      // gives the other answer, and its hint explains that and goes first.
      final order = r3.chips.singleWhere(
        (c) => RegExp(r'^[^()]+ or [^()]+ and [^()]+$').hasMatch(c.value),
      );
      final env = valuesOf(r3);
      expect(
        evaluate(leftToRight(order.value), env),
        isNot(evaluate(order.value, env)),
      );
      expect(order.hint(en), contains('`and` goes first'));
      // The same check with brackets is in the round too.
      expect(r3.chips.map((c) => c.value), contains(leftToRight(order.value)));
    });

    test('hints never name the right box, in either language', () {
      for (final round in logic.game) {
        for (final c in round.chips) {
          for (final l10n in [en, tl]) {
            final hint = c.hint(l10n);
            expect(
              RegExp('\\b${c.box}\\b').hasMatch(hint),
              isFalse,
              reason: '${c.value}: "$hint"',
            );
          }
          expect(c.hint(tl), isNot(c.hint(en)));
        }
      }
    });

    test('every chip is short (fits one row on a 360px phone)', () {
      // test/code_fit_test.dart measures the real width with real fonts.
      for (final round in logic.game) {
        for (final c in round.chips) {
          expect(c.value.length, lessThanOrEqualTo(24), reason: c.value);
        }
      }
    });
  });

  testWidgets('The round values show above the boxes', (tester) async {
    await pumpGame(tester);
    for (final line in ['battery = 50', 'lives = 0', 'has_key = True']) {
      expect(
        find.descendant(
          of: find.byType(CodeBox),
          matching: find.textContaining(line, findRichText: true),
        ),
        findsOneWidget,
      );
    }
    expect(
      tester.getTopLeft(find.byType(CodeBox)).dy,
      lessThan(tester.getTopLeft(box(0, 'True')).dy),
    );
  });

  testWidgets('Correct drop: has_key or lives > 0 snaps into True', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(
      tester,
      chip(0, 'has_key or lives > 0'),
      box(0, 'True'),
    );
    expect(textInBox(0, 'True', 'has_key or lives > 0'), findsOneWidget);
    expect(chip(0, 'has_key or lives > 0'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop bounces back with a one-line hint', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'not has_key'), box(0, 'True'));
    expect(chip(0, 'not has_key'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'True', 'not has_key'), findsNothing);
    expect(
      find.textContaining(
        en.game10R1Hint3.replaceAll('`', ''),
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tricky order chip: False first, then Cog explains and', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('gem = False', findRichText: true),
      ),
      findsOneWidget,
    );
    const order = 'key or gem and hp > 0';
    await tapPlace(tester, 2, order, 'False'); // reading left to right
    expect(chip(2, order), findsOneWidget);
    expect(
      find.textContaining(
        en.game10R3Hint1.replaceAll('`', ''),
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tapPlace(tester, 2, order, 'True'); // and goes first
    expect(textInBox(2, 'True', order), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, 'battery > 80 or has_key', 'True');
    expect(textInBox(0, 'True', 'battery > 80 or has_key'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game10R2Intro), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('battery = 30', findRichText: true),
      ),
      findsOneWidget,
    );

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(
      find.textContaining(
        en.game10R3Intro.replaceAll('`', ''),
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, 'battery > 20 and has_key', 'False'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        tl.game10R1Hint1.replaceAll('`', ''),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text(tl.game10R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('logic'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.logic': 2},
      );
      await tapPlace(tester, 0, 'not has_key', 'True');
      await tapPlace(tester, 0, 'has_key or lives > 0', 'False');
      await tapPlace(tester, 0, 'battery > 20 and has_key', 'False');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('logic'), 2);
    });
  });

  testWidgets('Lesson 10 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: logic,
          lessonNumber: lessons.indexOf(logic) + 1,
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
    expect(find.text(en.game10R1Intro), findsOneWidget);
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
          for (final c in logic.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final b in logic.game[r].boxes) {
            expect(
              tester.getSize(box(r, b.name)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in logic.game[r].chips) {
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
