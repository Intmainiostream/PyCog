import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// The Star Points coin: a yellow circle with the peso sign, in the app's
/// sticker style (dark brown outline). Stars stay for lesson and challenge
/// stars only, so the two never look alike.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 24});

  final double size;

  /// The peso sign (Nunito has it; Fredoka does not).
  static const sign = '₱';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.star,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.outline,
            width: math.max(1.5, size * 0.08),
          ),
        ),
        child: Text(
          sign,
          // Always fits the circle, whatever the text size setting.
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w900,
            fontVariations: const [FontVariation.weight(900)],
            fontSize: size * 0.62,
            height: 1,
            color: AppColors.outline,
          ),
        ),
      ),
    );
  }
}
