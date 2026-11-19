// Runs on a real Android device or emulator:
//   flutter test integration_test/minigame_solutions_test.dart -d <device id>
//
// Every MINIGAME challenge is checked with real Python:
//  * code challenges: the solution has the required code and passes all
//    hidden tests;
//  * fix the bug: the starting code fails;
//  * fill the blank: an empty blank and every other choice fail;
//  * quizzes with code: the code prints exactly the right answer, and no
//    wrong answer.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/data/minigame/levels.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/minigame/output_checker.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/playground/python_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MINIGAME challenges check out in real Python', (tester) async {
    final engine = PyodideEngine.instance;
    final en = lookupAppLocalizations(const Locale('en'));
    final failures = <String>[];
    var checked = 0;

    void report(String id, String what, bool ok, [String detail = '']) {
      // ignore: avoid_print
      print('MINIGAME ${ok ? 'PASS' : 'FAIL'} | $id | $what $detail');
      if (!ok) failures.add('$id: $what');
    }

    String shown(CheckResult r) => r.passed
        ? ''
        : '| test ${r.failedNumber}: '
              'stdout=${r.got!.stdout.replaceAll('\n', r'\n')} '
              'error=${r.got!.error}';

    for (final level in minigameLevels) {
      for (final c in level.challenges) {
        checked++;
        if (c.type == ChallengeType.quiz) {
          if (c.code.isEmpty) {
            report(c.id, 'quiz without code (nothing to run)', true);
            continue;
          }
          final code = c.code.map((line) => line.code).join('\n');
          final result = await engine.run(code);
          if (!code.contains('print(')) {
            // The question is about the code (e.g. a value's type), not
            // what it prints: it just has to run without an error.
            report(c.id, 'quiz code runs without an error', result.ok);
            continue;
          }
          final printed = normalizeOutput(result.stdout);
          final right = c.answers.indexWhere((a) => a.correct);
          String label(int i) => c.answers[i].label(en).replaceAll('`', '');
          report(
            c.id,
            'quiz code prints the right answer',
            result.ok && printed == label(right),
            '| printed=${printed.replaceAll('\n', r'\n')}',
          );
          for (var i = 0; i < c.answers.length; i++) {
            if (i == right) continue;
            report(
              c.id,
              'wrong answer ${label(i)} is not the output',
              printed != label(i),
            );
          }
          continue;
        }

        final solution = await checkProgram(
          engine,
          c.solutionProgram,
          c.tests,
          required: c.requiredCode,
        );
        report(c.id, 'solution passes', solution.passed, shown(solution));

        if (c.type == ChallengeType.fixBug) {
          final start = await checkProgram(engine, c.starter, c.tests);
          report(c.id, 'starting code fails', !start.passed);
        }
        if (c.type == ChallengeType.fillBlank) {
          for (final wrong in [
            '',
            ...c.choices.where((x) => x != c.solution),
          ]) {
            final r = await checkProgram(engine, c.programFor(wrong), c.tests);
            report(
              c.id,
              wrong.isEmpty ? 'empty blank fails' : 'wrong choice $wrong fails',
              !r.passed,
            );
          }
        }
      }
    }
    // ignore: avoid_print
    print('MINIGAME checked $checked challenges');
    // Every challenge of every level was checked (Level 1 and 2: 20).
    final total = minigameLevels.fold(0, (n, l) => n + l.challenges.length);
    expect(checked, total);
    expect(total, greaterThanOrEqualTo(20));
    expect(failures, isEmpty, reason: 'failed: $failures');
  });
}
