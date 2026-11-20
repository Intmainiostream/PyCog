import 'package:material_ui/material_ui.dart';

import '../data/shop.dart';
import 'theme_backdrop.dart';

/// Gives [child] the app color theme in use (Star Shop) as its page
/// background, with the theme's backdrop picture (sun, leaves, waves,
/// sprinkles) behind it. Only this small wrapper listens to the shop.
///
/// Light on the phone: the backdrop is painted once inside a
/// RepaintBoundary and never animates; the page in front ([child]) is
/// built once and reused, so the backdrop never makes it rebuild.
class ShopThemed extends StatelessWidget {
  const ShopThemed({super.key, required this.shop, required this.child});

  final ShopController shop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: shop,
      child: child,
      builder: (context, child) {
        final theme = Theme.of(context);
        final look = shop.theme;
        if (look.decor == ThemeDecor.none) {
          return Theme(
            data: theme.copyWith(scaffoldBackgroundColor: look.background),
            child: child!,
          );
        }
        // The page is see-through, so the backdrop behind it shows.
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('theme-backdrop'),
                painter: ThemeBackdropPainter(look),
              ),
            ),
            Theme(
              // See-through, but in the theme's own color: the trail's
              // fog fades into it without a grey band.
              data: theme.copyWith(
                scaffoldBackgroundColor: look.background.withValues(alpha: 0),
              ),
              child: child!,
            ),
          ],
        );
      },
    );
  }
}
