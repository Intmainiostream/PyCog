import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/lesson_card.dart';
import '../theme/app_theme.dart';

/// A dark, outlined box that shows Python code in the code font, with simple
/// colors for strings, numbers, True/False and `=`.
///
/// Code never wraps (a wrapped line of code is confusing). Instead its text
/// growth is capped, and if a line is still too wide, the box scrolls sideways.
class CodeBox extends StatelessWidget {
  const CodeBox({super.key, required this.lines});

  final List<CodeLine> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasMarks = lines.any((l) => l.mark != CodeMark.none);
    final media = MediaQuery.of(context);
    final codeScaler = media.textScaler.clamp(
      maxScaleFactor: AppSizes.maxCodeTextScale,
    );

    return Semantics(
      label: l10n.codeExampleLabel,
      container: true,
      child: MediaQuery(
        data: media.copyWith(textScaler: codeScaler),
        child: Container(
          width: double.infinity,
          decoration: AppDecorations.card(color: AppColors.codeBackground),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSizes.gap16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasMarks) ...[
                          _MarkBadge(mark: line.mark, l10n: l10n),
                          const SizedBox(width: AppSizes.gap8),
                        ],
                        Text.rich(
                          TextSpan(children: highlightPython(line.code)),
                          softWrap: false,
                          style: AppTextStyles.code.copyWith(
                            color: AppColors.codeText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green ✓ / red ✗ in front of good and bad example lines.
class _MarkBadge extends StatelessWidget {
  const _MarkBadge({required this.mark, required this.l10n});

  final CodeMark mark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(22);
    if (mark == CodeMark.none) return SizedBox(width: size, height: size);

    final good = mark == CodeMark.good;
    return Semantics(
      label: good ? l10n.codeGoodLabel : l10n.codeBadLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: good ? AppColors.success : AppColors.red,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.codeText, width: 2),
        ),
        child: Icon(
          good ? Icons.check_rounded : Icons.close_rounded,
          size: size * 0.7,
          color: good ? AppColors.outline : AppColors.surface,
        ),
      ),
    );
  }
}

/// Splits one line of Python into colored pieces. Deliberately tiny: it only
/// knows what the early lessons use.
List<TextSpan> highlightPython(String code) {
  final token = RegExp(r'"[^"]*"|\b\d+\b|\b(?:True|False|None)\b|=');
  final spans = <TextSpan>[];
  var last = 0;
  for (final match in token.allMatches(code)) {
    if (match.start > last) {
      spans.add(TextSpan(text: code.substring(last, match.start)));
    }
    final text = match[0]!;
    final color = switch (text) {
      _ when text.startsWith('"') => AppColors.codeString,
      '=' => AppColors.codeOperator,
      'True' || 'False' || 'None' => AppColors.codeKeyword,
      _ => AppColors.codeNumber,
    };
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(color: color),
      ),
    );
    last = match.end;
  }
  if (last < code.length) spans.add(TextSpan(text: code.substring(last)));
  return spans;
}
