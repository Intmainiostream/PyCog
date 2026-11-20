import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop.dart';

/// The three text size options in Settings.
enum TextSize {
  small(0.9),
  medium(1.0),
  large(1.2);

  const TextSize(this.scale);

  /// How much bigger or smaller than normal the text is.
  final double scale;
}

/// Holds every user setting and saves it to the phone with shared_preferences,
/// so choices are remembered after the app closes.
///
/// Widgets that listen to this rebuild whenever a setting changes.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs)
    : _locale = Locale(_prefs.getString(_kLanguage) ?? 'en'),
      _soundOn = _prefs.getBool(_kSound) ?? true,
      _musicOn = _prefs.getBool(_kMusic) ?? true,
      _onboardingSeen = _prefs.getBool(_kOnboardingSeen) ?? false,
      _textSize =
          TextSize.values.asNameMap()[_prefs.getString(_kTextSize)] ??
          TextSize.medium;

  /// Loads saved settings (or defaults on first launch).
  static Future<SettingsController> load() async {
    return SettingsController._(await SharedPreferences.getInstance());
  }

  // Keys used to save each setting on the device.
  static const _kLanguage = 'settings.language';
  static const _kSound = 'settings.sound';
  static const _kMusic = 'settings.music';
  static const _kTextSize = 'settings.textSize';
  static const _kOnboardingSeen = 'app.onboardingSeen';

  static const english = Locale('en');
  static const tagalog = Locale('tl');

  final SharedPreferences _prefs;

  /// Star Points and the Star Shop (saved in the same place).
  late final ShopController shop = ShopController(_prefs);

  Locale _locale;
  bool _soundOn;
  bool _musicOn;
  TextSize _textSize;
  bool _onboardingSeen;

  Locale get locale => _locale;
  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  TextSize get textSize => _textSize;

  /// Whether the first-launch onboarding was already shown.
  bool get onboardingSeen => _onboardingSeen;

  void setLocale(Locale value) {
    _locale = value;
    _prefs.setString(_kLanguage, value.languageCode);
    notifyListeners();
  }

  void setSoundOn(bool value) {
    _soundOn = value;
    _prefs.setBool(_kSound, value);
    notifyListeners();
  }

  void setMusicOn(bool value) {
    _musicOn = value;
    _prefs.setBool(_kMusic, value);
    notifyListeners();
  }

  /// Remembers that the onboarding was shown, so it never shows again.
  void markOnboardingSeen() {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    _prefs.setBool(_kOnboardingSeen, true);
  }

  void setTextSize(TextSize value) {
    _textSize = value;
    _prefs.setString(_kTextSize, value.name);
    notifyListeners();
  }
}
