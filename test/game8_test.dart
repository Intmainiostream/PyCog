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

final listsLesson = lessons.firstWhere((l) => l.id == 'lists');
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
// A tiny Python evaluator for the list tools this game uses, so the answers
// are re-checked on every test run (not just once in Python). It runs a
// round's setup lines first (making a list, items.append(...), and
// items[n] = ...), then each box: items[n] (counting from 0), len() of a
// list or a string, and "x" in items.
// ---------------------------------------------------------------------------

class MiniPython {
  final Map<String, Object> vars = {};

  List<String> _tokens = [];
  var _i = 0;

  String? get _peek => _i < _tokens.length ? _tokens[_i] : null;
  String _take() => _tokens[_i++];
  void _expect(String t) {
    final got = _take();
    if (got != t) throw FormatException('expected "$t", got "$got"');
  }

  void _start(String code) {
    _tokens = RegExp(r'"[^"]*"|\d+|\w+|[\[\]().,=]')
        .allMatches(code)
        .map((m) => m[0]!)
        .toList();
    _i = 0;
  }

  void _end() {
    if (_peek != null) throw FormatException('extra "$_peek"');
  }

  /// Runs setup [lines]. A statement may span lines (a list over 3 lines).
  void run(List<String> lines) {
    final statements = <String>[];
    var current = '';
    var depth = 0;
    for (final line in lines) {
      current = current.isEmpty ? line : '$current ${line.trim()}';
      depth += '['.allMatches(line).length - ']'.allMatches(line).length;
      depth += '('.allMatches(line).length - ')'.allMatches(line).length;
      if (depth == 0) {
        statements.add(current);
        current = '';
      }
    }
    if (current.isNotEmpty) throw const FormatException('unclosed bracket');
    for (final s in statements) {
      _statement(s);
    }
  }

  void _statement(String code) {
    _start(code);
    final name = _take();
    if (_peek == '=') {
      // name = value
      _take();
      vars[name] = _expr();
    } else if (_peek == '[') {
      // name[n] = value
      _take();
      final index = int.parse(_take());
      _expect(']');
      _expect('=');
      (vars[name]! as List<Object>)[index] = _expr();
    } else {
      // name.append(value)
      _expect('.');
      _expect('append');
      _expect('(');
      (vars[name]! as List<Object>).add(_expr());
      _expect(')');
    }
    _end();
  }

  /// What Python gives for [expression], using the setup's values.
  Object evaluate(String expression) {
    _start(expression);
    final value = _expr();
    _end();
    return value;
  }

  Object _expr() {
    final left = _postfix();
    if (_peek != 'in') return left;
    _take();
    final right = _postfix();
    return switch (right) {
      final List<Object> list => list.contains(left),
      final String s => s.contains(left as String),
      _ => throw const FormatException('in needs a list or text'),
    };
  }

  Object _postfix() {
    var value = _primary();
    while (_peek == '[') {
      _take();
      final index = int.parse(_take());
      _expect(']');
      value = switch (value) {
        // Too far: Python's IndexError.
        final List<Object> list when index >= list.length =>
          throw RangeError.index(index, list),
        final List<Object> list => list[index],
        final String s => s[index],
        _ => throw const FormatException('cannot pick from this'),
      };
    }
    return value;
  }

  Object _primary() {
    final t = _take();
    if (t.startsWith('"')) return t.substring(1, t.length - 1);
    if (int.tryParse(t) case final n?) return n;
    if (t == 'True') return true;
    if (t == 'False') return false;
    if (t == 'len') {
      _expect('(');
      final inside = _expr();
      _expect(')');
      return switch (inside) {
        final List<Object> list => list.length,
        final String s => s.length,
        _ => throw const FormatException('len needs a list or text'),
      };
    }
    if (t == '[') {
      final items = <Object>[];
      while (_peek != ']') {
        items.add(_expr());
        if (_peek == ',') _take();
      }
      _take();
      return items;
    }
    if (!vars.containsKey(t)) throw FormatException('unknown name "$t"');
    return vars[t]!;
  }
}

/// How Python's print() shows a value: text without quotes, True / False,
/// numbers as digits, and lists like ['sword', 'map'].
String printed(Object value) => switch (value) {
  true => 'True',
  false => 'False',
  final List<Object> list =>
    '[${list.map((v) => v is String ? "'$v'" : printed(v)).join(', ')}]',
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
        lesson: listsLesson,
        lessonNumber: lessons.indexOf(listsLesson) + 1,
        settings: settings,
        progress: progress,
        random: math.Random(8),
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
  for (final c in listsLesson.game[r].chips) {
    if (chip(r, c.value).evaluate().isEmpty) continue; // already placed
    await tapPlace(tester, r, c.value, c.box);
  }
  final last = r == listsLesson.game.length - 1;
  final button = find.text(last ? en.gameSeeResults : en.gameNextRound);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('Lesson 8 game data', () {
    test('3 rounds of 4 boxes, one chip per box, the list on top', () {
      expect(listsLesson.game, hasLength(3));
      for (final round in listsLesson.game) {
        expect(round.boxes, hasLength(4));
        expect(round.chips, hasLength(4));
        expect(round.setup.first.code, 'items = ["sword",');
        for (final b in round.boxes) {
          expect(round.chips.where((c) => c.box == b.name), hasLength(1));
        }
      }
    });

    test('the evaluator itself works on known cases', () {
      final py = MiniPython()
        ..run([
          'items = ["sword",',
          '         "shield",',
          '         "potion"]',
        ]);
      expect(py.evaluate('items[0]'), 'sword');
      expect(py.evaluate('len(items)'), 3);
      expect(py.evaluate('len("sword")'), 5);
      expect(py.evaluate('"potion" in items'), isTrue);
      expect(py.evaluate('"map" in items'), isFalse);
      expect(() => py.evaluate('items[3]'), throwsRangeError);
      py.run(['items.append("map")', 'items[0] = "axe"']);
      expect(printed(py.vars['items']!), "['axe', 'shield', 'potion', 'map']");
      expect(py.evaluate('items[3]'), 'map');
      expect(printed(py.evaluate('"sword" in items')), 'False');
      expect(() => py.evaluate('missing[0]'), throwsFormatException);
    });

    test('every chip is what print() shows, after the round setup', () {
      for (final (r, round) in listsLesson.game.indexed) {
        final py = afterSetup(round);
        for (final c in round.chips) {
          expect(
            c.value,
            printed(py.evaluate(c.box)),
            reason: 'round ${r + 1}: ${c.box}',
          );
        }
      }
    });

    test('no two boxes give the same answer; no two chips look alike', () {
      for (final (r, round) in listsLesson.game.indexed) {
        final py = afterSetup(round);
        final results = round.boxes.map((b) => printed(py.evaluate(b.name)));
        expect(results.toSet(), hasLength(4), reason: 'round ${r + 1}');
        expect(
          round.chips.map((c) => c.value).toSet(),
          hasLength(4),
          reason: 'round ${r + 1}',
        );
      }
    });

    test('round 1: picking by index from 0, plus len(items)', () {
      final boxes = listsLesson.game[0].boxes.map((b) => b.name).toList();
      expect(boxes, ['items[0]', 'items[1]', 'items[2]', 'len(items)']);
      // Negative indexes were not taught in Lesson 8.
      for (final round in listsLesson.game) {
        expect(round.boxes.any((b) => b.name.contains('-')), isFalse);
      }
    });

    test('round 2: len() and in, with one False answer', () {
      final r2 = listsLesson.game[1];
      final boxes = r2.boxes.map((b) => b.name).toList();
      expect(boxes.where((b) => b.startsWith('len(')), isNotEmpty);
      expect(boxes.where((b) => b.contains(' in ')), hasLength(2));
      expect(r2.chips.map((c) => c.value), containsAll(['True', 'False']));
    });

    test('round 3: the setup changes the list; append adds at the end', () {
      final r3 = listsLesson.game[2];
      final setup = r3.setup.map((l) => l.code).toList();
      expect(setup, contains('items.append("map")'));
      expect(setup, contains('items[0] = "axe"'));
      final py = afterSetup(r3);
      final items = py.vars['items']! as List<Object>;
      // The new item sits at the last index.
      expect(items.last, 'map');
      final last = r3.chips.singleWhere((c) => c.value == 'map');
      expect(last.box, 'items[${items.length - 1}]');
      expect(last.hint(en), allOf(contains('append'), contains('end')));
      // The boxes ask about the changed list.
      expect(
        r3.boxes.map((b) => b.name),
        containsAll(['len(items)', 'items[0]']),
      );
      expect(r3.chips.singleWhere((c) => c.box == 'len(items)').value, '4');
    });

    test('hints never name the right box, in either language', () {
      for (final round in listsLesson.game) {
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
      for (final round in listsLesson.game) {
        for (final b in round.boxes) {
          expect(b.name.length, lessThanOrEqualTo(16), reason: b.name);
        }
        for (final c in round.chips) {
          expect(c.value.length, lessThanOrEqualTo(6), reason: c.value);
        }
      }
    });
  });

  testWidgets('The backpack shows above the boxes', (tester) async {
    await pumpGame(tester);
    expect(
      find.descendant(
        of: find.byType(CodeBox),
        matching: find.textContaining('"shield",', findRichText: true),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(CodeBox)).dy,
      lessThan(tester.getTopLeft(box(0, 'items[0]')).dy),
    );
  });

  testWidgets('Correct drop: sword snaps into items[0]', (tester) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'sword'), box(0, 'items[0]'));
    expect(textInBox(0, 'items[0]', 'sword'), findsOneWidget);
    expect(chip(0, 'sword'), findsNothing);
    expect(find.text(en.gameCheer1), findsOneWidget);
  });

  testWidgets('Wrong drop: shield on items[0] explains counting from 0', (
    tester,
  ) async {
    await pumpGame(tester);
    await dragChipToBox(tester, chip(0, 'shield'), box(0, 'items[0]'));
    expect(chip(0, 'shield'), findsOneWidget); // back in the tray
    expect(textInBox(0, 'items[0]', 'shield'), findsNothing);
    expect(hintText(en.game8R1Hint2), findsOneWidget);
  });

  testWidgets('Round 3: the change shows; map on items[0] explains append', (
    tester,
  ) async {
    await pumpGame(tester);
    await finishRound(tester, 0);
    await finishRound(tester, 1);
    for (final line in ['items.append("map")', 'items[0] = "axe"']) {
      expect(
        find.descendant(
          of: find.byType(CodeBox),
          matching: find.textContaining(line, findRichText: true),
        ),
        findsOneWidget,
      );
    }
    await tapPlace(tester, 2, 'map', 'items[0]');
    expect(chip(2, 'map'), findsOneWidget);
    expect(hintText(en.game8R3Hint2), findsOneWidget);
    await tapPlace(tester, 2, 'map', 'items[3]');
    expect(textInBox(2, 'items[3]', 'map'), findsOneWidget);
  });

  testWidgets('Tap backup, and round progress 1 → 2 → 3', (tester) async {
    await pumpGame(tester);
    expect(find.bySemanticsLabel(en.gameProgress(1, 3)), findsOneWidget);

    await tapPlace(tester, 0, '3', 'len(items)');
    expect(textInBox(0, 'len(items)', '3'), findsOneWidget);

    await finishRound(tester, 0);
    expect(find.bySemanticsLabel(en.gameProgress(2, 3)), findsOneWidget);
    expect(find.text(en.game8R2Intro), findsOneWidget);

    await finishRound(tester, 1);
    expect(find.bySemanticsLabel(en.gameProgress(3, 3)), findsOneWidget);
    expect(find.text(en.game8R3Intro), findsOneWidget);
  });

  testWidgets('Language switch updates hints right away', (tester) async {
    final (settings, _) = await pumpGame(tester);
    await tapPlace(tester, 0, 'potion', 'items[1]'); // wrong

    settings.setLocale(SettingsController.tagalog);
    await tester.pumpAndSettle();
    expect(hintText(tl.game8R1Hint3), findsOneWidget);
    expect(find.text(tl.game8R1Intro), findsOneWidget);
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
      expect(progress.bestBonusStars('lists'), 3);
      expect(progress.unlockedCount(lessons), 1); // bonus never unlocks
    });

    testWidgets('3 wrong tries give 1 star; the best is kept', (tester) async {
      final (_, progress) = await pumpGame(
        tester,
        saved: {'progress.bonus.lists': 2},
      );
      await tapPlace(tester, 0, 'shield', 'items[0]');
      await tapPlace(tester, 0, 'potion', 'items[1]');
      await tapPlace(tester, 0, '3', 'items[2]');
      for (var r = 0; r < 3; r++) {
        await finishRound(tester, r);
      }
      expect(find.bySemanticsLabel(en.gameBonusStars(1)), findsOneWidget);
      expect(progress.bestBonusStars('lists'), 2);
    });
  });

  testWidgets('Lesson 8 quiz results: "Play the game" opens this game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      app(
        settings,
        QuizResultsScreen(
          lesson: listsLesson,
          lessonNumber: lessons.indexOf(listsLesson) + 1,
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
    expect(find.text(en.game8R1Intro), findsOneWidget);
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
          for (final c in listsLesson.game[r].chips) {
            expect(
              tester.getSize(chip(r, c.value)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getSize(box(r, c.box)).height,
              greaterThanOrEqualTo(48),
            );
          }
          for (final c in listsLesson.game[r].chips) {
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
