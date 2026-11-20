import 'package:material_ui/material_ui.dart';

import '../data/shop.dart';

/// Gives [child] the app color theme in use (Star Shop) as its page
/// background. Only this small wrapper listens to the shop, and the theme
/// only changes when the student picks another one.
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
        return Theme(
          data: theme.copyWith(scaffoldBackgroundColor: shop.theme.background),
          child: child!,
        );
      },
    );
  }
}
