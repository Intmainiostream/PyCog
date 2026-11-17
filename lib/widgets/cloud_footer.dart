import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Soft layered clouds at the very end of the lesson trail, with "More
/// lessons coming soon". The trail's path runs into the top of it.
///
/// Light on performance: one painter, no animation, no touch handling, and a
/// RepaintBoundary so scrolling the trail never repaints the clouds.
class CloudFooter extends StatelessWidget {
  const CloudFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Drawn a little higher than its slot, so the clouds cover the end of
    // the trail's path: the path disappears into them.
    return Transform.translate(
      offset: const Offset(0, -AppSizes.cloudOverlap),
      child: _clouds(l10n, context),
    );
  }

  Widget _clouds(AppLocalizations l10n, BuildContext context) {
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.cloudFooterMinHeight,
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _CloudPainter()),
              ),
            ),
            // The text sits on the front (white) cloud layer.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.gap24,
                112,
                AppSizes.gap24,
                AppSizes.gap24 * 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.star,
                    size: MediaQuery.textScalerOf(context).scale(30),
                  ),
                  const SizedBox(height: AppSizes.gap4),
                  Text(
                    l10n.cloudsMoreLessons,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gap4),
                  Text(
                    l10n.cloudsKeepPracticing,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three rows of overlapping puffs (back to front), each over a solid body
/// that runs to the bottom. Fixed shapes: it only repaints if its size
/// changes.
class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = math.min(w * 0.12, 60.0); // puff size scales with the width

    _layer(
      canvas,
      size,
      top: 0,
      radius: r * 0.9,
      shift: 0.0,
      fill: Paint()..color = AppColors.cloudBack,
    );
    _layer(
      canvas,
      size,
      top: 30,
      radius: r * 0.8,
      shift: 0.55,
      fill: Paint()..color = AppColors.cloudMiddle,
    );
    _layer(
      canvas,
      size,
      top: 58,
      radius: r,
      shift: 0.25,
      // White on top, fading into the page color at the very bottom.
      fill: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cloudFront, AppColors.background],
          stops: [0.55, 1.0],
        ).createShader(Offset.zero & size),
      edge: Paint()
        ..color = AppColors.cloudEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  /// One cloud layer. If [edge] is given, each puff is stroked first and
  /// then the fill is drawn over it, so only the outer half of the stroke
  /// shows: a soft outline around the whole layer, cheaply.
  void _layer(
    Canvas canvas,
    Size size, {
    required double top,
    required double radius,
    required double shift,
    required Paint fill,
    Paint? edge,
  }) {
    // The clouds spill past the sides (into the trail's side margins) so
    // they reach the screen edges instead of looking like a box. The
    // scrolling list clips them, so they never cover anything outside it.
    const bleed = 400.0;
    final step = radius * 1.35;
    final puffs = <Rect>[];
    for (
      var i = -(bleed / step).ceil() - 1;
      i * step < size.width + bleed;
      i++
    ) {
      // Fixed, slightly varied puff sizes (no randomness: same every paint).
      final vary = 0.85 + 0.3 * (((i % 7 + 7) * 5) % 7) / 6;
      final center = Offset(i * step + shift * step, top + radius);
      puffs.add(Rect.fromCircle(center: center, radius: radius * vary));
    }
    final body = Rect.fromLTRB(
      -bleed,
      top + radius,
      size.width + bleed,
      size.height,
    );

    if (edge != null) {
      for (final p in puffs) {
        canvas.drawOval(p, edge);
      }
    }
    final shape = Path()..addRect(body);
    for (final p in puffs) {
      shape.addOval(p);
    }
    canvas.drawPath(shape, fill);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}
