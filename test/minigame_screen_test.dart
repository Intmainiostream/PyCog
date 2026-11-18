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
      expect(find.text(en.mgSolved(0, 3)), findsOneWidget);
      expect(find.text('0/9'), findsOneWidget);
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
      expect(find.text('4/9'), findsOneWidget);
      expect(find.text(en.mgSolved(2, 3)), findsOneWidget);
    });

    testWidgets('an open level lists its challenges with their stars', (
      tester,
    ) async {
      await pumpMap(tester, saved: {'minigame.stars.mgL1C2': 2});
      await tapAndSettle(tester, key('mg-level-1'));
      expect(find.text(en.mgL1C1Title), findsOneWidget);
      expect(find.text(en.mgL1C2Title), findsOneWidget);
      expect(find.text(en.mgL1C3Title), findsOneWidget);
      expect(find.text(en.mgTypeQuiz), findsOneWidget);
      expect(find.text(en.mgTypeFillBlank), findsOneWidget);
      expect(find.text(en.mgTypeWriteCode), findsOneWidget);
      final stars = tester.widgetList<StarRow>(find.byType(StarRow));
      expect(stars.map((s) => s.stars), [0, 2, 0]);
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
      expect(find.text(en.mgL1C1Prompt), findsOneWidget);
      expect(find.text('battery = battery + 10'), findsOneWidget);
      expect(key('mg-hint'), findsNothing);
      expect(starsLeft(tester), 3);

      await tapAndSettle(tester, answer('60'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(3)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 3);
    });

    testWidgets('right on the second try = 2 stars', (tester) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('50'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgTryAgain), findsOneWidget);
      expect(starsLeft(tester), 2);

      await tapAndSettle(tester, answer('60'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 2);
    });

    testWidgets('third try = 1 star, and later tries stay at 1', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      for (final (wrong, left) in [('50', 2), ('10', 1), ('battery', 1)]) {
        await tapAndSettle(tester, answer(wrong));
        await tapAndSettle(tester, key('mg-check'));
        expect(starsLeft(tester), left, reason: 'after picking $wrong');
      }
      await tapAndSettle(tester, answer('60'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(1)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 1);
    });

    testWidgets('a wrong pick is saved: leaving does not reset it', (
      tester,
    ) async {
      final (progress, _) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('50'));
      await tapAndSettle(tester, key('mg-check'));
      // `50` is answers[1] in the data.
      expect(progress.wrongPicks('mgL1C1'), {1});

      await goBack(tester);
      await tapAndSettle(tester, key('mg-challenge-mgL1C1'));
      // Still marked wrong, can't be picked again, and still 2 stars.
      expect(
        find.descendant(
          of: answer('50'),
          matching: find.byIcon(Icons.cancel_rounded),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, answer('50'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgTryAgain), findsNothing); // nothing was picked
      expect(starsLeft(tester), 2);

      await tapAndSettle(tester, answer('60'));
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
      await tapAndSettle(tester, answer('50'));
      await tapAndSettle(tester, key('mg-check'));
      await tapAndSettle(tester, answer('60'));
      await tapAndSettle(tester, key('mg-check'));
      expect(find.text(en.mgPassed(2)), findsOneWidget);
      expect(progress.bestStars('mgL1C1'), 3);
    });
  });

  group('Hints (code challenges)', () {
    const solution = 'age = int(input("Age? "))\nprint(age + 1)';

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
      final stars = tester.widgetList<StarRow>(find.byType(StarRow));
      expect(stars.last.stars, 3);

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
      final (progress, engine) = await pumpMap(tester);
      await openChallenge(tester, 'mgL1C3');
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
      expect(progress.bestStars('mgL1C3'), 0);

      await tester.enterText(
        key('mg-code'),
        'age = int(input("Age? "))\nprint(age + 1)',
      );
      await tapAndSettle(tester, key('mg-run'));
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

  group('Moving on', () {
    testWidgets('Next challenge opens the next one; the last goes back', (
      tester,
    ) async {
      await pumpMap(tester);
      await openChallenge(tester, 'mgL1C1');
      await tapAndSettle(tester, answer('60'));
      await tapAndSettle(tester, key('mg-check'));
      await tapAndSettle(tester, key('mg-next'));
      expect(find.text(plain(en.mgL1C2Prompt)), findsOneWidget);

      await tapAndSettle(tester, key('mg-choice-0'));
      await tapAndSettle(tester, key('mg-run'));
      await tapAndSettle(tester, key('mg-next'));
      expect(find.text(en.mgL1C3Title), findsWidgets);

      await tester.enterText(
        key('mg-code'),
        'age = int(input("Age? "))\nprint(age + 1)',
      );
      await tapAndSettle(tester, key('mg-run'));
      expect(key('mg-next'), findsNothing); // the last one
      await tapAndSettle(tester, key('mg-back-level'));
      expect(find.byType(ChallengeScreen), findsNothing);
      expect(find.byType(MinigameLevelScreen), findsOneWidget);
      expect(find.textContaining(en.mgSolved(3, 3)), findsOneWidget);
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

  group('Fits a 360px phone', () {
    for (final lang in ['en', 'tl']) {
      testWidgets('every Level 1 challenge, with hints and a failed run '
          '($lang)', (tester) async {
        final l10n = lang == 'en' ? en : tl;
        await pumpMap(tester, lang: lang, size: const Size(360, 640));
        expect(find.text(l10n.mgMapTitle), findsOneWidget);
        await tapAndSettle(tester, key('mg-level-1'));
        for (final c in level1.challenges) {
          await tapAndSettle(tester, key('mg-challenge-${c.id}'));
          if (c.hints.isNotEmpty) {
            await tapAndSettle(tester, key('mg-hint'));
            await tapAndSettle(tester, key('mg-hint'));
          }
          if (c.type == ChallengeType.writeCode) {
            await tester.enterText(key('mg-code'), 'print(1)');
            await tapAndSettle(tester, key('mg-run'));
            expect(find.text(l10n.mgFailed(1)), findsOneWidget);
          }
          await goBack(tester);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
