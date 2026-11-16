import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A simple stand-in drawing of Cog: red antenna, teal head, mint face screen.
///
/// When the real art is ready, replace the body of [build] with e.g.
///   Image.asset('assets/images/cog.png', width: size, height: size)
class CogPlaceholder extends StatelessWidget {
  const CogPlaceholder({super.key, required this.size});

  /// Cog's size for the current screen: a fraction of the screen's shorter
  /// side, kept between a min and max so it's never tiny or huge.
  static double sizeFor(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest * AppSizes.cogSizeFraction).clamp(
      AppSizes.cogSizeMin,
      AppSizes.cogSizeMax,
    );
  }

  /// A smaller Cog for the lesson screen, so the explanation gets the space.
  static double lessonSizeFor(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest * AppSizes.lessonCogFraction).clamp(
      AppSizes.lessonCogMin,
      AppSizes.lessonCogMax,
    );
  }

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 120; // all measurements below are for a 120px Cog
    final stroke = AppSizes.outlineWidth;

    BoxDecoration part(Color color, {double radius = 0, bool circle = false}) {
      return BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius * s),
        border: Border.all(color: AppColors.outline, width: stroke),
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Antenna stick + red bulb
            Positioned(
              top: 10 * s,
              child: Container(
                width: 6 * s,
                height: 22 * s,
                color: AppColors.outline,
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 20 * s,
                height: 20 * s,
                decoration: part(AppColors.red, circle: true),
              ),
            ),
            // Ears
            for (final left in [true, false])
              Positioned(
                top: 54 * s,
                left: left ? 2 * s : null,
                right: left ? null : 2 * s,
                child: Container(
                  width: 16 * s,
                  height: 30 * s,
                  decoration: part(AppColors.tealDark, radius: 6),
                ),
              ),
            // Head
            Positioned(
              top: 28 * s,
              child: Container(
                width: 96 * s,
                height: 84 * s,
                padding: EdgeInsets.all(10 * s),
                decoration: part(
                  AppColors.teal,
                  radius: 22,
                ).copyWith(boxShadow: AppDecorations.hardShadow(4)),
                // Face screen
                child: Container(
                  decoration: part(AppColors.mint, radius: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < 2; i++)
                            Container(
                              width: 11 * s,
                              height: 17 * s,
                              decoration: BoxDecoration(
                                color: AppColors.outline,
                                borderRadius: BorderRadius.circular(6 * s),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6 * s),
                      // Smile
                      Container(
                        width: 24 * s,
                        height: 10 * s,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.outline,
                              width: stroke,
                            ),
                            left: BorderSide(
                              color: AppColors.outline,
                              width: stroke,
                            ),
                            right: BorderSide(
                              color: AppColors.outline,
                              width: stroke,
                            ),
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12 * s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
