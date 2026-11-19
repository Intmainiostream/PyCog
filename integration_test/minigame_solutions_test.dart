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
          // Several printed lines are written as one answer: `2, 3, 4`.
          final printed = normalizeOutput(result.stdout).split('\n').join(', ');
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
          // Fails in real Python even without the "must use" check.
          final start = await checkProgram(engine, c.starter, c.tests);
          report(c.id, 'starting code fails', !start.passed);
        }
        if (c.requiredCode.isNotEmpty) {
          // The solution written with no spaces around signs and after
          // commas (e.g. `if lives>0:`, `range(1,6)`, `battery-1`) still
          // passes, pieces included. Lines inside quotes are left alone.
          final tight = c.solutionProgram
              .split('\n')
              .map(
                (line) => line.contains('"')
                    ? line
                    : line.replaceAllMapped(
                        RegExp(
                          r' *(==|!=|<=|>=|\*\*|//|<|>|=|\+|-|\*|/|%|,) *',
                        ),
                        (m) => m[1]!,
                      ),
              )
              .join('\n');
          final tightResult = await checkProgram(
            engine,
            tight,
            c.tests,
            required: c.requiredCode,
          );
          report(
            c.id,
            'solution without spaces around signs passes',
            tightResult.passed,
            shown(tightResult),
          );

          // A wrong sign in any piece (the first sign swapped, e.g. `>` for
          // `>=`, `-` for `+`) must not pass: its output is wrong, or a
          // piece is missing.
          const swap = {
            '>=': '>',
            '<=': '<',
            '==': '!=',
            '!=': '==',
            '**': '*',
            '//': '/',
            '>': '>=',
            '<': '<=',
            '+': '-',
            '-': '+',
            '*': '**',
            '/': '//',
            '%': '//',
          };
          final sign = RegExp(r'==|!=|<=|>=|\*\*|//|<|>|\+|-|\*|/|%');
          for (final piece in c.requiredCode.where(sign.hasMatch)) {
            final s = sign.firstMatch(piece)![0]!;
            final wrongPiece = piece.replaceFirst(s, swap[s]!);
            final wrong = c.solutionProgram.replaceFirst(piece, wrongPiece);
            if (wrong == c.solutionProgram) continue;
            final r = await checkProgram(
              engine,
              wrong,
              c.tests,
              required: c.requiredCode,
            );
            report(c.id, 'wrong sign ($wrongPiece) fails', !r.passed);
          }

          // A wrong range (its last number one bigger, e.g. range(1, 7) for
          // range(1, 6)) must not pass either.
          final rangeCall = RegExp(r'range\(([^)]*?)(\d+)\)');
          for (final piece in c.requiredCode.where(rangeCall.hasMatch)) {
            final m = rangeCall.firstMatch(piece)!;
            final bigger = 'range(${m[1]}${int.parse(m[2]!) + 1})';
            final wrongPiece = piece.replaceFirst(m[0]!, bigger);
            final wrong = c.solutionProgram.replaceFirst(piece, wrongPiece);
            if (wrong == c.solutionProgram) continue;
            final r = await checkProgram(
              engine,
              wrong,
              c.tests,
              required: c.requiredCode,
            );
            report(c.id, 'wrong range ($wrongPiece) fails', !r.passed);
          }

          // e.g. print(5) for "5", print("Cog") for "Cog".
          final fixedAnswer = [
            for (final line in c.tests.first.output)
              int.tryParse(line) != null || line == 'True' || line == 'False'
                  ? 'print($line)'
                  : 'print("$line")',
          ].join('\n');
          final printed = await checkProgram(
            engine,
            fixedAnswer,
            c.tests,
            required: c.requiredCode,
          );
          report(c.id, 'printing the answer fails', !printed.passed);
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
    // Every challenge of every level was checked (Levels 1-6: 60).
    final total = minigameLevels.fold(0, (n, l) => n + l.challenges.length);
    expect(checked, total);
    expect(total, greaterThanOrEqualTo(60));
    expect(failures, isEmpty, reason: 'failed: $failures');
  });
}
