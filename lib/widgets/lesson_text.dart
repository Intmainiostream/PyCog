import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Shows lesson text where words in `backticks` appear in the code font,
/// e.g. "Then write `=`." → "Then write" + `=` in code style.
class LessonText extends StatelessWidget {
  const LessonText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('`');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              // Odd pieces were between backticks.
              i.isOdd
                  ? TextSpan(
                      text: parts[i],
                      style: AppTextStyles.code.copyWith(
                        fontSize: style.fontSize,
                        color: AppColors.codeInline,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                        backgroundColor: AppColors.mint,
                      ),
                    )
                  : TextSpan(text: parts[i]),
        ],
      ),
      style: style,
      textAlign: textAlign,
    );
  }
}
