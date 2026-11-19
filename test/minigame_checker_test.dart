import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pycog/minigame/output_checker.dart';
import 'package:pycog/models/minigame.dart';
import 'package:pycog/playground/python_runner.dart';

/// A pretend Python: [answer] decides what each run gives back. Every run
/// is recorded, so tests can see which hidden tests were tried.
class ScriptedEngine implements PythonEngine {
  ScriptedEngine(this.answer);

  final PythonResult Function(String code, List<String> inputs) answer;
  final runs = <List<String>>[];

  @override
  final ValueNotifier<bool> isReady = ValueNotifier(true);

  @override
  Future<PythonResult> run(
    String code, {
    List<String> inputs = const [],
    Duration timeout = const Duration(seconds: 3),
  }) async {
    runs.add(inputs);
    return answer(code, inputs);
  }
}

PythonResult printed(String stdout, {String? error, bool timedOut = false}) =>
    PythonResult(
      stdout: stdout,
      error: error,
      timedOut: timedOut,
      elapsed: Duration.zero,
    );

/// Like `age = int(input("Age? "))` then `print(age + 1)`, shown like a
/// terminal (the typed answer is echoed after the question).
PythonResult agePlusOne(String code, List<String> inputs) =>
    printed('Age? ${inputs[0]}\n${int.parse(inputs[0]) + 1}\n');

const ageTests = [
  TestCase(inputs: ['12'], output: ['Age? 12', '13']),
  TestCase(inputs: ['0'], output: ['Age? 0', '1']),
  TestCase(inputs: ['99'], output: ['Age? 99', '100']),
];

void main() {
  group('Comparing outputs', () {
    test('the same lines match', () {
      expect(outputMatches('Age? 12\n13\n', ['Age? 12', '13']), isTrue);
    });

    test('spaces and tabs at the end of a line are ignored', () {
      expect(outputMatches('Age? 12   \n13\t \n', ['Age? 12', '13']), isTrue);
      expect(outputMatches('Age? 12\n13', ['Age? 12  ', '13']), isTrue);
    });

    test('empty lines at the very end are ignored', () {
      expect(outputMatches('13\n\n\n', ['13']), isTrue);
      expect(outputMatches('13', ['13']), isTrue);
    });

    test('spaces at the start or in the middle still count', () {
      expect(outputMatches(' 13\n', ['13']), isFalse);
      expect(outputMatches('Age?  12\n', ['Age? 12']), isFalse);
    });

    test('an empty line in the middle still counts', () {
      expect(outputMatches('a\n\nb\n', ['a', 'b']), isFalse);
    });

    test('a different letter case or a missing line does not match', () {
      expect(outputMatches('cog\n', ['Cog']), isFalse);
      expect(outputMatches('Age? 12\n', ['Age? 12', '13']), isFalse);
      expect(outputMatches('', ['13']), isFalse);
    });

    test('Windows line endings are fine', () {
      expect(outputMatches('a\r\nb\r\n', ['a', 'b']), isTrue);
    });
  });

  group('Running the hidden tests', () {
    test('passes only when every test matches', () async {
      final engine = ScriptedEngine(agePlusOne);
      final result = await checkProgram(engine, 'code', ageTests);
      expect(result.passed, isTrue);
      expect(engine.runs, [
        ['12'],
        ['0'],
        ['99'],
      ]);
    });

    test('stops at the first failed test, so later tests never run', () async {
      // Always prints 13: right for the first test only.
      final engine = ScriptedEngine(
        (code, inputs) => printed('Age? ${inputs[0]}\n13\n'),
      );
      final result = await checkProgram(engine, 'code', ageTests);
      expect(result.passed, isFalse);
      expect(result.failedNumber, 2);
      expect(result.failedCase, same(ageTests[1]));
      expect(result.got!.stdout, 'Age? 0\n13\n');
      // The third test was never tried.
      expect(engine.runs, [
        ['12'],
        ['0'],
      ]);
    });

    test('an error fails the test even if the output matches', () async {
      final engine = ScriptedEngine(
        (code, inputs) => printed('Cog\n', error: 'NameError: oops'),
      );
      final result = await checkProgram(engine, 'code', const [
        TestCase(output: ['Cog']),
      ]);
      expect(result.passed, isFalse);
      expect(result.failedNumber, 1);
      expect(result.got!.error, 'NameError: oops');
    });

    test('running too long fails the test', () async {
      final engine = ScriptedEngine(
        (code, inputs) => printed('Cog\n', timedOut: true),
      );
      final result = await checkProgram(engine, 'code', const [
        TestCase(output: ['Cog']),
      ]);
      expect(result.passed, isFalse);
      expect(result.got!.timedOut, isTrue);
    });

    test('each test gets its own typed inputs', () async {
      final engine = ScriptedEngine((code, inputs) => printed(''));
      await checkProgram(engine, 'code', const [
        TestCase(inputs: ['Ana', '12'], output: ['x']),
      ]);
      expect(engine.runs.single, ['Ana', '12']);
    });
  });

  group('Showing an expected output', () {
    test('typed answers are moved out of their lines, in order', () {
      final (rows, typed) = splitExpected(
        ['Name? Ana', 'Age? 12', 'Hi Ana', '13'],
        ['Ana', '12'],
      );
      expect(rows, ['Name? ', 'Age? ', 'Hi Ana', '13']);
      expect(typed, {0: 'Ana', 1: '12'});
    });

    test('without inputs nothing changes', () {
      final (rows, typed) = splitExpected(['Cog'], const []);
      expect(rows, ['Cog']);
      expect(typed, isEmpty);
    });
  });

  group('Fill the blank', () {
    final challenge = Challenge.fillBlank(
      id: 'x',
      title: (_) => '',
      prompt: (_) => '',
      hints: [(_) => '', (_) => ''],
      template: 'name = "Cog"\nprint($blankMarker)',
      solution: 'name',
      tests: const [
        TestCase(output: ['Cog']),
      ],
    );

    test('the entered text goes where the blank is', () {
      expect(challenge.programFor('name'), 'name = "Cog"\nprint(name)');
      expect(challenge.solutionProgram, 'name = "Cog"\nprint(name)');
    });
  });

  group('Required code ("must use")', () {
    const required = ['speed = 5', 'print(speed)'];
    const tests = [
      TestCase(output: ['5']),
    ];
    ScriptedEngine fivePrinter() =>
        ScriptedEngine((code, inputs) => printed('5\n'));

    test(
      'a missing piece: the code is not run, and the piece is listed',
      () async {
        final engine = fivePrinter();
        final result = await checkProgram(
          engine,
          'print(5)',
          tests,
          required: required,
        );
        expect(result.passed, isFalse);
        expect(result.missing, ['speed = 5', 'print(speed)']);
        expect(result.failedNumber, isNull); // no test ran or failed
        expect(engine.runs, isEmpty);
      },
    );

    test('only the missing pieces are listed, in order', () async {
      final result = await checkProgram(
        fivePrinter(),
        'speed = 5\nprint(5)',
        tests,
        required: required,
      );
      expect(result.missing, ['print(speed)']);
    });

    test('extra spaces around = and inside brackets do not matter', () {
      for (final code in [
        'speed=5\nprint(speed)',
        'speed = 5\nprint(speed)',
        'speed   =   5\nprint( speed )',
        'speed\t=\t5\nprint(speed )',
      ]) {
        expect(missingCode(code, required), isEmpty, reason: code);
      }
      // A piece written with no spaces matches code with spaces too.
      expect(missingCode('speed = 5', ['speed=5']), isEmpty);
    });

    test('other spaces still count', () {
      expect(missingCode('spe ed = 5', ['speed =']), ['speed =']);
      expect(missingCode('print (speed)', ['print(speed)']), ['print(speed)']);
    });

    test('a piece inside a # comment does not count', () {
      expect(
        missingCode('# speed = 5 print(speed)\nprint(5)', required),
        required,
      );
      // But a # inside quotes is not a comment.
      expect(missingCode('name = "#1"\nprint(name)', ['print(name)']), isEmpty);
    });

    test('with all pieces there, the code runs and is checked', () async {
      final engine = fivePrinter();
      final result = await checkProgram(
        engine,
        'speed = 5\nprint(speed)',
        tests,
        required: required,
      );
      expect(result.passed, isTrue);
      expect(engine.runs, hasLength(1));
    });

    test('no required list: nothing changes', () async {
      final engine = fivePrinter();
      final result = await checkProgram(engine, 'print(5)', tests);
      expect(result.passed, isTrue);
      expect(result.missing, isEmpty);
      expect(engine.runs, hasLength(1));
    });

    test('only fix the bug and write it yourself can have a list', () {
      final write = Challenge.writeCode(
        id: 'w',
        title: (_) => '',
        prompt: (_) => '',
        hints: [(_) => '', (_) => ''],
        solution: 'speed = 5\nprint(speed)',
        tests: tests,
        requiredCode: required,
      );
      expect(write.requiredCode, required);
      final fill = Challenge.fillBlank(
        id: 'f',
        title: (_) => '',
        prompt: (_) => '',
        hints: [(_) => '', (_) => ''],
        template: 'print($blankMarker)',
        solution: '5',
        tests: tests,
      );
      expect(fill.requiredCode, isEmpty);
    });
  });
}
