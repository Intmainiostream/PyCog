import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/playground/python_checks.dart';
import 'package:pycog/playground/python_runner.dart';
import 'package:pycog/playground/python_test_screen.dart';
import 'package:pycog/theme/app_theme.dart';

/// Stands in for real Python (which needs an Android WebView; the real
/// thing is tested on a device by integration_test/python_runner_test.dart).
class FakeEngine implements PythonEngine {
  final calls = <(String, List<String>)>[];

  @override
  final ValueNotifier<bool> isReady = ValueNotifier(true);
  PythonResult Function(String code, List<String> inputs) answer = (c, i) =>
      const PythonResult(stdout: '5\n', elapsed: Duration(milliseconds: 7));

  @override
  Future<PythonResult> run(
    String code, {
    List<String> inputs = const [],
    Duration timeout = const Duration(seconds: 3),
  }) async {
    calls.add((code, inputs));
    return answer(code, inputs);
  }
}

Future<FakeEngine> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final engine = FakeEngine();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: PythonTestScreen(engine: engine),
    ),
  );
  return engine;
}

void main() {
  testWidgets('Run sends the code and typed answers; shows the output', (
    tester,
  ) async {
    final engine = await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const ValueKey('py-code')),
      'age = int(input("Age? "))\nprint(age + 1)',
    );
    await tester.enterText(find.byKey(const ValueKey('py-answers')), '12\n');
    engine.answer = (c, i) => const PythonResult(
      stdout: 'Age? 12\n13\n',
      elapsed: Duration(milliseconds: 8),
    );
    await tester.tap(find.byKey(const ValueKey('py-run')));
    await tester.pumpAndSettle();
    expect(engine.calls.single.$2, ['12']);
    expect(find.textContaining('13'), findsOneWidget);
  });

  testWidgets('An error and a timeout are shown clearly', (tester) async {
    final engine = await pumpScreen(tester);
    engine.answer = (c, i) => const PythonResult(
      stdout: '',
      error: "ValueError: invalid literal for int() with base 10: 'abc'",
      elapsed: Duration(milliseconds: 7),
    );
    await tester.tap(find.byKey(const ValueKey('py-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ValueError'), findsOneWidget);

    engine.answer = (c, i) => const PythonResult(
      stdout: '',
      timedOut: true,
      elapsed: Duration(seconds: 3),
    );
    await tester.tap(find.byKey(const ValueKey('py-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('longer than 3 seconds'), findsOneWidget);
  });

  testWidgets('Run all checks runs every check in order', (tester) async {
    final engine = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('py-checks')));
    await tester.pumpAndSettle();
    expect(engine.calls.map((c) => c.$1), [
      for (final check in pythonChecks) check.code,
    ]);
    expect(
      find.textContaining('of ${pythonChecks.length} passed'),
      findsOneWidget,
    );
  });

  test('the six requested checks are in the list', () {
    final names = pythonChecks.where((c) => !c.sandbox).map((c) => c.name);
    expect(names, [
      'print(2 + 3)',
      'for loop with range',
      'function with return',
      'input() with 12 typed',
      'int("abc") error',
      'while True stops',
    ]);
    expect(
      pythonChecks.singleWhere((c) => c.name == 'input() with 12 typed').inputs,
      ['12'],
    );
  });
}
