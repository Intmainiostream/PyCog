import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../sound/sounds.dart';

/// A chunky on/off switch in the sticker style.
/// Yellow-green when on, light brown when off.
class StickerSwitch extends StatelessWidget {
  const StickerSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  static const _width = 62.0;
  static const _height = 36.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onChanged(!value);
          Sounds.play(Sfx.tap);
        },
        // The pill is 36px tall, but the tappable area is at least 48x48.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Center(widthFactor: 1, child: _pill()),
        ),
      ),
    );
  }

  Widget _pill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.success : AppColors.locked,
        borderRadius: BorderRadius.circular(_height),
        border: AppDecorations.outline,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _height - 12,
          height: _height - 12,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outline,
              width: AppSizes.outlineWidth - 1,
            ),
          ),
        ),
      ),
    );
  }
}
