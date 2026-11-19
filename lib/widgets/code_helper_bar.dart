import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Types [text] into [controller] where the cursor is (replacing any
/// selection), then puts the cursor [back] characters before the end of it
/// (inside brackets).
void insertCode(TextEditingController controller, String text, {int back = 0}) {
  final value = controller.value;
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  controller.value = TextEditingValue(
    text: value.text.replaceRange(selection.start, selection.end, text),
    selection: TextSelection.collapsed(
      offset: selection.start + text.length - back,
    ),
  );
}

/// Small buttons for symbols that are hard to type on a phone keyboard.
/// It counts as part of the code box (TextFieldTapRegion), so tapping a
/// button keeps the keyboard open. Used by the CODING playground and the
/// MINIGAME code challenges.
class CodeHelperBar extends StatelessWidget {
  const CodeHelperBar({
    super.key,
    required this.l10n,
    required this.padding,
    required this.onInsert,
    this.keyPrefix = 'coding',
  });

  final AppLocalizations l10n;
  final double padding;
  final void Function(String text, {int back}) onInsert;

  /// Start of the widget keys (`<prefix>-helpers`, `<prefix>-key-:`...).
  final String keyPrefix;

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
        key: ValueKey('$keyPrefix-helpers'),
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
                      key: ValueKey('$keyPrefix-key-$label'),
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
