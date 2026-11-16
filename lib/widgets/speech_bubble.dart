import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'lesson_text.dart';

/// Which side of the bubble the tail points out of (towards the speaker).
enum TailSide { up, left }

/// An outlined speech bubble with a little tail pointing at the speaker.
/// Words in `backticks` are shown in the code font.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.textAlign = TextAlign.center,
    this.style,
    this.tail = TailSide.up,
  });

  final String text;
  final TextAlign textAlign;

  /// Defaults to the subtitle style (Fredoka).
  final TextStyle? style;

  /// [TailSide.up] when the speaker is above, [TailSide.left] when beside.
  final TailSide tail;

  static const _tailWidth = 26.0; // along the bubble's edge
  static const _tailHeight = 16.0; // how far it sticks out

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: tail == TailSide.up ? double.infinity : null,
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
    );

    // The tail overlaps the bubble's border by the outline width, so the
    // outline looks continuous.
    switch (tail) {
      case TailSide.up:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, AppSizes.outlineWidth),
              child: CustomPaint(
                size: const Size(_tailWidth, _tailHeight),
                painter: _TailPainter(TailSide.up),
              ),
            ),
            body,
          ],
        );
      case TailSide.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.gap16),
              child: Transform.translate(
                offset: const Offset(AppSizes.outlineWidth, 0),
                child: CustomPaint(
                  size: const Size(_tailHeight, _tailWidth),
                  painter: _TailPainter(TailSide.left),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        );
    }
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.side);

  final TailSide side;

  @override
  void paint(Canvas canvas, Size size) {
    // Three points: the two that touch the bubble, and the tip between them.
    final (a, tip, b) = switch (side) {
      TailSide.up => (
        Offset(0, size.height),
        Offset(size.width / 2, 0),
        Offset(size.width, size.height),
      ),
      TailSide.left => (
        Offset(size.width, 0),
        Offset(0, size.height / 2),
        Offset(size.width, size.height),
      ),
    };
    Path outline() => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(b.dx, b.dy);

    canvas.drawPath(outline()..close(), Paint()..color = AppColors.surface);
    canvas.drawPath(
      outline(),
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.outlineWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.side != side;
}
