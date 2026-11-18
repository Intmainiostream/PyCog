import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'python_checks.dart';
import 'python_runner.dart';

/// A tiny screen to try the offline Python runner: a code box, typed
/// answers for input(), a Run button and the output. "Run all checks" runs
/// the feasibility checks and shows each result and its time.
class PythonTestScreen extends StatefulWidget {
  const PythonTestScreen({super.key, this.engine});

  /// Defaults to the real Python (Pyodide). Tests pass a fake.
  final PythonEngine? engine;

  @override
  State<PythonTestScreen> createState() => _PythonTestScreenState();
}

class _PythonTestScreenState extends State<PythonTestScreen> {
  final _code = TextEditingController(text: 'print(2 + 3)');
  final _answers = TextEditingController();
  PythonResult? _result;
  bool _busy = false;
  final _checks = <(PythonCheck, PythonResult)>[];

  PythonEngine get _engine => widget.engine ?? PyodideEngine.instance;

  @override
  void dispose() {
    _code.dispose();
    _answers.dispose();
    super.dispose();
  }

  List<String> get _inputs =>
      _answers.text.split('\n').where((line) => line.isNotEmpty).toList();

  Future<void> _run() async {
    setState(() => _busy = true);
    final result = await _engine.run(_code.text, inputs: _inputs);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  Future<void> _runChecks() async {
    setState(() {
      _busy = true;
      _checks.clear();
    });
    for (final check in pythonChecks) {
      final result = await _engine.run(check.code, inputs: check.inputs);
      if (!mounted) return;
      setState(() => _checks.add((check, result)));
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final mono = AppTextStyles.code.copyWith(color: AppColors.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Python test (offline)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.gap16),
          children: [
            TextField(
              key: const ValueKey('py-code'),
              controller: _code,
              maxLines: 6,
              minLines: 3,
              style: mono,
              decoration: const InputDecoration(
                labelText: 'Python code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.gap8),
            TextField(
              key: const ValueKey('py-answers'),
              controller: _answers,
              maxLines: 3,
              minLines: 1,
              style: mono,
              decoration: const InputDecoration(
                labelText: 'Typed answers for input() (one per line)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.gap8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('py-run'),
                    onPressed: _busy ? null : _run,
                    child: const Text('Run'),
                  ),
                ),
                const SizedBox(width: AppSizes.gap8),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('py-checks'),
                    onPressed: _busy ? null : _runChecks,
                    child: const Text('Run all checks'),
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: AppSizes.gap8),
              const LinearProgressIndicator(),
            ],
            if (_result case final r?) ...[
              const SizedBox(height: AppSizes.gap16),
              _ResultView(result: r, mono: mono),
            ],
            if (_checks.isNotEmpty) ...[
              const SizedBox(height: AppSizes.gap16),
              Text(
                'Checks: ${_checks.where((c) => c.$1.passes(c.$2)).length}'
                ' of ${pythonChecks.length} passed so far',
                style: AppTextStyles.subtitle,
              ),
              for (final (check, result) in _checks)
                _CheckView(check: check, result: result, mono: mono),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.mono});

  final PythonResult result;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('py-output'),
      padding: const EdgeInsets.all(AppSizes.gap12),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Output', style: AppTextStyles.small),
          SelectableText(
            result.stdout.isEmpty ? '(nothing printed)' : result.stdout,
            style: mono,
          ),
          if (result.error case final e?)
            Text(e, style: mono.copyWith(color: AppColors.redDark)),
          if (result.timedOut)
            Text(
              'Stopped: the program ran longer than 3 seconds.',
              style: mono.copyWith(color: AppColors.redDark),
            ),
          const SizedBox(height: AppSizes.gap4),
          Text(
            'call ${result.elapsed.inMilliseconds} ms, '
            'program ${result.runTime.inMilliseconds} ms',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _CheckView extends StatelessWidget {
  const _CheckView({
    required this.check,
    required this.result,
    required this.mono,
  });

  final PythonCheck check;
  final PythonResult result;
  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    final ok = check.passes(result);
    final shown = result.timedOut
        ? 'timed out after ${result.runTime.inMilliseconds} ms'
        : [
            if (result.stdout.isNotEmpty) result.stdout.trimRight(),
            ?result.error,
          ].join('\n');
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.gap8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? AppColors.successDark : AppColors.redDark,
          ),
          const SizedBox(width: AppSizes.gap8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${check.name}  (${result.elapsed.inMilliseconds} ms)',
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(shown, style: mono),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
