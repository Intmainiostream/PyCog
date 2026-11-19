import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/data/minigame_progress.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/models/quiz.dart';
import 'package:pycog/playground/python_runner.dart';
import 'package:pycog/screens/challenge_screen.dart';
import 'package:pycog/screens/minigame_map_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/output_box.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// A tiny pretend Python that knows the programs these tests type.
class FakePython implements PythonEngine {
  final runs = <(String, List<String>)>[];

  @override
  final ValueNotifier<bool> isReady = ValueNotifier(true);

  static PythonResult _out(String stdout, [String? error]) =>
      PythonResult(stdout: stdout, error: error, elapsed: Duration.zero);

  /// Like the real runner: the typed answer is echoed after "Age? ".
  static PythonResult _age(String answer, String printed) => PythonResult(
    stdout: 'Age? $answer\n$printed\n',
    typed: [TypedAnswer('Age? '.length, answer)],
    elapsed: Duration.zero,
  );

  @override
  Future<PythonResult> run(
    String code, {
    List<String> inputs = const [],
    Duration timeout = const Duration(seconds: 3),
  }) async {
    runs.add((code, inputs));
    switch (code) {
      case 'name = "Cog"\nprint(name)':
        return _out('Cog\n');
      case 'name = "Cog"\nprint("name")':
        return _out('name\n');
      case 'name = "Cog"\nprint(Name)':
        return _out('', "NameError: name 'Name' is not defined");
      case 'age = int(input("Age? "))\nprint(age + 1)':
        return _age(inputs[0], '${int.parse(inputs[0]) + 1}');
      case 'age = int(input("Age? "))\nprint(13)':
        return _age(inputs[0], '13');
      case 'print(1 + 1)':
        return _out('2\n');
      case 'speed = 5\nprint(speed)' ||
          'speed=5\nprint( speed )' ||
          'print(5)' ||
          'speed = 5\nprint(5)':
        return _out('5\n');
      case 'print(6)':
        return _out('6\n');
      case 'lives = 3\nif lives > 0:\n    print("Keep playing!")' ||
          'lives = 3\nif lives >= 0:\n    print("Keep playing!")' ||
          'lives=3\nif lives>0:\n    print("Keep playing!")':
        return _out('Keep playing!\n');
      case 'speed = 5\nprint(Speed)':
        return _out('', "NameError: name 'Speed' is not defined");
      case 'robot_name = "Cog"\nspeed = 5\nis_moving = True\n'
          'print(robot_name)\nprint(speed)\nprint(is_moving)':
        return _out('Cog\n5\nTrue\n');
    }
    return _out('', 'SyntaxError: invalid syntax');
  }
}

final level1 = minigameLevels.first;

Finder key(String k) => find.byKey(ValueKey(k));

Future<(MinigameProgress, FakePython)> pumpMap(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  List<MinigameLevel>? levels,
  String lang = 'en',
  Size size = const Size(800, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({...saved, 'settings.language': lang});
  final settings = await SettingsController.load();
  final progress = await MinigameProgress.load();
  final engine = FakePython();
  await tester.pumpWidget(
    ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: MinigameMapScreen(
          settings: settings,
          progress: progress,
          levels: levels,
          engine: engine,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (progress, engine);
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// From the map: open Level [level], then challenge [number].
Future<void> openChallenge(
  WidgetTester tester,
  String id, {
  int level = 1,
}) async {
  await tapAndSettle(tester, key('mg-level-$level'));
  await tapAndSettle(tester, key('mg-challenge-$id'));
}

/// Text as the screen draws it: words in `backticks` lose the backticks.
String plain(String text) => text.replaceAll('`', '');

/// Goes back one screen (like the back or close button).
Future<void> goBack(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

/// The "must use" message as the screen shows it (non-breaking spaces
/// inside each piece, no backticks).
String plainMustUse(AppLocalizations l10n, List<String> pieces) => plain(
  l10n.mgMustUse(
    pieces.map((p) => '`${p.replaceAll(' ', '\u00A0')}`').join(', '),
  ),
);

int starsLeft(WidgetTester tester) =>
    tester.widget<StarRow>(key('mg-stars-left')).stars;

/// The quiz answer button showing [label].
Finder answer(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey &&
        '${(w.key as ValueKey).value}'.startsWith('mg-answer-'),
  ),
);

/// The rows of one output box (after its "Output" label).
List<String> rowsOf(WidgetTester tester, Finder box) => tester
    .widgetList<Text>(find.descendant(of: box, matching: find.byType(Text)))
    .skip(1)
    .map((t) => t.data ?? t.textSpan!.toPlainText())
    .toList();

/// A pretend quiz challenge (right answer: "yes").
Challenge quiz(String id) => Challenge.quiz(
  id: id,
  title: (_) => 'Quiz $id',
  prompt: (_) => 'Pick yes',
  answers: [
    QuizAnswer(label: (_) => 'yes', correct: true),
    QuizAnswer(label: (_) => 'no'),
  ],
);

void main() {
  group('Level map', () {
    testWidgets('10 levels: Level 1 open, the rest locked', (tester) async {
      await pumpMap(tester);
      expect(find.text(en.mgMapTitle), findsOneWidget);
      for (var n = 1; n <= 10; n++) {
        await tester.ensureVisible(key('mg-level-$n'));
        expect(key('mg-level-$n'), findsOneWidget);
      }
      await tester.ensureVisible(key('mg-level-1'));
      await tester.pumpAndSettle();
      expect(find.text(en.mgSolved(0, 10)), findsOneWidget);
      expect(find.text('0/30'), findsOneWidget);
      expect(find.text(en.mgLocked), findsNWidgets(9));
    });

    testWidgets('a locked level says how to open it', (tester) async {
      await pumpMap(tester);
      await tapAndSettle(tester, key('mg-level-2'));
      expect(find.text(en.mgLevelLocked(1)), findsOneWidget);
    });

    testWidgets('the stars earned show on each level', (tester) async {
      await pumpMap(
        tester,
        saved: {'minigame.stars.mgL1C1': 3, 'minigame.stars.mgL1C3': 1},
      );
      expect(find.text('4/30'), findsOneWidget);
      expect(find.text(en.mgSolved(2, 10)), findsOneWidget);
    });

    testWidgets('an open level lists its challenges with their stars', (
      tester,
    ) async {
      await pumpMap(
        tester,
        size: const Size(800, 2000), // all 10 tiles on screen
        saved: {'minigame.stars.mgL1C2': 2, 'minigame.stars.mgL1C10': 3},
      );
      await tapAndSettle(tester, key('mg-level-1'));
      for (final c in level1.challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
      expect(find.text(en.mgTypeQuiz), findsNWidgets(3));
      expect(find.text(en.mgTypeFillBlank), findsNWidgets(2));
      expect(find.text(en.mgTypeFixBug), findsNWidgets(2));
      expect(find.text(en.mgTypeWriteCode), findsNWidgets(3));
      final stars = tester.widgetList<StarRow>(find.byType(StarRow));
      expect(stars.map((s) => s.stars), [0, 2, 0, 0, 0, 0, 0, 0, 0, 3]);
    });

    testWidgets('an open level with no challenges says "coming soon"', (
      tester,
    ) async {
      await pumpMap(
        tester,
        levels: [const MinigameLevel(number: 1, challenges: [])],
      );
      expect(find.text(en.mgLevelSoon), findsOneWidget);
      await tapAndSettle(tester, key('mg-level-1'));
      expect(find.byType(MinigameLevelScreen), findsNothing);
    });
  });

  group('Quiz challenge (stars from wrong picks)', () {
    testWidgets('right on the first try = 3 stars; no hints in a quiz', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      expect(find.text(plain(en.mgL1C1Prompt)), findsOneWidget);
      expect(find.text('battery = 80'), findsOneWidget);
      expect(key('mg-hint'), findsNothing);
      expect(starsLeft(tester), 3);

      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 3);
    });

    testWidgets('right on the second try = 2 stars', (tester) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('100'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgTryAgain), findsOneWidget);
      expect(starsLeft(tester), 2);

      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 2);
    });

    testWidgets('third try = 1 star, and later tries stay at 1', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      for (final (wrong, left) in [('100', 2), ('180', 1), ('battery', 1)]) {
        await tapAndSettle(tester, answer(wrong));
        await tapAndSettle(tester, key('mg-check'));
        expect(starsLeft(tester), left, reason: 'after picking $wrong');
      }
      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(1)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 1);
    });

    testWidgets('a wrong pick is saved: leaving does not reset it', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('100'));
      await tapAndSettle(tester, key('mg-check'));
      // `100` is answers[1] in the data.
      expect(progress.wrongPicks('mgL1C1'), {1});

      await goBack(tester);
      await tapAndSettle(tester, key('mg-challenge-mgL1C1'));
      // Still marked wrong, can't be picked again, and still 2 stars.
      expect(
        find.descendant(
          of: answer('100'),
          matching: find.byIcon(Icons.cancel_rounded),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, answer('100'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgTryAgain), findsNothing); // nothing was picked
      expect(starsLeft(tester), 2);

      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      expect(progress.bestStars('mgL1C1'), 2);
      // Finished: the saved wrong picks are cleared, so a replay is fresh.
      expect(progress.wrongPicks('mgL1C1'), isEmpty);
      await goBack(tester);
      await tapAndSettle(tester, key('mg-challenge-mgL1C1'));
      expect(starsLeft(tester), 3);
    });

    testWidgets('a worse quiz replay keeps the best stars', (tester) async {
      final (progress, _) = await pumpMap(
        tester,
        saved: {'minigame.stars.mgL1C1': 3},
      );
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('100'));
      await tapAndSettle(tester, key('mg-check'));
      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 3);
    });
  });

  group('Hints (code challenges)', () {
    // Level 1, challenge 3: make speed = 5 and print it.
    const solution = 'speed = 5\nprint(speed)';

    Future<void> solve(WidgetTester tester) async {
      await tester.enterText(key('mg-code'), solution);
      await tapAndSettle(tester, key('mg-run'));
    }

    testWidgets('each hint costs a star, down to 1', (tester) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C3');
      expect(starsLeft(tester), 3);
      expect(find.textContaining(plain(en.mgL1C3Hint1)), findsNothing);

      await tapAndSettle(tester, key('mg-hint'));
      expect(find.textContaining(plain(en.mgL1C3Hint1)), findsOneWidget);
      expect(find.textContaining(plain(en.mgL1C3Hint2)), findsNothing);
      expect(starsLeft(tester), 2);

      await tapAndSettle(tester, key('mg-hint'));
      expect(find.textContaining(plain(en.mgL1C3Hint2)), findsOneWidget);
      expect(starsLeft(tester), 1);
      expect(key('mg-hint'), findsNothing); // only 2 hints

      await solve(tester);
      expect(find.text(en.mgPassed(1)), findsOneWidget);
      expect(progress.bestStars('mgL1C3'), 1);
    });

    testWidgets('an opened hint stays open after leaving and coming back', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C3');
      await tapAndSettle(tester, key('mg-hint'));
      expect(progress.hintsUsed('mgL1C3'), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame.hints.mgL1C3'), 1);

      await goBack(tester);
      await tapAndSettle(tester, key('mg-challenge-mgL1C3'));
      expect(find.textContaining(plain(en.mgL1C3Hint1)), findsOneWidget);
      expect(starsLeft(tester), 2);

      await solve(tester);
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.bestStars('mgL1C3'), 2);
    });

    testWidgets('hints saved before the app closed are still open', (
      tester,
    ) async {
      await pumpMap(tester, saved: {'minigame.hints.mgL1C3': 2});
      await openChallenge(tester, 'mgL1C3');
      expect(find.textContaining(plain(en.mgL1C3Hint1)), findsOneWidget);
      expect(find.textContaining(plain(en.mgL1C3Hint2)), findsOneWidget);
      expect(key('mg-hint'), findsNothing);
      expect(starsLeft(tester), 1);
    });

    testWidgets('finishing clears the saved hints', (tester) async {
      final (progress, _) = await pumpMap(
        tester,
        saved: {'minigame.hints.mgL1C3': 1},
      );
      await openChallenge(tester, 'mgL1C3');
      await solve(tester);
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.hintsUsed('mgL1C3'), 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('minigame.hints.mgL1C3'), isFalse);

      // A replay starts fresh.
      await goBack(tester);
      await tapAndSettle(tester, key('mg-challenge-mgL1C3'));
      expect(find.textContaining(plain(en.mgL1C3Hint1)), findsNothing);
      expect(starsLeft(tester), 3);
    });

    testWidgets('hints on a challenge finished with 3 stars never lower '
        'the best', (tester) async {
      final (progress, _) = await pumpMap(
        tester,
        saved: {'minigame.stars.mgL1C3': 3},
      );
      await openChallenge(tester, 'mgL1C3');
      await tapAndSettle(tester, key('mg-hint'));
      await tapAndSettle(tester, key('mg-hint'));
      expect(starsLeft(tester), 1);

      // While the hints are open, the level still shows the best: 3.
      await goBack(tester);
      expect(progress.bestStars('mgL1C3'), 3);
      final c3 = tester.widget<StarRow>(
        find.descendant(
          of: key('mg-challenge-mgL1C3'),
          matching: find.byType(StarRow),
        ),
      );
      expect(c3.stars, 3);

      await tapAndSettle(tester, key('mg-challenge-mgL1C3'));
      await solve(tester);
      expect(find.text(en.mgPassed(1)), findsOneWidget);
      expect(progress.bestStars('mgL1C3'), 3);
      expect(progress.hintsUsed('mgL1C3'), 0);
    });
  });

  group('Fill the blank', () {
    testWidgets('a wrong pick shows the failed test, then the right one '
        'passes with 3 stars', (tester) async {
      final (progress, engine) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C2');
      expect(find.text(en.mgPickBlank), findsOneWidget);
      // Nothing picked yet: Run is off.
      await tapAndSettle(tester, key('mg-run'));
      expect(engine.runs, isEmpty);

      await tapAndSettle(tester, key('mg-choice-2')); // Name
      await tapAndSettle(tester, key('mg-run'));
      expect(engine.runs.single.$1, 'name = "Cog"\nprint(Name)');
      expect(find.text(en.mgFailed(1)), findsOneWidget);
      expect(key('mg-error'), findsOneWidget);
      expect(find.text(en.codingTipName), findsOneWidget);
      expect(find.text(en.codingNothingPrinted), findsOneWidget);
      expect(rowsOf(tester, key('mg-expected-output')), ['Cog']);
      expect(starsLeft(tester), 3); // a failed run costs nothing

      await tapAndSettle(tester, key('mg-choice-1')); // "name"
      await tapAndSettle(tester, key('mg-run'));
      expect(rowsOf(tester, key('mg-your-output')), ['name']);

      await tapAndSettle(tester, key('mg-choice-0')); // name
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('mgL1C2'), 3);
    });

    testWidgets('without choices the student types the blank', (tester) async {
      final typed = Challenge.fillBlank(
        id: 't1',
        title: (_) => 'Typed blank',
        prompt: (_) => 'Make it print 2',
        hints: [(_) => 'h1', (_) => 'h2'],
        template: 'print(1 $blankMarker 1)',
        solution: '+',
        tests: const [
          TestCase(output: ['2']),
        ],
      );
      final (progress, engine) = await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [typed]),
        ],
      );
      await openChallenge(tester, 't1');
      expect(find.byKey(const ValueKey('mg-choice-0')), findsNothing);
      await tester.enterText(key('mg-blank'), '+');
      await tester.pumpAndSettle();
      // The blank in the code shows what was typed.
      final code = tester.widget<Text>(key('mg-blank-code'));
      expect(code.textSpan!.toPlainText(), 'print(1 + 1)');
      await tapAndSettle(tester, key('mg-run'));
      expect(engine.runs.single.$1, 'print(1 + 1)');
      expect(progress.bestStars('t1'), 3);
    });
  });

  group('Write it yourself', () {
    testWidgets('only the first failed test is shown, never the untried ones', (
      tester,
    ) async {
      // A test-only challenge with input() (Level 1 has none).
      final age = Challenge.writeCode(
        id: 'age',
        title: (_) => 'Next year',
        prompt: (_) => 'Ask with input("Age? ") and print the age plus 1.',
        hints: [(_) => 'h1', (_) => 'h2'],
        solution: 'age = int(input("Age? "))\nprint(age + 1)',
        showFirstTest: true,
        tests: const [
          TestCase(inputs: ['12'], output: ['Age? 12', '13']),
          TestCase(inputs: ['0'], output: ['Age? 0', '1']),
          TestCase(inputs: ['99'], output: ['Age? 99', '100']),
        ],
      );
      final (progress, engine) = await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [age]),
        ],
      );
      await openChallenge(tester, 'age');
      // The first test is shown as an example.
      final example = tester.widget<OutputBox>(key('mg-example'));
      expect(example.lines, ['Age? ', '13']);
      expect(example.typed, {0: '12'});

      await tester.enterText(
        key('mg-code'),
        'age = int(input("Age? "))\nprint(13)',
      );
      await tapAndSettle(tester, key('mg-run'));
      // Test 1 passed, test 2 failed, test 3 never ran.
      expect(engine.runs.map((r) => r.$2), [
        ['12'],
        ['0'],
      ]);
      expect(find.text(en.mgFailed(2)), findsOneWidget);
      final yours = tester.widget<OutputBox>(key('mg-your-output'));
      expect(yours.lines, ['Age? ', '13']);
      expect(yours.typed, {0: '0'});
      final expected = tester.widget<OutputBox>(key('mg-expected-output'));
      expect(expected.lines, ['Age? ', '1']);
      expect(expected.typed, {0: '0'});
      expect(find.textContaining('99'), findsNothing);
      expect(find.textContaining('100'), findsNothing);
      expect(progress.bestStars('age'), 0);

      await tester.enterText(
        key('mg-code'),
        'age = int(input("Age? "))\nprint(age + 1)',
      );
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('age'), 3);
    });

    testWidgets('a Level 1 write-it challenge with no example shown', (
      tester,
    ) async {
      final (progress, engine) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C3');
      expect(key('mg-example'), findsNothing);
      await tester.enterText(key('mg-code'), 'speed = 5\nprint(speed)');
      await tapAndSettle(tester, key('mg-run'));
      expect(engine.runs.single.$2, isEmpty); // no typed answers
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('mgL1C3'), 3);
    });

    testWidgets('the helper keys type into the code box', (tester) async {
      await pumpMap(tester);
      await openChallenge(tester, 'mgL1C3');
      await tester.tap(key('mg-code'));
      await tester.pumpAndSettle();
      expect(key('mg-helpers'), findsOneWidget);
      await tester.tap(key('mg-key-( )'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(key('mg-code')).controller!.text, '()');
    });
  });

  group('Required code ("must use")', () {
    /// The message as the screen shows it (non-breaking spaces inside
    /// each piece, no backticks).
    String mustUse(AppLocalizations l10n, List<String> pieces) => plain(
      l10n.mgMustUse(
        pieces.map((p) => '`${p.replaceAll(' ', '\u00A0')}`').join(', '),
      ),
    );
    // A test-only challenge, so these tests don't depend on lesson content.
    final need = Challenge.writeCode(
      id: 'need',
      title: (_) => 'Make speed',
      prompt: (_) => 'Make speed = 5 and print(speed).',
      hints: [(_) => 'h1', (_) => 'h2'],
      solution: 'speed = 5\nprint(speed)',
      requiredCode: const ['speed = 5', 'print(speed)'],
      tests: const [
        TestCase(output: ['5']),
      ],
    );

    testWidgets('right output but a missing piece: the code runs, then a '
        'short message, no star lost', (tester) async {
      final (progress, engine) = await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [need]),
        ],
      );
      await openChallenge(tester, 'need');
      await tester.enterText(key('mg-code'), 'print(5)');
      await tapAndSettle(tester, key('mg-run'));
      expect(engine.runs, hasLength(1)); // it ran first
      expect(
        find.text(mustUse(en, ['speed = 5', 'print(speed)'])),
        findsOneWidget,
      );
      expect(key('mg-failed'), findsNothing); // no failed test is shown
      expect(starsLeft(tester), 3);
      expect(progress.bestStars('need'), 0);

      // Only the piece still missing is named.
      await tester.enterText(key('mg-code'), 'speed = 5\nprint(5)');
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(mustUse(en, ['print(speed)'])), findsOneWidget);
    });

    testWidgets('wrong output: the failed test, not the "must use" message', (
      tester,
    ) async {
      await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [need]),
        ],
      );
      await openChallenge(tester, 'need');
      await tester.enterText(key('mg-code'), 'print(6)');
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(en.mgFailed(1)), findsOneWidget);
      expect(key('mg-your-output'), findsOneWidget);
      expect(key('mg-missing'), findsNothing);
    });

    testWidgets('extra spaces still count: with every piece it passes', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [need]),
        ],
      );
      await openChallenge(tester, 'need');
      await tester.enterText(key('mg-code'), 'speed=5\nprint( speed )');
      await tapAndSettle(tester, key('mg-run'));
      expect(key('mg-missing'), findsNothing);
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('need'), 3);
    });

    testWidgets('fix the bug: the starting code shows its real error first', (
      tester,
    ) async {
      final fix = Challenge.fixBug(
        id: 'fixspeed',
        title: (_) => 'Fix speed',
        prompt: (_) => 'Fix it so print(speed) shows 5.',
        hints: [(_) => 'h1', (_) => 'h2'],
        starter: 'speed = 5\nprint(Speed)',
        solution: 'speed = 5\nprint(speed)',
        requiredCode: const ['speed =', 'print(speed)'],
        tests: const [
          TestCase(output: ['5']),
        ],
      );
      final (progress, _) = await pumpMap(
        tester,
        levels: [
          MinigameLevel(number: 1, challenges: [fix]),
        ],
      );
      await openChallenge(tester, 'fixspeed');
      // Run the starting code as it is: the real NameError, no message.
      await tapAndSettle(tester, key('mg-run'));
      expect(key('mg-error'), findsOneWidget);
      expect(find.textContaining('NameError'), findsOneWidget);
      expect(key('mg-missing'), findsNothing);

      // Right output, but a piece is missing: the message, no star lost.
      await tester.enterText(key('mg-code'), 'print(5)');
      await tapAndSettle(tester, key('mg-run'));
      expect(
        find.text(mustUse(en, ['speed =', 'print(speed)'])),
        findsOneWidget,
      );
      expect(starsLeft(tester), 3);

      await tester.enterText(key('mg-code'), 'speed = 5\nprint(speed)');
      await tapAndSettle(tester, key('mg-run'));
      expect(progress.bestStars('fixspeed'), 3);
    });

    testWidgets('the message is in Tagalog too', (tester) async {
      await pumpMap(
        tester,
        lang: 'tl',
        levels: [
          MinigameLevel(number: 1, challenges: [need]),
        ],
      );
      await openChallenge(tester, 'need');
      await tester.enterText(key('mg-code'), 'print(5)');
      await tapAndSettle(tester, key('mg-run'));
      expect(
        find.text(mustUse(tl, ['speed = 5', 'print(speed)'])),
        findsOneWidget,
      );
    });
  });

  group('Moving on', () {
    testWidgets('Next challenge opens the next one; the last goes back', (
      tester,
    ) async {
      await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('80'));
      await tapAndSettle(tester, key('mg-check'));
      await tapAndSettle(tester, key('mg-next'));
      expect(find.text(plain(en.mgL1C2Prompt)), findsOneWidget);

      await tapAndSettle(tester, key('mg-choice-0'));
      await tapAndSettle(tester, key('mg-run'));
      await tapAndSettle(tester, key('mg-next'));
      expect(find.text(en.mgL1C3Title), findsWidgets);

      await tester.enterText(key('mg-code'), 'speed = 5\nprint(speed)');
      await tapAndSettle(tester, key('mg-run'));
      expect(key('mg-next'), findsOneWidget); // 7 more to go
      await tapAndSettle(tester, key('mg-back-level'));
      expect(find.byType(ChallengeScreen), findsNothing);
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      expect(find.textContaining(en.mgSolved(3, 10)), findsOneWidget);

      // The last challenge (10) has no Next button, only Back.
      await tapAndSettle(tester, key('mg-challenge-mgL1C10'));
      await tester.enterText(
        key('mg-code'),
        'robot_name = "Cog"\nspeed = 5\nis_moving = True\n'
        'print(robot_name)\nprint(speed)\nprint(is_moving)',
      );
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(key('mg-next'), findsNothing);
      await tapAndSettle(tester, key('mg-back-level'));
      expect(find.textContaining(en.mgSolved(4, 10)), findsOneWidget);
    });

    testWidgets('solving the 7th challenge opens the next level', (
      tester,
    ) async {
      final levels = [
        MinigameLevel(
          number: 1,
          challenges: [for (var c = 1; c <= 10; c++) quiz('q$c')],
        ),
        MinigameLevel(number: 2, challenges: [quiz('r1')]),
      ];
      await pumpMap(
        tester,
        levels: levels,
        saved: {for (var c = 1; c <= 6; c++) 'minigame.stars.q$c': 1},
      );
      expect(find.text(en.mgLocked), findsOneWidget);
      await openChallenge(tester, 'q7');
      await tapAndSettle(tester, answer('yes'));
      await tapAndSettle(tester, key('mg-check'));
      expect(
        find.text('${en.mgPassed(3)}\n${en.mgUnlocked(2)}'),
        findsOneWidget,
      );
      // Back on the map, Level 2 is open.
      await tapAndSettle(tester, key('mg-back-level'));
      await goBack(tester);
      await tester.pumpAndSettle();
      expect(find.text(en.mgLocked), findsNothing);
      await tapAndSettle(tester, key('mg-level-2'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
    });
  });

  group('Level 2', () {
    // 7 Level 1 challenges with a star open Level 2.
    final level1Done = {
      for (var c = 1; c <= 7; c++) 'minigame.stars.mgL1C$c': 1,
    };

    testWidgets('opens after 7 Level 1 stars and lists its 10 challenges', (
      tester,
    ) async {
      await pumpMap(tester, size: const Size(800, 2000));
      await tapAndSettle(tester, key('mg-level-2'));
      expect(find.text(en.mgLevelLocked(1)), findsOneWidget);

      await pumpMap(tester, size: const Size(800, 2000), saved: level1Done);
      await tapAndSettle(tester, key('mg-level-2'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[1].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
      expect(find.textContaining(en.mgSolved(0, 10)), findsOneWidget);
    });
  });

  group('Level 3', () {
    testWidgets('challenge 3: a wrong comparison with the right output gets '
        'the "must use" message; spaces around > do not matter', (
      tester,
    ) async {
      final level3 = MinigameLevel(
        number: 1,
        challenges: [minigameLevels[2].challenges[2]], // mgL3C3
      );
      final (progress, _) = await pumpMap(tester, levels: [level3]);
      await openChallenge(tester, 'mgL3C3');

      await tester.enterText(
        key('mg-code'),
        'lives = 3\nif lives >= 0:\n    print("Keep playing!")',
      );
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(plainMustUse(en, ['if lives > 0'])), findsOneWidget);
      expect(progress.bestStars('mgL3C3'), 0);

      await tester.enterText(
        key('mg-code'),
        'lives=3\nif lives>0:\n    print("Keep playing!")',
      );
      await tapAndSettle(tester, key('mg-run'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('mgL3C3'), 3);
    });

    testWidgets('opens after 7 Level 2 stars and lists its 10 challenges', (
      tester,
    ) async {
      final level1Done = {
        for (var c = 1; c <= 7; c++) 'minigame.stars.mgL1C$c': 1,
      };
      await pumpMap(tester, size: const Size(800, 2000), saved: level1Done);
      await tapAndSettle(tester, key('mg-level-3'));
      expect(find.text(en.mgLevelLocked(2)), findsOneWidget);

      await pumpMap(
        tester,
        size: const Size(800, 2000),
        saved: {
          ...level1Done,
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL2C$c': 1,
        },
      );
      await tapAndSettle(tester, key('mg-level-3'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[2].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
    });
  });

  group('Level 4', () {
    testWidgets('opens after 7 Level 3 stars and lists its 10 challenges', (
      tester,
    ) async {
      final levels1to2 = {
        for (var c = 1; c <= 7; c++) 'minigame.stars.mgL1C$c': 1,
        for (var c = 1; c <= 7; c++) 'minigame.stars.mgL2C$c': 1,
      };
      await pumpMap(tester, size: const Size(800, 2000), saved: levels1to2);
      await tapAndSettle(tester, key('mg-level-4'));
      expect(find.text(en.mgLevelLocked(3)), findsOneWidget);

      await pumpMap(
        tester,
        size: const Size(800, 2000),
        saved: {
          ...levels1to2,
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL3C$c': 1,
        },
      );
      await tapAndSettle(tester, key('mg-level-4'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[3].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
    });
  });

  group('Level 5', () {
    testWidgets('opens after 7 Level 4 stars and lists its 10 challenges', (
      tester,
    ) async {
      final levels1to3 = {
        for (var l = 1; l <= 3; l++)
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL${l}C$c': 1,
      };
      await pumpMap(tester, size: const Size(800, 2000), saved: levels1to3);
      await tapAndSettle(tester, key('mg-level-5'));
      expect(find.text(en.mgLevelLocked(4)), findsOneWidget);

      await pumpMap(
        tester,
        size: const Size(800, 2000),
        saved: {
          ...levels1to3,
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL4C$c': 1,
        },
      );
      await tapAndSettle(tester, key('mg-level-5'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[4].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
    });
  });

  group('Level 6', () {
    testWidgets('opens after 7 Level 5 stars and lists its 10 challenges', (
      tester,
    ) async {
      final levels1to4 = {
        for (var l = 1; l <= 4; l++)
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL${l}C$c': 1,
      };
      await pumpMap(tester, size: const Size(800, 2000), saved: levels1to4);
      await tapAndSettle(tester, key('mg-level-6'));
      expect(find.text(en.mgLevelLocked(5)), findsOneWidget);

      await pumpMap(
        tester,
        size: const Size(800, 2000),
        saved: {
          ...levels1to4,
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL5C$c': 1,
        },
      );
      await tapAndSettle(tester, key('mg-level-6'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[5].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
    });
  });

  group('Level 7', () {
    testWidgets('opens after 7 Level 6 stars and lists its 10 challenges', (
      tester,
    ) async {
      final levels1to5 = {
        for (var l = 1; l <= 5; l++)
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL${l}C$c': 1,
      };
      await pumpMap(tester, size: const Size(800, 2000), saved: levels1to5);
      await tapAndSettle(tester, key('mg-level-7'));
      expect(find.text(en.mgLevelLocked(6)), findsOneWidget);

      await pumpMap(
        tester,
        size: const Size(800, 2000),
        saved: {
          ...levels1to5,
          for (var c = 1; c <= 7; c++) 'minigame.stars.mgL6C$c': 1,
        },
      );
      await tapAndSettle(tester, key('mg-level-7'));
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      for (final c in minigameLevels[6].challenges) {
        expect(find.text(c.title(en)), findsOneWidget, reason: c.id);
      }
    });
  });

  group('Fits a 360px phone', () {
    for (final number in [1, 2, 3, 4, 5, 6, 7]) {
      for (final lang in ['en', 'tl']) {
        testWidgets('every Level $number challenge, with hints and a failed '
            'run ($lang)', (tester) async {
          final l10n = lang == 'en' ? en : tl;
          await pumpMap(
            tester,
            lang: lang,
            size: const Size(360, 640),
            saved: {
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL1C$c': 1,
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL2C$c': 1,
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL3C$c': 1,
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL4C$c': 1,
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL5C$c': 1,
              for (var c = 1; c <= 7; c++) 'minigame.stars.mgL6C$c': 1,
            },
          );
          expect(find.text(l10n.mgMapTitle), findsOneWidget);
          // The map builds its tiles lazily: scroll the level into view.
          await tester.scrollUntilVisible(
            key('mg-level-$number'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tapAndSettle(tester, key('mg-level-$number'));
          for (final c in minigameLevels[number - 1].challenges) {
            await tapAndSettle(tester, key('mg-challenge-${c.id}'));
            if (c.hints.isNotEmpty) {
              await tapAndSettle(tester, key('mg-hint'));
              await tapAndSettle(tester, key('mg-hint'));
            }
            if (c.type == ChallengeType.writeCode) {
              await tester.enterText(key('mg-code'), 'print(1)');
              await tapAndSettle(tester, key('mg-run'));
              // The output is wrong, so the failed test is shown (the
              // "must use" message only comes when the output is right).
              expect(find.text(l10n.mgFailed(1)), findsOneWidget);
              expect(key('mg-missing'), findsNothing);
            }
            await goBack(tester);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
