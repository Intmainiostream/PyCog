import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/settings_controller.dart';
import '../data/shop.dart';
import '../l10n/generated/app_localizations.dart';
import '../sound/sounds.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/title_top_bar.dart';

/// The Star Shop: spend Star Points on looks (app colors, code editor
/// colors, a name tag for Cog). Each item is bought once and saved; then it
/// can be put in use. Nothing here changes stars, records, unlocks, hints
/// or answers.
///
/// Light on the phone: one ListView, and only this screen listens to the
/// shop (buying or equipping redraws the list, nothing else).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.settings});

  final SettingsController settings;

  ShopController get _shop => settings.shop;

  Future<void> _tapItem(BuildContext context, ShopItem item) async {
    final l10n = AppLocalizations.of(context);
    if (_shop.owns(item)) {
      _shop.equip(item);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    final missing = _shop.missingFor(item);
    if (missing > 0) {
      say(l10n.shopNeedMore(missing));
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('shop-confirm'),
        backgroundColor: AppColors.background,
        title: Text(
          l10n.shopConfirmTitle(item.name(l10n)),
          style: AppTextStyles.title,
        ),
        content: Text(
          l10n.shopConfirmBody(item.price, _shop.points),
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            key: const ValueKey('shop-cancel'),
            onPressed: Sounds.tapThen(() => Navigator.of(context).pop(false)),
            child: Text(l10n.shopCancel),
          ),
          TextButton(
            key: const ValueKey('shop-yes'),
            onPressed: Sounds.tapThen(() => Navigator.of(context).pop(true)),
            child: Text(l10n.shopBuy),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (_shop.buy(item) == BuyResult.bought) {
      _shop.equip(item); // a new look is put in use right away
      Sounds.play(Sfx.finish);
      say(l10n.shopBought(item.name(l10n)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              AppSizes.screenPadding,
              (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
            );
            return Column(
              children: [
                TitleTopBar(
                  padding: side,
                  title: l10n.shopTitle,
                  backLabel: l10n.homeBackToHome,
                  settingsLabel: l10n.settingsTooltip,
                  onSettings: () => showSettingsSheet(context, settings),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _shop,
                    builder: (context, _) => ListView(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        AppSizes.gap8,
                        side,
                        AppSizes.gap24,
                      ),
                      children: [
                        Center(child: PointsChip(points: _shop.points)),
                        const SizedBox(height: AppSizes.gap8),
                        Text(
                          l10n.shopIntro,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.small,
                        ),
                        for (final (group, title, note) in [
                          (
                            ShopGroup.theme,
                            l10n.shopGroupTheme,
                            l10n.shopGroupThemeNote,
                          ),
                          (
                            ShopGroup.editor,
                            l10n.shopGroupEditor,
                            l10n.shopGroupEditorNote,
                          ),
                          (
                            ShopGroup.tag,
                            l10n.shopGroupTag,
                            l10n.shopGroupTagNote,
                          ),
                        ]) ...[
                          const SizedBox(height: AppSizes.gap24),
                          Semantics(
                            header: true,
                            child: Text(title, style: AppTextStyles.title),
                          ),
                          Text(note, style: AppTextStyles.small),
                          const SizedBox(height: AppSizes.gap8),
                          for (final item in shopItemsIn(group))
                            _ItemCard(
                              key: ValueKey('shop-${item.id}'),
                              item: item,
                              owned: _shop.owns(item),
                              inUse: _shop.isEquipped(item),
                              onTap: () => _tapItem(context, item),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The Star Points balance: the app's star icon and the number (no emoji).
class PointsChip extends StatelessWidget {
  const PointsChip({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.shopPoints(points),
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('shop-points'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gap12,
          vertical: AppSizes.gap4,
        ),
        decoration: AppDecorations.card(
          color: AppColors.surface,
          radius: AppSizes.radiusSmall,
          shadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.star, size: 26),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.shopPoints(points),
                style: AppTextStyles.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One item: a small preview, its name, and Buy / Use / In use.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.owned,
    required this.inUse,
    required this.onTap,
  });

  final ShopItem item;
  final bool owned;
  final bool inUse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The button says "In use"; the line under the name says what it is.
    final status = owned
        ? (item.free ? l10n.shopFree : l10n.shopOwned)
        : l10n.shopPrice(item.price);
    final action = inUse
        ? l10n.shopEquipped
        : (owned ? l10n.shopEquip : l10n.shopBuy);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.gap8),
      padding: const EdgeInsets.all(AppSizes.gap8),
      decoration: AppDecorations.card(
        color: inUse ? AppColors.mint : AppColors.surface,
        shadow: false,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Preview(item: item),
          const SizedBox(width: AppSizes.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name(l10n), style: AppTextStyles.subtitle),
                Row(
                  children: [
                    if (!owned) ...[
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.star,
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Flexible(child: Text(status, style: AppTextStyles.small)),
                  ],
                ),
                const SizedBox(height: AppSizes.gap4),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  // Only as wide as its word (buttons fill the row
                  // otherwise).
                  child: IntrinsicWidth(
                    child: ChunkyButton(
                      key: ValueKey('shop-action-${item.id}'),
                      color: inUse
                          ? AppColors.surface
                          : (owned ? AppColors.teal : AppColors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.gap16,
                        vertical: AppSizes.gap8,
                      ),
                      onTap: inUse ? null : onTap,
                      child: Text(action, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small picture of the item: a color swatch, a bit of code, or the tag.
class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final theme = item.theme;
    final editor = item.editor;
    if (theme != null) {
      return Container(
        width: size,
        height: size,
        decoration: AppDecorations.card(
          color: theme.background,
          radius: AppSizes.radiusSmall,
          shadow: false,
        ),
        child: const Icon(Icons.palette_rounded, color: AppColors.teal),
      );
    }
    if (editor != null) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: AppDecorations.card(
          color: editor.background,
          radius: AppSizes.radiusSmall,
          shadow: false,
        ),
        padding: const EdgeInsets.all(4),
        // A tiny code sample; it shrinks instead of wrapping with big text.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'x=1',
            style: AppTextStyles.code.copyWith(
              color: editor.text,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.card(
        color: AppColors.background,
        radius: AppSizes.radiusSmall,
        shadow: false,
      ),
      child: const Icon(Icons.badge_rounded, color: AppColors.teal),
    );
  }
}
