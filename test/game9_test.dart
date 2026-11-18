import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/games/input_output_game.dart';
import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/models/match_game.dart';
import 'package:pycog/screens/game_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/code_box.dart';

final io = lessons.firstWhere((l) => l.id == 'input_output');
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
// A tiny Python evaluator for the lines this game uses, so the answers are
// re-checked on every test run (not just once in Python). The setup's
// `# you typed: Ana, 12` comment gives the answers, in order, to each
// input() line, always as text (like Python). Boxes may use "text",
// numbers, names, + (join text or add numbers; text + a number is an
// error, like Python's TypeError), * (before +), int(), float() and
// print(a, b) (a comma adds a space).
// ---------------------------------------------------------------------------

/// A Python error (TypeError, ValueError): the line does not work.
class PyError implements Exception {
  const PyError(this.type);
  final String type;
  @override
  String toString() => type;
}

class MiniPython {
  final Map<String, Object> vars = {};
  final List<String> _typed = [];

  List<String> _tokens = [];
  var _i = 0;

  String? get _peek => _i < _tokens.length ? _tokens[_i] : null;
  String _take() => _tokens[_i++];
  void _expect(String t) {
    final got = _take();
    if (got != t) throw FormatException('expected "$t", got "$got"');
  }

  void _start(String code) {
    _tokens = RegExp(r'"[^"]*"|\d+|\w+|[()+*,=]')
        .allMatches(code)
        .map((m) => m[0]!)
        .toList();
    _i = 0;
  }

  void _end() {
    if (_peek != null) throw FormatException('extra "$_peek"');
  }

  /// Runs the setup lines. The typed answers come from the comment.
  void run(List<String> lines) {
    for (final line in lines) {
      final typed = RegExp(r'^# you typed: (.+)$').firstMatch(line);
      if (typed != null) _typed.addAll(typed[1]!.split(', '));
    }
    for (final line in lines.where((l) => !l.startsWith('#'))) {
      _start(line);
      final name = _take();
      _expect('=');
      vars[name] = _expr();
      _end();
    }
  }

  /// What the box shows: a print(...) line shows what it prints; any other
  /// line shows print(line). A line that does not work shows `Error`.
  String shows(String line) {
    try {
      _start(line);
      if (_peek == 'print') {
        _take();
        _expect('(');
        final things = <Object>[];
        while (_peek != ')') {
          things.add(_expr());
          if (_peek == ',') _take();
        }
        _take();
        _end();
        return things.map(printed).join(' '); // a comma adds a space
      }
      final value = _expr();
      _end();
      return printed(value);
    } on PyError {
      return errorChip;
    }
  }

  Object _expr() {
    var left = _product();
    while (_peek == '+') {
      _take();
      final right = _product();
      left = switch ((left, right)) {
        (final String a, final String b) => a + b,
        (final int a, final int b) => a + b,
        (final num a, final num b) => a.toDouble() + b.toDouble(),
        _ => throw const PyError('TypeError'), // text + a number
      };
    }
    return left;
  }

  // * goes before +, like Python.
  Object _product() {
    var left = _primary();
    while (_peek == '*') {
      _take();
      final right = _primary();
      left = switch ((left, right)) {
        (final int a, final int b) => a * b,
        (final String s, final int n) => s * n,
        (final num a, final num b) => a.toDouble() * b.toDouble(),
        _ => throw const PyError('TypeError'),
      };
    }
    return left;
  }

  Object _primary() {
    final t = _take();
    if (t.startsWith('"')) return t.substring(1, t.length - 1);
    if (int.tryParse(t) case final n?) return n;
    if (t == 'input') {
      _expect('(');
      _take(); // the question
      _expect(')');
      if (_typed.isEmpty) throw const FormatException('nothing typed');
      return _typed.removeAt(0); // always text, even "12"
    }
    if (t == 'int' || t == 'float') {
      _expect('(');
      final inside = _expr();
      _expect(')');
      final text = '$inside'.trim();
      if (t == 'int') {
        if (inside is double) return inside.truncate();
        return int.tryParse(text) ?? (throw const PyError('ValueError'));
      }
      return double.tryParse(text) ?? (throw const PyError('ValueError'));
    }
    if (!vars.containsKey(t)) throw FormatException('unknown name "$t"');
    return vars[t]!;
  }
}

/// How Python's print() shows a value: text without quotes, numbers as
/// digits, and a float always with its ".0".
String printed(Object value) => switch (value) {
  final double d when d == d.roundToDouble() => '${d.toInt()}.0',
  _ => '$value',
};

/// A fresh evaluator that has run [round]'s setup lines.
MiniPython afterSetup(GameRound round) =>
    MiniPython()..run([for (final l in round.setup) l.code]);

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
        lesson: io,
        lessonNumber: lessons.indexOf(io) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(9),
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
  for (final c in io.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == io.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 9 game data', () {
    test('3 rounds of 4 boxes, one chip per box, the same input setup', () {
      expect(io.game, hasLength(3));
      for (final round in io.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup.map((l) => l.code), [
          'name = input("Your name? ")',
          'age = input("Age? ")',
          '# you typed: Ana, 12',
        ]);
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('the evaluator itself works on known cases', () {
      final py = MiniPython()
        ..run([
          'name = input("Your name? ")',
          'age = input("Age? ")',
          '# you typed: Ana, 12',
        ]);
      // input() always gives text, even for 12.
      expect(py.vars['age'], isA<String>());
      expect(py.vars['age'], '12');
      expect(py.shows('print("Score:", 10)'), 'Score: 10');
      expect(py.shows('"Hi, " + name'), 'Hi, Ana');
      expect(py.shows('age + age'), '1212');
      expect(py.shows('int(age) + 1'), '13');
      expect(py.shows('float(age)'), '12.0');
      expect(py.shows('age + 1'), errorChip); // TypeError
      expect(py.shows('int(name)'), errorChip); // ValueError
      expect(py.shows('print(name, 5 + 5)'), 'Ana 10');
      expect(py.shows('int(age) * 2'), '24');
      expect(py.shows('1 + 2 * 3'), '7'); // * first
      expect(py.shows('age * 2'), '1212'); // text repeated
      expect(() => py.shows('missing + 1'), throwsFormatException);
    });

    test('every chip is what the line shows, with Ana and 12 typed', () {
      for (final (r, round) in io.game.indexed) {
        final py = afterSetup(round);
        for (final c in round.chips) {
          expect(c.value, py.shows(c.box), reason: 'round ${r + 1}: ${c.box}');
        }
      }
    });

    test('no two boxes give the same answer; no two chips look alike', () {
      for (final (r, round) in io.game.indexed) {
        final py = afterSetup(round);
        final results = round.boxes.map((b) => py.shows(b.name));
        expect(results.toSet(), hasLength(4), reason: 'round ${r + 1}');
        expect(
          round.chips.map((c) => c.value).toSet(),
          hasLength(4),
          reason: 'round ${r + 1}',
        );
      }
    });

    test('round 1: print with commas, and joining with +', () {
      final r1 = io.game[0];
      expect(r1.boxes.map((b) => b.name), contains('print("Score:", 10)'));
      expect(r1.boxes.map((b) => b.name), contains('"Hi, " + name'));
      final score = r1.chips.singleWhere((c) => c.box == 'print("Score:", 10)');
      expect(score.value, 'Score: 10'); // the comma added a space
    });

    test('round 2: int() (and float(), which Lesson 9 mentions)', () {
      final r2 = io.game[1];
      expect(r2.boxes.map((b) => b.name), contains('int("5") + 1'));
      expect(r2.boxes.map((b) => b.name), contains('int(age) + 1'));
      expect(r2.chips.singleWhere((c) => c.box == 'int(age) + 1').value, '13');
      // float() is only used because Lesson 9 card 6 mentions it.
      expect(io.cards[5].speech(en), contains('`float()`'));
    });

    test('round 3: the trap; Error only where Python really fails', () {
      final r3 = io.game[2];
      final py = afterSetup(r3);
      final error = r3.chips.singleWhere((c) => c.value == errorChip);
      expect(error.box, 'age + 1');
      expect(py.shows(error.box), errorChip);
      // The hint says input() always gives text, and names the real error.
      expect(
        error.hint(en),
        allOf(contains('input()'), contains('text'), contains('TypeError')),
      );
      expect(r3.chips.singleWhere((c) => c.box == 'age + age').value, '1212');
      expect(r3.chips.singleWhere((c) => c.box == 'int(age) + 1').value, '13');
      // No other chip in the whole game is Error, and the error type is
      // never a chip.
      for (final round in io.game) {
        for (final c in round.chips) {
          if (c.value == errorChip) continue;
          expect(py.shows(c.box), isNot(errorChip), reason: c.box);
          expect(c.value, isNot(contains('Error')));
        }
      }
    });

    test('hints never name the right box, in either language', () {
      for (final round in io.game) {
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
      // test/code_fit_test.dart also measures chips and setup lines with
      // real fonts.
      for (final round in io.game) {
        for (final b in round.boxes) {
          expect(b.name.length, lessThanOrEqualTo(19), reason: b.name);
        }
        for (final c in round.chips) {
          expect(c.value.length, lessThanOrEqualTo(9), reason: c.value);
        }
      }
    });
  });

  testWidgets('The input lines and the typed answers show on top', (
    tester,
  ) async {
    await pumpGame(tester);
    for (final line in ['age = input("Age? ")', '# you typed: Ana, 12']) {
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
      lessThan(tester.getTopLeft(box(0, '"Hi, " + name')).dy),
    );
  });

  testWidgets('Correct drop: Hi, Ana snaps into "Hi, " + name', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'Hi, Ana'), box(0, '"Hi, " + name'));
    expect(textInBox(0, '"Hi, " + name', 'Hi, Ana'), findsOneWidget);
    expect(chip(0, 'Hi, Ana'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop: Age:12 on print(name, age) explains +', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'Age:12'), box(0, 'print(name, age)'));
    expect(chip(0, 'Age:12'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'print(name, age)', 'Age:12'), findsNothing);
    expect(hintText(en.game9R1Hint4), findsOneWidget);
  });

  testWidgets('Round 3: Error on int(age) + 1 bounces with the input hint', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    await tapPlace(tester, 2, errorChip, 'int(age) + 1');
    expect(chip(2, errorChip), findsOneWidget);
    expect(hintText(en.game9R3Hint1), findsOneWidget);
    await tapPlace(tester, 2, errorChip, 'age + 1');
    expect(textInBox(2, 'age + 1', errorChip), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, 'Score: 10', 'print("Score:", 10)');
    expect(textInBox(0, 'print("Score:", 10)', 'Score: 10'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(hintText(en.game9R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game9R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, 'Ana 12', '"Age:" + age'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(hintText(tl.game9R1Hint3), findsOneWidget);
    expect(find.text(tl.game9R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('input_output'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.input_output': 2},
      );
      await tapPlace(tester, 0, 'Ana 12', '"Hi, " + name');
      await tapPlace(tester, 0, 'Hi, Ana', '"Age:" + age');
      await tapPlace(tester, 0, 'Age:12', 'print("Score:", 10)');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('input_output'), 2);
    });
  });

  testWidgets('Lesson 9 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: io,
          lessonNumber: lessons.indexOf(io) + 1,
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
    expect(find.text(en.game9R1Intro), findsOneWidget);
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
          for (final c in io.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in io.game[r].chips) {
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
