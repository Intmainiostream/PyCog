import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../sound/sounds.dart';

/// The basic "sticker" button: thick outline, hard shadow underneath, and it
/// sinks down onto its shadow while pressed.
///
/// Used for normal buttons, the gear button, option pickers and lesson nodes.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.red,
    this.circle = false,
    this.radius = AppSizes.radius,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.gap16,
      vertical: AppSizes.gap12,
    ),
    this.width,
    this.height,
    this.semanticLabel,
    this.disabledColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final bool circle;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  /// What screen readers say for this button (useful for icon-only buttons).
  final String? semanticLabel;

  /// Fill when [onTap] is null. Defaults to light brown ("locked"). Quiz
  /// answers use this to stay green/red after the question is answered.
  final Color? disabledColor;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    const depth = AppSizes.shadowDepth;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: Sounds.tapThen(widget.onTap),
        // The bottom padding reserves room for the shadow so the layout
        // doesn't jump when the button moves down.
        child: Padding(
          padding: const EdgeInsets.only(bottom: depth),
          child: AnimatedContainer(
            duration: AppSizes.pressDuration,
            width: widget.width,
            height: widget.height,
            // Never smaller than a finger: 48x48 including the shadow strip.
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouchTarget,
              minHeight: AppSizes.minTouchTarget - AppSizes.shadowDepth,
            ),
            padding: widget.padding,
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
            decoration: BoxDecoration(
              color: _fill,
              shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.circle
                  ? null
                  : BorderRadius.circular(widget.radius),
              border: AppDecorations.outline,
              boxShadow: AppDecorations.hardShadow(_pressed ? 0 : depth),
            ),
            child: DefaultTextStyle.merge(
              style: AppTextStyles.button.copyWith(color: _textColor),
              child: IconTheme.merge(
                data: IconThemeData(color: _textColor),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _enabled => widget.onTap != null;

  /// A disabled button (no onTap) turns light brown.
  Color get _fill =>
      _enabled ? widget.color : (widget.disabledColor ?? AppColors.locked);

  /// White text on dark/strong colors, brown text on light ones.
  Color get _textColor {
    if (!_enabled && widget.disabledColor == null) return AppColors.lockedDark;
    return ThemeData.estimateBrightnessForColor(_fill) == Brightness.dark
        ? AppColors.surface
        : AppColors.text;
  }
}
