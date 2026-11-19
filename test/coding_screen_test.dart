import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/playground/coding_examples.dart';
import 'package:pycog/playground/coding_output.dart';
import 'package:pycog/playground/python_runner.dart';
import 'package:pycog/screens/coding_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/cog_feedback_card.dart';
import 'package:pycog/widgets/output_box.dart';

final en = lookupAppLocalizations(const Locale('en'));
final tl = lookupAppLocalizations(const Locale('tl'));

/// Stands in for real Python (which needs an Android WebView).
class FakeEngine implements PythonEngine {
  final calls = <(String, List<String>)>[];

  @override
  final ValueNotifier<bool> isReady = ValueNotifier(true);

  /// What the next run gives back.
  PythonResult next = const PythonResult(stdout: '5\n', elapsed: Duration.zero);

  /// When set, runs wait for it (to see the "Starting Python..." state).
  Completer<void>? gate;

  @override
  Future<PythonResult> run(
    String code, {
    List<String> inputs = const [],
    Duration timeout = const Duration(seconds: 3),
  }) async {
    calls.add((code, inputs));
    await gate?.future;
    return next;
  }
}

final code = find.byKey(const ValueKey('coding-code'));
final answers = find.byKey(const ValueKey('coding-answers'));
final run = find.byKey(const ValueKey('coding-run'));
final clear = find.byKey(const ValueKey('coding-clear'));
final examples = find.byKey(const ValueKey('coding-examples'));
final helpers = find.byKey(const ValueKey('coding-helpers'));

String codeText(WidgetTester tester) =>
    tester.widget<TextField>(code).controller!.text;

Future<(FakeEngine, SettingsController)> pumpCoding(
  WidgetTester tester, {
  Size size = const Size(800, 1400),
  String lang = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'settings.language': lang});
  final settings = await SettingsController.load();
  final engine = FakeEngine();
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
        home: CodingScreen(settings: settings, engine: engine),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (engine, settings);
}

Future<void> tapRun(WidgetTester tester) async {
  await tester.ensureVisible(run);
  await tester.tap(run);
  await tester.pumpAndSettle();
}

/// The rows inside the output box (after its "Output" label).
List<String> outputRows(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(OutputBox), matching: find.byType(Text)),
    )
    .skip(1)
    .map((t) => t.data!)
    .toList();

void main() {
  setUp(CodingSession.reset);

  group('Running code', () {
    testWidgets('Run sends the code and shows what it printed', (tester) async {
      final (engine, _) = await pumpCoding(tester);
      await tester.enterText(code, 'print(2 + 3)');
      await tapRun(tester);
      expect(engine.calls.single.$1, 'print(2 + 3)');
      expect(engine.calls.single.$2, isEmpty);
      expect(outputRows(tester), ['5']);
      expect(find.byKey(const ValueKey('coding-error')), findsNothing);
    });

    testWidgets('An error: the real last line, then one line from Cog', (
      tester,
    ) async {
      final (engine, _) = await pumpCoding(tester);
      const error = "ValueError: invalid literal for int() with base 10: 'abc'";
      engine.next = const PythonResult(
        stdout: '',
        error: error,
        elapsed: Duration.zero,
      );
      await tapRun(tester);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('coding-error')),
          matching: find.text(error),
        ),
        findsOneWidget,
      );
      final cog = tester.widget<CogFeedbackCard>(find.byType(CogFeedbackCard));
      expect(cog.text, en.codingTipValue);
    });

    testWidgets('A timeout: the friendly message, and what was printed', (
      tester,
    ) async {
      final (engine, _) = await pumpCoding(tester);
      engine.next = const PythonResult(
        stdout: '1\n2\n',
        timedOut: true,
        elapsed: Duration(seconds: 3),
      );
      await tapRun(tester);
      expect(outputRows(tester), ['1', '2']);
      final cog = tester.widget<CogFeedbackCard>(find.byType(CogFeedbackCard));
      expect(cog.text, en.codingTimeout);
    });

    testWidgets('Nothing printed: a short note, no empty box', (tester) async {
      final (engine, _) = await pumpCoding(tester);
      engine.next = const PythonResult(stdout: '', elapsed: Duration.zero);
      await tapRun(tester);
      expect(find.byType(OutputBox), findsNothing);
      expect(find.text(en.codingNothingPrinted), findsOneWidget);
    });

    testWidgets('Python not started: friendly message, no raw error', (
      tester,
    ) async {
      final (engine, _) = await pumpCoding(tester);
      engine.next = const PythonResult(
        stdout: '',
        error: 'PythonStartError: no WebView',
        elapsed: Duration.zero,
      );
      await tapRun(tester);
      expect(find.byKey(const ValueKey('coding-error')), findsNothing);
      expect(
        tester.widget<CogFeedbackCard>(find.byType(CogFeedbackCard)).text,
        en.codingStartError,
      );
    });

    testWidgets('"Starting Python..." until Python is ready', (tester) async {
      final (engine, _) = await pumpCoding(tester);
      engine.isReady.value = false;
      engine.gate = Completer<void>();
      await tester.ensureVisible(run);
      await tester.tap(run);
      await tester.pump();
      expect(find.text(en.codingStarting), findsOneWidget);
      engine.isReady.value = true;
      await tester.pump();
      expect(find.text(en.codingRunning), findsOneWidget);
      engine.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(en.codingRunning), findsNothing);
      expect(outputRows(tester), ['5']);
    });
  });

  group('input() and typed answers', () {
    testWidgets('The answers box shows only when the code uses input(', (
      tester,
    ) async {
      await pumpCoding(tester);
      await tester.enterText(code, 'print("hi")');
      await tester.pump();
      expect(answers, findsNothing);
      await tester.enterText(code, 'name = input("Name? ")');
      await tester.pump();
      expect(answers, findsOneWidget);
    });

    testWidgets('Answers go in order; they show in the typed chip', (
      tester,
    ) async {
      final (engine, _) = await pumpCoding(tester);
      await tester.enterText(
        code,
        'name = input("Name? ")\nage = int(input("Age? "))\nprint(age + 1)',
      );
      await tester.pump();
      await tester.enterText(answers, 'Ana\n12\n\n'); // blank lines at the end
      // Like real Python: question, answer, Enter.
      engine.next = const PythonResult(
        stdout: 'Name? Ana\nAge? 12\n13\n',
        typed: [TypedAnswer(6, 'Ana'), TypedAnswer(15, '12')],
        elapsed: Duration.zero,
      );
      await tapRun(tester);
      expect(engine.calls.single.$2, ['Ana', '12']);
      // Questions in the rows, answers in the "typed by the person" chips.
      expect(outputRows(tester), [
        'Name? ',
        'Ana',
        'Age? ',
        '12',
        '13',
        en.lesson9TypedLabel,
      ]);
      expect(find.byKey(const ValueKey('typed-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('typed-1')), findsOneWidget);
    });

    testWidgets('Too few answers: a clear, friendly message', (tester) async {
      final (engine, _) = await pumpCoding(tester);
      await tester.enterText(code, 'a = input("A? ")\nb = input("B? ")');
      await tester.pump();
      await tester.enterText(answers, 'one');
      engine.next = const PythonResult(
        stdout: 'A? one\nB? ',
        typed: [TypedAnswer(3, 'one')],
        error: 'EOFError: EOF when reading a line',
        elapsed: Duration.zero,
      );
      await tapRun(tester);
      expect(
        tester.widget<CogFeedbackCard>(find.byType(CogFeedbackCard)).text,
        en.codingNeedMoreAnswers,
      );
    });
  });

  group('Editing', () {
    testWidgets('Examples fill the code box (and typed answers)', (
      tester,
    ) async {
      await pumpCoding(tester);
      for (final example in codingExamples) {
        await tester.tap(examples);
        await tester.pumpAndSettle();
        await tester.tap(find.text(example.title(en)).last);
        await tester.pumpAndSettle();
        expect(codeText(tester), example.code);
        if (example.answers.isNotEmpty) {
          expect(
            tester.widget<TextField>(answers).controller!.text,
            example.answers.join('\n'),
          );
        }
      }
    });

    testWidgets('Helper buttons show while typing and type symbols', (
      tester,
    ) async {
      await pumpCoding(tester);
      expect(helpers, findsNothing);
      await tester.enterText(code, 'print');
      await tester.pump();
      expect(helpers, findsOneWidget); // the code box has focus
      Future<void> key(String label) async {
        await tester.tap(find.byKey(ValueKey('coding-key-$label')));
        await tester.pump();
      }

      await key('( )'); // print() with the cursor inside
      await key('" "'); // print("") with the cursor inside the quotes
      expect(codeText(tester), 'print("")');
      final selection = tester.widget<TextField>(code).controller!.selection;
      expect(selection.baseOffset, 'print("'.length);
      await key('Tab');
      expect(codeText(tester), 'print("    ")');
      expect(helpers, findsOneWidget); // still typing
    });

    testWidgets('Clear empties the box; Undo brings it back', (tester) async {
      await pumpCoding(tester);
      await tester.enterText(code, 'print("keep me")');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(codeText(tester), '');
      await tester.tap(find.text(en.codingUndo));
      await tester.pumpAndSettle();
      expect(codeText(tester), 'print("keep me")');
    });

    testWidgets('The code is kept while the app is open', (tester) async {
      await pumpCoding(tester);
      await tester.enterText(code, 'x = 42');
      expect(CodingSession.code, 'x = 42');
      // Leave and open the screen again.
      await tester.pumpWidget(const SizedBox());
      await pumpCoding(tester);
      expect(codeText(tester), 'x = 42');
    });
  });

  group('Languages and licenses', () {
    testWidgets('Tagalog labels', (tester) async {
      await pumpCoding(tester, lang: 'tl');
      expect(find.text(tl.codingTitle), findsOneWidget);
      expect(find.text(tl.codingRun), findsOneWidget);
      expect(find.text(tl.codingAbout), findsOneWidget);
    });

    testWidgets('About line and the license page button', (tester) async {
      await pumpCoding(tester);
      expect(find.text(en.codingAbout), findsOneWidget);
      expect(en.codingAbout, allOf(contains('MPL-2.0'), contains('PSF')));
      expect(find.text(en.codingLicenses), findsOneWidget);
    });

    test('the license texts are bundled', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final pyodide = await rootBundle.loadString(
        'assets/pyodide/LICENSE-pyodide.txt',
      );
      final cpython = await rootBundle.loadString(
        'assets/pyodide/LICENSE-cpython.txt',
      );
      expect(pyodide, startsWith('Mozilla Public License Version 2.0'));
      expect(cpython, contains('PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2'));
    });
  });

  group('Output helpers', () {
    test('splitOutput moves typed answers out of their rows', () {
      final (rows, typed) = splitOutput('Age? 12\n13\n', const [
        TypedAnswer(5, '12'),
      ]);
      expect(rows, ['Age? ', '13']);
      expect(typed, {0: '12'});
      final (plain, none) = splitOutput('a\nb\n', const []);
      expect(plain, ['a', 'b']);
      expect(none, isEmpty);
      expect(splitOutput('', const []).$1, isEmpty);
    });

    test('Cog has a friendly line for each common error', () {
      expect(
        friendlyTip(en, 'SyntaxError: invalid syntax'),
        en.codingTipSyntax,
      );
      expect(
        friendlyTip(en, 'IndentationError: expected an indented block'),
        en.codingTipIndent,
      );
      expect(
        friendlyTip(en, "NameError: name 'x' is not defined"),
        en.codingTipName,
      );
      expect(
        friendlyTip(en, 'ZeroDivisionError: division by zero'),
        en.codingTipZero,
      );
      expect(
        friendlyTip(en, 'IndexError: list index out of range'),
        en.codingTipIndex,
      );
      expect(
        friendlyTip(en, "ImportError: The module 'os' is turned off in PyCog"),
        en.codingTipBlocked,
      );
      expect(friendlyTip(en, 'KeyError: 1'), en.codingTipOther);
      expect(needsMoreAnswers('EOFError: EOF when reading a line'), isTrue);
    });
  });

  // Small phones with the biggest text, both languages: nothing overflows
  // (it would throw), with output, an error and the helper buttons showing.
  for (final (name, size) in [
    ('360x640', const Size(360, 640)),
    ('640x360', const Size(640, 360)),
  ]) {
    for (final lang in ['en', 'tl']) {
      testWidgets('Fits | $name | 1.5x + Large | $lang', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final (engine, _) = await pumpCoding(tester, size: size, lang: lang);
        await tester.enterText(code, 'age = int(input("Age? "))');
        await tester.pump();
        engine.next = const PythonResult(
          stdout: 'Age? abc\n',
          typed: [TypedAnswer(5, 'abc')],
          error: "ValueError: invalid literal for int() with base 10: 'abc'",
          elapsed: Duration.zero,
        );
        await tapRun(tester);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(code);
        await tester.pumpAndSettle();
        await tester.tap(code);
        await tester.pumpAndSettle();
        expect(helpers, findsOneWidget);
      });
    }
  }
}
