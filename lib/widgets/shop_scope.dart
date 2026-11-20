import 'package:material_ui/material_ui.dart';

import '../data/shop.dart';

/// Makes the Star Shop reachable from every screen (put around the whole
/// app in main.dart), so Cog can wear the name tag badge in use anywhere.
class ShopScope extends InheritedNotifier<ShopController> {
  const ShopScope({
    super.key,
    required ShopController shop,
    required super.child,
  }) : super(notifier: shop);

  /// The shop, or null when there is none (e.g. a screen shown alone in a
  /// test).
  static ShopController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShopScope>()?.notifier;
}

/// Cog with his name tag badge (from the Star Shop) as a small sticker on
/// his bottom-right corner. No badge in use: just [child].
class CogBadge extends StatelessWidget {
  const CogBadge({super.key, required this.cogWidth, required this.child});

  /// How wide Cog is drawn (the badge is about a third of it).
  final double cogWidth;
  final Widget child;

  /// Badge size compared to Cog's width.
  static const fraction = 0.36;

  @override
  Widget build(BuildContext context) {
    final image = ShopScope.maybeOf(context)?.tag?.image;
    if (image == null) return child;
    final size = cogWidth * fraction;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -size * 0.15,
          bottom: -size * 0.1,
          child: Image.asset(
            image,
            key: const ValueKey('cog-badge'),
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
