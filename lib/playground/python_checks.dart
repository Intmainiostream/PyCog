import 'python_runner.dart';

/// One feasibility check: a program, its typed answers, and what a correct
/// result looks like.
class PythonCheck {
  const PythonCheck({
    required this.name,
    required this.code,
    required this.passes,
    required this.expected,
    this.inputs = const [],
    this.sandbox = false,
  });

  final String name;
  final String code;
  final List<String> inputs;

  /// A short description of the right result (shown on screen).
  final String expected;

  final bool Function(PythonResult result) passes;

  /// True for the "files and network are turned off" checks.
  final bool sandbox;
}

/// The six checks asked for, plus sandbox checks. Used by the test screen
/// and by integration_test/python_runner_test.dart.
final List<PythonCheck> pythonChecks = [
  PythonCheck(
    name: 'print(2 + 3)',
    code: 'print(2 + 3)',
    expected: 'prints 5',
    passes: (r) => r.ok && r.stdout == '5\n',
  ),
  PythonCheck(
    name: 'for loop with range',
    code: 'for i in range(3):\n    print("Step", i)',
    expected: 'Step 0, Step 1, Step 2',
    passes: (r) => r.ok && r.stdout == 'Step 0\nStep 1\nStep 2\n',
  ),
  PythonCheck(
    name: 'function with return',
    code: 'def add(a, b):\n    return a + b\n\nprint(add(2, 3))',
    expected: 'prints 5',
    passes: (r) => r.ok && r.stdout == '5\n',
  ),
  PythonCheck(
    name: 'input() with 12 typed',
    code: 'age = int(input("Age? "))\nprint(age + 1)',
    inputs: ['12'],
    expected: 'Age? 12, then 13',
    passes: (r) => r.ok && r.stdout == 'Age? 12\n13\n',
  ),
  PythonCheck(
    name: 'int("abc") error',
    code: 'print(int("abc"))',
    expected: "ValueError: invalid literal for int() with base 10: 'abc'",
    passes: (r) =>
        !r.timedOut &&
        r.error == "ValueError: invalid literal for int() with base 10: 'abc'",
  ),
  PythonCheck(
    name: 'while True stops',
    code: 'n = 0\nwhile True:\n    n = n + 1',
    expected: 'stopped after about 3 seconds',
    passes: (r) =>
        r.timedOut &&
        r.runTime >= const Duration(milliseconds: 2900) &&
        r.runTime < const Duration(seconds: 5),
  ),
  // Sandbox: files and the network are turned off; normal modules work.
  PythonCheck(
    name: 'writing a file is blocked',
    code: 'open("notes.txt", "w").write("hi")',
    expected: 'PermissionError: Files are turned off in PyCog',
    sandbox: true,
    passes: (r) => r.error == 'PermissionError: Files are turned off in PyCog',
  ),
  PythonCheck(
    name: 'import os is blocked',
    code: 'import os\nprint(os.listdir("/"))',
    expected: "ImportError: The module 'os' is turned off in PyCog",
    sandbox: true,
    passes: (r) =>
        r.error == "ImportError: The module 'os' is turned off in PyCog",
  ),
  PythonCheck(
    name: 'network (js.fetch) is blocked',
    code: 'import js\njs.fetch("https://example.com")',
    expected: "ImportError: The module 'js' is turned off in PyCog",
    sandbox: true,
    passes: (r) =>
        r.error == "ImportError: The module 'js' is turned off in PyCog",
  ),
  PythonCheck(
    name: 'a file through a back door is blocked',
    code:
        'import random\n'
        'real_open = random.__builtins__["open"]\n'
        'real_open("/home/pyodide/secret.txt", "w")',
    expected: 'PermissionError (stopped by the audit hook)',
    sandbox: true,
    passes: (r) => r.error?.startsWith('PermissionError') ?? false,
  ),
  PythonCheck(
    name: 'normal modules still work',
    code: 'import math, random\nprint(math.sqrt(16), random.randint(7, 7))',
    expected: 'prints 4.0 7',
    sandbox: true,
    passes: (r) => r.ok && r.stdout == '4.0 7\n',
  ),
];
