import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'data/progress_controller.dart';
import 'data/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  // Load saved settings (language, sound, music, text size) before starting.
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  runApp(PyCogApp(settings: settings, progress: progress));
}

class PyCogApp extends StatelessWidget {
  const PyCogApp({super.key, required this.settings, required this.progress});

  final SettingsController settings;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app whenever a setting changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        // Our app's text + material_ui's built-in text (buttons, tooltips...).
        // We don't use AppLocalizations.localizationsDelegates because it
        // points at the old flutter/material delegates, not material_ui's.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        // Apply the "Text size" setting on top of the phone's own text size,
        // capped so the layout never breaks (e.g. phone 1.5x * Large 1.2x =
        // 1.8x is fine; anything above 2x is held at 2x).
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final scale = (media.textScaler.scale(1) * settings.textSize.scale)
              .clamp(0.5, AppSizes.maxTextScale);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        },
        home: HomeScreen(settings: settings, progress: progress),
      ),
    );
  }
}

/// Shows the bundled fonts' licenses on the app's "Licenses" page.
void _registerFontLicenses() {
  const fonts = {
    'Fredoka': 'assets/fonts/OFL-Fredoka.txt',
    'Nunito': 'assets/fonts/OFL-Nunito.txt',
    'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
}
