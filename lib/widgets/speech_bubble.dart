import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'lesson_text.dart';

/// An outlined speech bubble with a little tail pointing up at the speaker.
/// Words in `backticks` are shown in the code font.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.textAlign = TextAlign.center,
    this.style,
  });

  final String text;
  final TextAlign textAlign;

  /// Defaults to the subtitle style (Fredoka).
  final TextStyle? style;

  static const _tailWidth = 26.0;
  static const _tailHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The tail sits on top and overlaps the bubble's border by the outline
        // width, so the outline looks continuous.
        Transform.translate(
          offset: const Offset(0, AppSizes.outlineWidth),
          child: CustomPaint(
            size: const Size(_tailWidth, _tailHeight),
            painter: _TailPainter(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.gap16,
            vertical: AppSizes.gap12,
          ),
          decoration: AppDecorations.card(radius: AppSizes.radiusLarge),
          child: LessonText(
            text,
            textAlign: textAlign,
            style: style ?? AppTextStyles.subtitle,
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path..close(), Paint()..color = AppColors.surface);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height),
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.outlineWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => false;
}
