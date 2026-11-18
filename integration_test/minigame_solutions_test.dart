// Runs on a real Android device or emulator:
//   flutter test integration_test/minigame_solutions_test.dart -d <device id>
//
// Every MINIGAME code challenge is checked with real Python: its solution
// must pass all hidden tests, and (for fill the blank) every other choice
// must fail.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/minigame/output_checker.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/playground/python_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MINIGAME solutions pass their hidden tests in real Python', (
    tester,
  ) async {
    final engine = PyodideEngine.instance;
    final failures = <String>[];
    for (final level in minigameLevels) {
      for (final c in level.challenges.where((c) => c.runsCode)) {
        final result = await checkProgram(engine, c.solutionProgram, c.tests);
        // ignore: avoid_print
        print(
          'MINIGAME ${result.passed ? 'PASS' : 'FAIL'} | ${c.id} solution'
          '${result.passed ? '' : ' | test ${result.failedNumber}: '
                    'stdout=${result.got!.stdout.replaceAll('\n', r'\n')} '
                    'error=${result.got!.error}'}',
        );
        if (!result.passed) failures.add('${c.id} solution');

        if (c.type == ChallengeType.fillBlank) {
          for (final choice in c.choices.where((x) => x != c.solution)) {
            final wrong = await checkProgram(
              engine,
              c.programFor(choice),
              c.tests,
            );
            // ignore: avoid_print
            print(
              'MINIGAME ${wrong.passed ? 'FAIL' : 'PASS'} | ${c.id} '
              'wrong choice $choice is rejected',
            );
            if (wrong.passed) failures.add('${c.id} choice $choice');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: 'failed: $failures');
  });
}
