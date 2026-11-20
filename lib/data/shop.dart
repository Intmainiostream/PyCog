import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// The three kinds of things in the Star Shop.
enum ShopGroup { theme, editor, tag }

/// Colors for the home screen and the Play trail background.
/// The extra picture a theme paints behind the home screen and the Play
/// trail (see ThemeBackdropPainter).
enum ThemeDecor { none, sunset, mint, ocean, candy }

class ThemeLook {
  const ThemeLook(this.background, {this.decor = ThemeDecor.none});

  final Color background;
  final ThemeDecor decor;
}

/// Colors of the CODING editor box.
class EditorLook {
  const EditorLook({
    required this.background,
    required this.text,
    required this.cursor,
    required this.hint,
  });

  final Color background;
  final Color text;
  final Color cursor;
  final Color hint;
}

/// One thing to buy. Price 0 = free and owned from the start (the default
/// of its group). Everything is only for looks: nothing here can change
/// stars, records, unlocks, hints or answers.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.group,
    required this.price,
    required this.name,
    this.theme,
    this.editor,
  });

  final String id;
  final ShopGroup group;
  final int price;
  final String Function(AppLocalizations) name;
  final ThemeLook? theme;
  final EditorLook? editor;

  bool get free => price == 0;

  /// Its picture in assets/shop/ (app colors and name tags; the code
  /// editor looks have none yet and show a small code sample instead).
  String? get image => group == ShopGroup.editor
      ? null
      : 'assets/shop/${id.replaceAll('.', '_')}.png';
}

/// Everything in the shop. The first item of each group is its free default.
final List<ShopItem> shopItems = [
  // App color themes (home screen and Play trail background). All light,
  // so the dark text keeps strong contrast.
  ShopItem(
    id: 'theme.classic',
    group: ShopGroup.theme,
    price: 0,
    name: (l) => l.shopThemeClassic,
    theme: const ThemeLook(AppColors.background),
  ),
  ShopItem(
    id: 'theme.sunset',
    group: ShopGroup.theme,
    price: 10,
    name: (l) => l.shopThemeSunset,
    theme: const ThemeLook(Color(0xFFFFEDE0), decor: ThemeDecor.sunset),
  ),
  ShopItem(
    id: 'theme.mint',
    group: ShopGroup.theme,
    price: 15,
    name: (l) => l.shopThemeMint,
    theme: const ThemeLook(Color(0xFFE6F8EF), decor: ThemeDecor.mint),
  ),
  ShopItem(
    id: 'theme.ocean',
    group: ShopGroup.theme,
    price: 20,
    name: (l) => l.shopThemeOcean,
    theme: const ThemeLook(Color(0xFFE4F3FF), decor: ThemeDecor.ocean),
  ),
  ShopItem(
    id: 'theme.candy',
    group: ShopGroup.theme,
    price: 30,
    name: (l) => l.shopThemeCandy,
    theme: const ThemeLook(Color(0xFFFFF0F6), decor: ThemeDecor.candy),
  ),
  // CODING editor looks.
  ShopItem(
    id: 'editor.classic',
    group: ShopGroup.editor,
    price: 0,
    name: (l) => l.shopEditorClassic,
    editor: const EditorLook(
      background: AppColors.codeBackground,
      text: AppColors.codeText,
      cursor: AppColors.codeOperator,
      hint: AppColors.codeComment,
    ),
  ),
  ShopItem(
    id: 'editor.midnight',
    group: ShopGroup.editor,
    price: 10,
    name: (l) => l.shopEditorMidnight,
    editor: const EditorLook(
      background: Color(0xFF14213D),
      text: Color(0xFFE8F1FF),
      cursor: Color(0xFF7FD1FF),
      hint: Color(0xFF94A6C4),
    ),
  ),
  ShopItem(
    id: 'editor.retro',
    group: ShopGroup.editor,
    price: 20,
    name: (l) => l.shopEditorRetro,
    editor: const EditorLook(
      background: Color(0xFF0B1A0B),
      text: Color(0xFF6CFF6C),
      cursor: Color(0xFF6CFF6C),
      hint: Color(0xFF46B04F),
    ),
  ),
  ShopItem(
    id: 'editor.paper',
    group: ShopGroup.editor,
    price: 25,
    name: (l) => l.shopEditorPaper,
    editor: const EditorLook(
      background: Color(0xFFFFFBF1),
      text: Color(0xFF3B2416),
      cursor: Color(0xFF1B7A71),
      hint: Color(0xFF7D6352),
    ),
  ),
  // Cog name tags (a short title under Cog on the home screen).
  ShopItem(
    id: 'tag.none',
    group: ShopGroup.tag,
    price: 0,
    name: (l) => l.shopTagNone,
  ),
  ShopItem(
    id: 'tag.rookie',
    group: ShopGroup.tag,
    price: 10,
    name: (l) => l.shopTagRookie,
  ),
  ShopItem(
    id: 'tag.loop',
    group: ShopGroup.tag,
    price: 15,
    name: (l) => l.shopTagLoop,
  ),
  ShopItem(
    id: 'tag.bug',
    group: ShopGroup.tag,
    price: 30,
    name: (l) => l.shopTagBug,
  ),
  ShopItem(
    id: 'tag.pro',
    group: ShopGroup.tag,
    price: 50,
    name: (l) => l.shopTagPro,
  ),
];

/// The items of one group, default first.
List<ShopItem> shopItemsIn(ShopGroup group) => [
  for (final item in shopItems)
    if (item.group == group) item,
];

ShopItem shopItemById(String id) => shopItems.firstWhere((i) => i.id == id);

/// What happened when the student tried to buy something.
enum BuyResult { bought, alreadyOwned, notEnough }

/// Star Points (the shop money) and the shop: what is owned and what is in
/// use, saved on the phone. Lives in [SettingsController.shop].
///
/// Points: every finished run earns as many points as the stars it earned;
/// the first time an item is completed, the points are doubled. Replays
/// earn again every time. The balance never goes below 0.
class ShopController extends ChangeNotifier {
  ShopController(this._prefs);

  final SharedPreferences _prefs;

  static const _kPoints = 'shop.points';
  static const _kOwned = 'shop.owned';
  static String _kEquipped(ShopGroup group) => 'shop.equipped.${group.name}';

  /// The Star Points the student has (never below 0).
  int get points {
    final p = _prefs.getInt(_kPoints) ?? 0;
    return p < 0 ? 0 : p;
  }

  /// Points for a finished run: its stars, doubled the first time.
  static int pointsFor(int stars, {required bool first}) {
    if (stars < 1) return 0;
    return first ? stars * 2 : stars;
  }

  /// Adds the points of a finished run and returns them.
  int earnRun(int stars, {required bool first}) {
    final earned = pointsFor(stars, first: first);
    if (earned > 0) {
      _prefs.setInt(_kPoints, points + earned);
      notifyListeners();
    }
    return earned;
  }

  /// Adds bonus points (e.g. the MINIGAME level bonus) and returns them.
  int addBonus(int bonus) {
    if (bonus <= 0) return 0;
    _prefs.setInt(_kPoints, points + bonus);
    notifyListeners();
    return bonus;
  }

  Set<String> get _owned => (_prefs.getStringList(_kOwned) ?? const []).toSet();

  bool owns(ShopItem item) => item.free || _owned.contains(item.id);

  /// How many more points [item] needs (0 if it can be bought now).
  int missingFor(ShopItem item) {
    final missing = item.price - points;
    return missing > 0 ? missing : 0;
  }

  /// Buys [item] once: only if it is not owned yet and there are enough
  /// points.
  BuyResult buy(ShopItem item) {
    if (owns(item)) return BuyResult.alreadyOwned;
    if (item.price > points) return BuyResult.notEnough;
    _prefs.setInt(_kPoints, points - item.price);
    _prefs.setStringList(_kOwned, [..._owned, item.id]..sort());
    notifyListeners();
    return BuyResult.bought;
  }

  /// The item in use for [group] (its free default if nothing else).
  ShopItem equipped(ShopGroup group) {
    final id = _prefs.getString(_kEquipped(group));
    for (final item in shopItems) {
      if (item.id == id && item.group == group && owns(item)) return item;
    }
    return shopItemsIn(group).first;
  }

  bool isEquipped(ShopItem item) => equipped(item.group).id == item.id;

  /// Uses [item] (only an owned one). Returns false if it is not owned.
  bool equip(ShopItem item) {
    if (!owns(item)) return false;
    _prefs.setString(_kEquipped(item.group), item.id);
    notifyListeners();
    return true;
  }

  ThemeLook get theme => equipped(ShopGroup.theme).theme!;
  EditorLook get editor => equipped(ShopGroup.editor).editor!;

  /// Cog's name tag on the home screen, or null for none.
  ShopItem? get tag {
    final item = equipped(ShopGroup.tag);
    return item.free ? null : item;
  }
}
