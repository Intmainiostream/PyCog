import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'chunky_button.dart';

/// The code-font text style used on chips and in boxes. It sets no color,
/// so it picks up the button's own text color (white on teal, brown on cream).
TextStyle _codeStyle({double size = AppSizes.fontSubtitle}) => TextStyle(
  fontFamily: AppFonts.code,
  fontSize: size,
  fontWeight: FontWeight.w700,
  fontVariations: const [FontVariation.weight(700)],
  fontFeatures: AppTextStyles.codeFontFeatures, // no ≠ / ≥ ligatures
  decoration: TextDecoration.none,
);

/// A value chip (like `80` or `"Cog"`) the student drags into a box.
/// It can also be tapped to pick it, then a box tapped to place it.
///
/// [shakeCount] goes up by one each time the chip is dropped on the wrong
/// box; every change plays a little "bounce back" shake.
class GameValueChip extends StatelessWidget {
  const GameValueChip({
    super.key,
    required this.value,
    required this.selected,
    required this.shakeCount,
    required this.semanticLabel,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final int shakeCount;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = ChunkyButton(
      color: selected ? AppColors.teal : AppColors.surface,
      radius: AppSizes.radiusSmall,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.gap16,
        vertical: AppSizes.gap8,
      ),
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(child: Text(value, style: _codeStyle())),
    );

    // A chip is only as wide as its value (buttons otherwise stretch to fill
    // the row, which stacked the chips one per line and made the tray tall).
    final sized = IntrinsicWidth(child: chip);

    return Draggable<String>(
      data: value,
      // What follows the finger. Drawn above everything, so it sets its own
      // text style instead of inheriting one.
      feedback: _ChipFace(value: value),
      childWhenDragging: Opacity(opacity: 0.35, child: sized),
      child: _Shake(count: shakeCount, child: sized),
    );
  }
}

/// The chip as it looks while being dragged (slightly bigger and tilted).
class _ChipFace extends StatelessWidget {
  const _ChipFace({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Transform.scale(
        scale: 1.1,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget - AppSizes.shadowDepth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.gap16,
            vertical: AppSizes.gap8,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: AppDecorations.outline,
            boxShadow: AppDecorations.hardShadow(),
          ),
          child: Text(
            value,
            style: _codeStyle().copyWith(color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}

/// Shakes its child side to side each time [count] changes.
class _Shake extends StatelessWidget {
  const _Shake({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child; // never shaken yet: no animation on start
    return TweenAnimationBuilder<double>(
      key: ValueKey(count), // a new count restarts the shake
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// A labeled variable box that values can be dropped into (or tapped into).
///
/// Shows `?` when empty, the value in yellow-green with a ✓ once matched, and
/// for the "changing it" twist, the old value crossed out above the new one.
class GameBoxView extends StatelessWidget {
  const GameBoxView({
    super.key,
    required this.name,
    required this.startValue,
    required this.placedValue,
    required this.semanticLabel,
    required this.onTap,
    required this.onDrop,
  });

  final String name;
  final String? startValue;
  final String? placedValue;
  final String semanticLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final filled = placedValue != null;

    return DragTarget<String>(
      // Only empty (or not-yet-updated) boxes take drops.
      onWillAcceptWithDetails: (_) => !filled,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          button: !filled,
          label: semanticLabel,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: filled ? null : onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name tag
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
                  // Long names shrink to fit narrow boxes instead of wrapping.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      style: _codeStyle(size: AppSizes.fontBody)
                          .copyWith(color: AppColors.surface),
                    ),
                  ),
                ),
                Container(width: 3, height: 6, color: AppColors.outline),
                // The box itself
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.gameBoxMinHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.gap8,
                    vertical: AppSizes.gap8,
                  ),
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.success
                        : hovering
                        ? AppColors.mint
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    border: Border.all(
                      color: AppColors.outline,
                      width: hovering
                          ? AppSizes.outlineWidth + 2
                          : AppSizes.outlineWidth,
                    ),
                    boxShadow: AppDecorations.hardShadow(4),
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: AppColors.text),
                    child: _contents(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contents() {
    final value = placedValue;
    if (value != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (startValue != null)
            Text(
              startValue!,
              style: _codeStyle(size: AppSizes.fontBody).copyWith(
                color: AppColors.textMuted,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.red,
                decorationThickness: 3,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: _codeStyle()),
                ),
              ),
              const SizedBox(width: AppSizes.gap4),
              const Icon(Icons.check_circle_rounded, color: AppColors.outline),
            ],
          ),
        ],
      );
    }
    if (startValue != null) {
      // Twist box: shows its current (old) value, waiting for a new one.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(startValue!, style: _codeStyle()),
          const SizedBox(width: AppSizes.gap4),
          const Icon(Icons.sync_rounded, color: AppColors.tealDark),
        ],
      );
    }
    return Text(
      '?',
      textAlign: TextAlign.center,
      style: _codeStyle(size: AppSizes.fontTitle)
          .copyWith(color: AppColors.lockedDark),
    );
  }
}
