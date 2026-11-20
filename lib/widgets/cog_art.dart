import 'package:material_ui/material_ui.dart';

import 'cog_placeholder.dart';
import 'shop_scope.dart';

/// Which Cog picture to show.
enum CogPose {
  /// Waving hello: greetings and places where Cog talks.
  waving,

  /// Both hands up: celebrations (a finished challenge, results, the end).
  cheering,
}

/// The real Cog art (assets/branding/). Both pictures show Cog from the
/// waist up, so they are wider than tall.
///
/// [size] is the same number the old square [CogPlaceholder] used; the
/// picture is a bit wider than that and shorter, so it never needs more
/// height than the old Cog did.
class CogArt extends StatelessWidget {
  const CogArt({super.key, required this.pose, required this.size});

  final CogPose pose;
  final double size;

  static const wavingAsset = 'assets/branding/cog_wave.png';
  static const cheeringAsset = 'assets/branding/cog_cheer.png';

  /// Width / height of each picture file (473 x 331 and 418 x 256).
  static const wavingAspect = 473 / 331;
  static const cheeringAspect = 418 / 256;

  /// How much wider than the old square Cog the picture is drawn.
  static const widthFactor = 1.2;

  String get asset => switch (pose) {
    CogPose.waving => wavingAsset,
    CogPose.cheering => cheeringAsset,
  };

  double get aspect => switch (pose) {
    CogPose.waving => wavingAspect,
    CogPose.cheering => cheeringAspect,
  };

  double get width => size * widthFactor;
  double get height => width / aspect;

  @override
  Widget build(BuildContext context) {
    // A fixed box, so the screen doesn't jump while the picture loads.
    return ExcludeSemantics(
      // Cog wears his name tag badge from the Star Shop, if one is in use.
      child: CogBadge(
        cogWidth: width,
        child: SizedBox(
          width: width,
          height: height,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            // If the picture can't load, the drawn Cog shows instead.
            errorBuilder: (_, _, _) =>
                Center(child: CogPlaceholder(size: height)),
          ),
        ),
      ),
    );
  }
}
