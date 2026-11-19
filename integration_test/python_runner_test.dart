// Runs on a real Android device or emulator:
//   flutter test integration_test/python_runner_test.dart -d <device id>
//
// Starts real Python (Pyodide in a hidden WebView), times the first and
// second run, and runs every feasibility check.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pycog/playground/coding_examples.dart';
import 'package:pycog/playground/coding_output.dart';
import 'package:pycog/playground/python_checks.dart';
import 'package:pycog/playground/python_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline Python: timing and all checks', (tester) async {
    // First run: starts the WebView and loads Python.
    final first = await runPython('print(2 + 3)');
    // Second run: Python is already loaded.
    final second = await runPython('print(2 + 3)');
    final third = await runPython('print(sum(range(10)))');
    // ignore: avoid_print
    print(
      'TIMING first run ${first.elapsed.inMilliseconds} ms '
      '(Python load ${PyodideEngine.instance.lastLoadTime?.inMilliseconds} ms), '
      'second run ${second.elapsed.inMilliseconds} ms, '
      'third run ${third.elapsed.inMilliseconds} ms',
    );
    expect(first.stdout, '5\n');
    expect(second.stdout, '5\n');
    expect(third.stdout, '45\n');

    final failures = <String>[];
    for (final check in pythonChecks) {
      final r = await runPython(check.code, inputs: check.inputs);
      final ok = check.passes(r);
      // ignore: avoid_print
      print(
        'CHECK ${ok ? 'PASS' : 'FAIL'} | ${check.name} | '
        '${r.elapsed.inMilliseconds} ms (program ${r.runTime.inMilliseconds} ms) | '
        'stdout=${r.stdout.replaceAll('\n', r'\n')} | error=${r.error} | '
        'timedOut=${r.timedOut}',
      );
      if (!ok) failures.add(check.name);
    }

    // After a timeout, a fresh Python is started: the next run still works.
    final after = await runPython('print("still works")');
    // ignore: avoid_print
    print(
      'AFTER TIMEOUT ${after.elapsed.inMilliseconds} ms | '
      'stdout=${after.stdout.trim()} | error=${after.error}',
    );
    expect(after.stdout, 'still works\n');
    expect(failures, isEmpty, reason: 'failed checks: $failures');
  });

  testWidgets('CODING playground examples run in real Python', (tester) async {
    const expected = [
      'Hi, I am Cog!\n',
      '100\n80\n',
      'Low battery!\n',
      'Step 0\nStep 1\nStep 2\n',
      '5\n',
      'Your name? Ana\nAge? 12\nHi, Ana\nNext year: 13\n',
    ];
    for (final (i, example) in codingExamples.indexed) {
      final r = await runPython(example.code, inputs: example.answers);
      // ignore: avoid_print
      print(
        'EXAMPLE $i | ${r.elapsed.inMilliseconds} ms | '
        'stdout=${r.stdout.replaceAll('\n', r'\n')} | error=${r.error} | '
        'typed=${[for (final t in r.typed) '${t.offset}:${t.text}']}',
      );
      expect(r.error, isNull, reason: 'example $i');
      expect(r.stdout, expected[i], reason: 'example $i');
    }
    // Typed answers: where real Python put them, they split into rows.
    final input = await runPython(
      codingExamples.last.code,
      inputs: codingExamples.last.answers,
    );
    final (rows, typed) = splitOutput(input.stdout, input.typed);
    expect(rows, ['Your name? ', 'Age? ', 'Hi, Ana', 'Next year: 13']);
    expect(typed, {0: 'Ana', 1: '12'});
    // Too few answers: the error the screen turns into a friendly message.
    final short = await runPython(codingExamples.last.code, inputs: ['Ana']);
    expect(short.error, 'EOFError: EOF when reading a line');
  });
}
