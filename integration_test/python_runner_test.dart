// Runs on a real Android device or emulator:
//   flutter test integration_test/python_runner_test.dart -d <device id>
//
// Starts real Python (Pyodide in a hidden WebView), times the first and
// second run, and runs every feasibility check.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}
