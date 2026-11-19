import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'data/minigame_progress.dart';
import 'data/progress_controller.dart';
import 'data/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'sound/audio_clips.dart';
import 'sound/sounds.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  _registerPythonLicenses();
  // Load saved settings (language, sound, music, text size) before starting.
  final settings = await SettingsController.load();
  final progress = await ProgressController.load();
  final minigame = await MinigameProgress.load();
  // Sound effects: loaded in the background, so the app starts right away.
  Sounds.player = SequencedSoundPlayer(AudioplayersClips());
  unawaited(Sounds.player.preload());
  runApp(PyCogApp(settings: settings, progress: progress, minigame: minigame));
}

class PyCogApp extends StatelessWidget {
  const PyCogApp({
    super.key,
    required this.settings,
    required this.progress,
    this.minigame,
    this.intro = true,
  });

  final SettingsController settings;
  final ProgressController progress;

  /// MINIGAME stars (the home screen loads them itself if not given).
  final MinigameProgress? minigame;

  /// Show the splash first (and the onboarding on the first launch).
  /// Tests that start at the home screen turn this off.
  final bool intro;

  Widget _home(BuildContext context) =>
      HomeScreen(settings: settings, progress: progress, minigame: minigame);

  /// Splash, then the onboarding (first launch only), then home.
  Widget _start(BuildContext context) {
    if (!intro) return _home(context);
    return SplashScreen(
      next: (context) => settings.onboardingSeen
          ? _home(context)
          : OnboardingScreen(settings: settings, home: _home),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sounds follow the "Sound effects" switch.
    Sounds.useSettings(settings);
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
        home: Builder(builder: _start),
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

/// Shows the licenses of the offline Python (the CODING playground) on the
/// app's "Licenses" page: Pyodide (MPL-2.0) and CPython (PSF License).
void _registerPythonLicenses() {
  LicenseRegistry.addLicense(() async* {
    final pyodide = await rootBundle.loadString(
      'assets/pyodide/LICENSE-pyodide.txt',
    );
    yield LicenseEntryWithLineBreaks(
      ['Pyodide'],
      'Pyodide 314.0.8, included unmodified. Source code: '
      'https://github.com/pyodide/pyodide\n\n$pyodide',
    );
    yield LicenseEntryWithLineBreaks([
      'CPython (Python)',
    ], await rootBundle.loadString('assets/pyodide/LICENSE-cpython.txt'));
  });
}
