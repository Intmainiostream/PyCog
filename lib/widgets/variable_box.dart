import 'package:material_ui/material_ui.dart';

import '../models/lesson_card.dart';
import '../theme/app_theme.dart';

/// A variable drawn as a box with a label: the name on a teal tag, the value
/// inside. If the value changed, the old value is shown crossed out.
class VariableBox extends StatelessWidget {
  const VariableBox({super.key, required this.data});

  final VariableBoxData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: data.oldValue == null
          ? '${data.name}: ${data.value}'
          : '${data.name}: ${data.oldValue} → ${data.value}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The label tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.gap8,
              vertical: 2,
            ),
            decoration: AppDecorations.card(
              color: AppColors.teal,
              radius: AppSizes.radiusSmall,
              shadow: false,
            ),
            child: Text(
              data.name,
              style: AppTextStyles.code.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation.weight(700)],
              ),
            ),
          ),
          // A short "string" joining tag and box
          Container(width: 3, height: 8, color: AppColors.outline),
          // The box
          Container(
            constraints: const BoxConstraints(
              minWidth: AppSizes.variableBoxMinWidth,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.gap16,
              vertical: AppSizes.gap12,
            ),
            decoration: AppDecorations.card(color: AppColors.mint),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.oldValue != null)
                  Text(
                    data.oldValue!,
                    style: AppTextStyles.code.copyWith(
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.red,
                      decorationThickness: 3,
                    ),
                  ),
                Text(
                  data.value,
                  style: AppTextStyles.code.copyWith(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation.weight(700)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
