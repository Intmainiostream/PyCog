import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../playground/coding_examples.dart';
import '../playground/coding_output.dart';
import '../playground/python_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_feedback_card.dart';
import '../widgets/output_box.dart';
import '../widgets/settings_sheet.dart';

/// What the student typed in the playground. Kept while the app is open,
/// so leaving the screen and coming back keeps the code.
class CodingSession {
  CodingSession._();

  static String code = 'print("Hi, I am Cog!")';
  static String answers = '';

  /// Back to a fresh start (used by tests).
  static void reset() {
    code = 'print("Hi, I am Cog!")';
    answers = '';
  }
}

/// The CODING playground, like a small Programiz for phones: a code box,
/// helper buttons for hard-to-type symbols, Run and Clear, typed answers for
/// input(), starter examples, and the output in the lessons' output box.
/// Python runs fully offline with [runPython] (Pyodide in a hidden WebView).
class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key, required this.settings, this.engine});

  final SettingsController settings;

  /// Defaults to the real Python. Tests pass a fake.
  final PythonEngine? engine;

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  late final _code = TextEditingController(text: CodingSession.code);
  late final _answers = TextEditingController(text: CodingSession.answers);
  final _codeFocus = FocusNode();
  PythonResult? _result;
  bool _running = false;

  PythonEngine get _engine => widget.engine ?? PyodideEngine.instance;

  bool get _usesInput => _code.text.contains('input(');

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      CodingSession.code = _code.text;
      setState(() {}); // shows or hides the Typed answers box
    });
    _answers.addListener(() => CodingSession.answers = _answers.text);
    _codeFocus.addListener(() => setState(() {})); // helper buttons
  }

  @override
  void dispose() {
    _code.dispose();
    _answers.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// The typed answers, one per line (empty lines at the end are ignored).
  List<String> get _inputs {
    if (!_usesInput) return const [];
    final lines = _answers.text.split('\n');
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    return lines;
  }

  Future<void> _run() async {
    _codeFocus.unfocus();
    setState(() {
      _running = true;
      _result = null;
    });
    final result = await _engine.run(_code.text, inputs: _inputs);
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
    });
  }

  void _clear() {
    final l10n = AppLocalizations.of(context);
    final oldCode = _code.text;
    final oldAnswers = _answers.text;
    setState(() {
      _code.clear();
      _answers.clear();
      _result = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.codingCleared),
          action: SnackBarAction(
            label: l10n.codingUndo,
            onPressed: () => setState(() {
              _code.text = oldCode;
              _answers.text = oldAnswers;
            }),
          ),
        ),
      );
  }

  void _useExample(CodingExample example) {
    setState(() {
      _code.text = example.code;
      _answers.text = example.answers.join('\n');
      _result = null;
    });
  }

  /// Types [text] where the cursor is (replacing any selection), then puts
  /// the cursor [back] characters before the end of it (inside brackets).
  void _insert(String text, {int back = 0}) {
    final value = _code.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    _code.value = TextEditingValue(
      text: value.text.replaceRange(selection.start, selection.end, text),
      selection: TextSelection.collapsed(
        offset: selection.start + text.length - back,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              AppSizes.screenPadding,
              (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
            );
            return Column(
              children: [
                _TopBar(
                  padding: side,
                  title: l10n.codingTitle,
                  backLabel: l10n.lessonBack,
                  settingsLabel: l10n.settingsTooltip,
                  onSettings: () => showSettingsSheet(context, widget.settings),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      AppSizes.gap4,
                      side,
                      AppSizes.gap24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _content(l10n),
                    ),
                  ),
                ),
                // Hard-to-type symbols, right above the keyboard.
                if (_codeFocus.hasFocus)
                  _HelperBar(l10n: l10n, padding: side, onInsert: _insert),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n) {
    final mono = AppTextStyles.code;
    return [
      Text(l10n.codingIntro, style: AppTextStyles.small),
      const SizedBox(height: AppSizes.gap8),
      // On its own row, so it never squeezes the intro with big text.
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _ExamplesButton(label: l10n.codingExamples, onPick: _useExample),
      ),
      const SizedBox(height: AppSizes.gap8),
      // The code box: dark, like the lessons' code boxes.
      Container(
        decoration: AppDecorations.card(color: AppColors.codeBackground),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap12,
          vertical: AppSizes.gap8,
        ),
        child: Semantics(
          label: l10n.codingCodeLabel,
          child: TextField(
            key: const ValueKey('coding-code'),
            controller: _code,
            focusNode: _codeFocus,
            minLines: 8,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.none,
            cursorColor: AppColors.codeOperator,
            style: mono.copyWith(color: AppColors.codeText),
            decoration: InputDecoration.collapsed(
              hintText: l10n.codingCodeHint,
              hintStyle: mono.copyWith(color: AppColors.codeComment),
            ),
          ),
        ),
      ),
      if (_usesInput) ...[
        const SizedBox(height: AppSizes.gap12),
        TextField(
          key: const ValueKey('coding-answers'),
          controller: _answers,
          minLines: 2,
          maxLines: 5,
          autocorrect: false,
          enableSuggestions: false,
          style: mono.copyWith(color: AppColors.tealDark),
          decoration: InputDecoration(
            labelText: l10n.codingAnswersLabel,
            hintText: l10n.codingAnswersHint,
            prefixIcon: const Icon(Icons.keyboard_rounded),
            filled: true,
            fillColor: AppColors.mint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSizes.gap12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ChunkyButton(
              key: const ValueKey('coding-run'),
              color: AppColors.red,
              onTap: _running ? null : _run,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded),
                  const SizedBox(width: 4),
                  Flexible(child: Text(l10n.codingRun)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gap12),
          Expanded(
            child: ChunkyButton(
              key: const ValueKey('coding-clear'),
              color: AppColors.surface,
              onTap: _running ? null : _clear,
              child: Text(l10n.codingClear, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
      if (_running)
        ValueListenableBuilder<bool>(
          valueListenable: _engine.isReady,
          builder: (context, ready, _) => Padding(
            padding: const EdgeInsets.only(top: AppSizes.gap12),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: AppSizes.gap8),
                Expanded(
                  child: Text(
                    ready ? l10n.codingRunning : l10n.codingStarting,
                    key: const ValueKey('coding-status'),
                    style: AppTextStyles.bodyBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_result case final result?) ...[
        const SizedBox(height: AppSizes.gap12),
        ..._output(l10n, result),
      ],
      const SizedBox(height: AppSizes.gap24),
      Text(
        l10n.codingAbout,
        style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'PyCog'),
          child: Text(l10n.codingLicenses),
        ),
      ),
    ];
  }

  List<Widget> _output(AppLocalizations l10n, PythonResult result) {
    final (rows, typed) = splitOutput(result.stdout, result.typed);
    final error = result.error;
    return [
      if (rows.isNotEmpty)
        OutputBox(lines: rows, typed: typed)
      else if (error == null && !result.timedOut)
        Text(l10n.codingNothingPrinted, style: AppTextStyles.body),
      if (result.timedOut)
        CogFeedbackCard(text: l10n.codingTimeout, mood: CogMood.hint),
      if (error != null) ...[
        if (!isStartError(error))
          Container(
            key: const ValueKey('coding-error'),
            margin: const EdgeInsets.only(top: AppSizes.gap8),
            padding: const EdgeInsets.all(AppSizes.gap12),
            decoration: AppDecorations.card(color: AppColors.surface),
            child: SelectableText(
              error,
              style: AppTextStyles.code.copyWith(
                color: AppColors.redDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        CogFeedbackCard(text: friendlyTip(l10n, error), mood: CogMood.hint),
      ],
    ];
  }
}

/// Back arrow, title and gear, like the other screens.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.padding,
    required this.title,
    required this.backLabel,
    required this.settingsLabel,
    required this.onSettings,
  });

  final double padding;
  final String title;
  final String backLabel;
  final String settingsLabel;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppSizes.gap12,
        padding,
        AppSizes.gap8,
      ),
      child: Row(
        children: [
          ChunkyButton(
            circle: true,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            semanticLabel: backLabel,
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_rounded, size: 28),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
            ),
          ),
          ChunkyButton(
            circle: true,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            semanticLabel: settingsLabel,
            onTap: onSettings,
            child: const Icon(Icons.settings_rounded, size: 28),
          ),
        ],
      ),
    );
  }
}

/// "Examples": a small menu of starter programs from the lessons.
class _ExamplesButton extends StatelessWidget {
  const _ExamplesButton({required this.label, required this.onPick});

  final String label;
  final ValueChanged<CodingExample> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<CodingExample>(
      key: const ValueKey('coding-examples'),
      tooltip: label,
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final example in codingExamples)
          PopupMenuItem(value: example, child: Text(example.title(l10n))),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.gap12),
        decoration: AppDecorations.card(
          color: AppColors.mint,
          radius: AppSizes.radiusSmall,
          shadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.tealDark),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.tealDark,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.tealDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small buttons for symbols that are hard to type on a phone keyboard.
/// It counts as part of the code box (TextFieldTapRegion), so tapping a
/// button keeps the keyboard open.
class _HelperBar extends StatelessWidget {
  const _HelperBar({
    required this.l10n,
    required this.padding,
    required this.onInsert,
  });

  final AppLocalizations l10n;
  final double padding;
  final void Function(String text, {int back}) onInsert;

  @override
  Widget build(BuildContext context) {
    // (label on the button, text typed, characters to step back)
    const keys = [
      ('Tab', '    ', 0),
      (':', ':', 0),
      ('( )', '()', 1),
      ('[ ]', '[]', 1),
      ('" "', '""', 1),
      ('=', '=', 0),
      ('+', '+', 0),
      ('-', '-', 0),
      ('*', '*', 0),
      ('/', '/', 0),
      ('#', '#', 0),
    ];
    return TextFieldTapRegion(
      child: Container(
        key: const ValueKey('coding-helpers'),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.outline,
              width: AppSizes.outlineWidth,
            ),
          ),
        ),
        height: AppSizes.minTouchTarget + AppSizes.gap12,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: AppSizes.gap4,
          ),
          children: [
            for (final (label, text, back) in keys)
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.gap4),
                child: Semantics(
                  button: true,
                  label: label == 'Tab'
                      ? l10n.codingInsertTab
                      : l10n.codingInsert(label),
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.codeBackground,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: InkWell(
                      key: ValueKey('coding-key-$label'),
                      canRequestFocus: false,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      onTap: () => onInsert(text, back: back),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: AppSizes.minTouchTarget,
                          minHeight: AppSizes.minTouchTarget,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.gap8,
                            ),
                            child: Text(
                              label,
                              style: AppTextStyles.code.copyWith(
                                color: AppColors.codeText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
