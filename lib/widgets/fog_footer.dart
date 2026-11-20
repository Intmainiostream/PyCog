import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Soft, slowly drifting fog at the very end of the lesson trail, with
/// "More lessons coming soon" under it. The trail's path runs into the top
/// of the fog and disappears.
///
/// Light on the phone:
///  * one slow animation for the whole fog, drawn by one painter that
///    repaints by itself (no widget rebuilds, so the lesson list above is
///    never rebuilt by the fog);
///  * a RepaintBoundary, so the fog repaints alone and scrolling the trail
///    never repaints it;
///  * no blur filters: only see-through gradients;
///  * it stands still when the phone's "reduce motion" is on, and Flutter
///    pauses it when another screen covers the trail;
///  * it ignores touches, so taps and scrolling go to the trail.
class FogFooter extends StatefulWidget {
  const FogFooter({super.key});

  /// One full drift of the fog (slow on purpose).
  static const cycle = Duration(seconds: 18);

  /// Tests turn the drifting off by default (an endless animation never
  /// "settles"); the fog tests turn it back on.
  @visibleForTesting
  static bool drift = true;

  @override
  State<FogFooter> createState() => _FogFooterState();
}

class _FogFooterState extends State<FogFooter>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: FogFooter.cycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context) || !FogFooter.drift;
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Drawn a little higher than its slot, so the fog covers the end of the
    // trail's path: the path disappears into it.
    return Transform.translate(
      offset: const Offset(0, -AppSizes.fogOverlap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.fogMinHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey('fog-paint'),
                    painter: FogPainter(
                      _controller,
                      // The fog fades into the page color (Star Shop theme).
                      page: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
            // The text sits low in the fog, where it is thickest.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.gap24,
                AppSizes.fogTextTop,
                AppSizes.gap24,
                AppSizes.gap24 * 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.cloudsMoreLessons,
                    key: const ValueKey('fog-text'),
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

/// Paints the fog: a soft band that thickens downwards, with a few big,
/// see-through patches that drift left and right and fade in and out a
/// little, all driven by one animation value (0 to 1, looping).
class FogPainter extends CustomPainter {
  FogPainter(this.time, {this.page = AppColors.background})
    : super(repaint: time);

  final Animation<double> time;

  /// The page color the fog fades into at the bottom.
  final Color page;

  // Each patch: where it sits (fractions of the size), how big it is, how
  // far it drifts, and its own timing offset.
  static const _patches = [
    (x: 0.15, y: 0.18, w: 0.75, h: 0.30, drift: 0.10, phase: 0.0),
    (x: 0.80, y: 0.22, w: 0.70, h: 0.28, drift: 0.12, phase: 0.33),
    (x: 0.45, y: 0.38, w: 0.90, h: 0.32, drift: 0.08, phase: 0.66),
    (x: 0.05, y: 0.55, w: 0.80, h: 0.30, drift: 0.11, phase: 0.5),
    (x: 0.95, y: 0.58, w: 0.75, h: 0.30, drift: 0.09, phase: 0.15),
    (x: 0.50, y: 0.75, w: 1.00, h: 0.34, drift: 0.06, phase: 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time.value * 2 * math.pi;

    // The fog spills past the sides into the trail's margins, so it reaches
    // the screen edges; the scrolling list clips it.
    const bleed = 200.0;
    final all = Rect.fromLTRB(-bleed, 0, w + bleed, h);

    // 1. The base band: clear at the top (the path runs into it), soft fog
    //    in the middle, the page colour at the very bottom.
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.fog.withValues(alpha: 0),
            AppColors.fog.withValues(alpha: 0.7),
            AppColors.fog.withValues(alpha: 0.9),
            page,
          ],
          stops: const [0.0, 0.3, 0.72, 1.0],
        ).createShader(all),
    );

    // 2. Drifting patches: see-through ovals that fade to nothing at their
    //    edges (a radial gradient, much cheaper than a blur).
    for (final (i, p) in _patches.indexed) {
      final color = i.isOdd ? AppColors.fogMint : AppColors.fogLight;
      final phase = t + p.phase * 2 * math.pi;
      final cx = (p.x + math.sin(phase) * p.drift) * w;
      final cy = p.y * h + math.cos(phase * 0.5) * 6;
      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: p.w * w * 1.4,
        height: p.h * h * 1.6,
      );
      // Fades in and out a little.
      final alpha = 0.6 + 0.3 * (0.5 + 0.5 * math.sin(phase * 1.3));
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(FogPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.page != page;
}
