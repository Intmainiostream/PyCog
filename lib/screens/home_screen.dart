import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/lessons.dart';
import '../data/minigame_progress.dart';
import '../data/progress_controller.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../playground/python_runner.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import 'coding_screen.dart';
import 'minigame_map_screen.dart';
import 'trail_screen.dart';

/// The first screen: Cog says hi, with three big buttons.
///  * PLAY opens the lesson trail.
///  * MINIGAME opens the challenge map ([MinigameMapScreen]).
///  * CODING opens the Python playground ([CodingScreen]).
///
/// When it opens, Python starts quietly in the background, so the first Run
/// in the playground is fast.
///
/// The star counter and gear are the same as on the trail, and the stars
/// update live from saved progress.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.progress,
    this.minigame,
  });

  final SettingsController settings;
  final ProgressController progress;

  /// MINIGAME stars. Loaded when MINIGAME is tapped if not given.
  final MinigameProgress? minigame;

  void _openTrail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Named, so "Back to lessons" can return to the trail.
        settings: const RouteSettings(name: TrailScreen.routeName),
        builder: (_) => TrailScreen(settings: settings, progress: progress),
      ),
    );
  }

  void _openCoding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CodingScreen(settings: settings)),
    );
  }

  Future<void> _openMinigame(BuildContext context) async {
    final navigator = Navigator.of(context);
    final saved = minigame ?? await MinigameProgress.load();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => MinigameMapScreen(settings: settings, progress: saved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WarmUpPython(child: _build(context));
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: progress, // keeps the star counter up to date
        builder: (context, _) => SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppSizes.wideLayoutMinWidth &&
                  constraints.maxWidth > constraints.maxHeight;
              final maxWidth = wide
                  ? AppSizes.maxWideContentWidth
                  : AppSizes.maxContentWidth;
              final sidePadding = math.max(
                AppSizes.screenPadding,
                (constraints.maxWidth - maxWidth) / 2,
              );

              return Column(
                children: [
                  AppTopBar(
                    sidePadding: sidePadding,
                    stars: progress.totalStars(lessons),
                    onSettings: () => showSettingsSheet(context, settings),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        AppSizes.gap8,
                        sidePadding,
                        AppSizes.gap24,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 2, child: _cog(context)),
                                const SizedBox(width: AppSizes.gap24),
                                Expanded(flex: 3, child: _buttons(context)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _cog(context),
                                const SizedBox(height: AppSizes.gap24),
                                _buttons(context),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cog(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CogPlaceholder(size: CogPlaceholder.sizeFor(context)),
        SpeechBubble(text: AppLocalizations.of(context).homeGreeting),
      ],
    );
  }

  Widget _buttons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeButton(
          key: const ValueKey('home-play'),
          label: l10n.homePlay,
          icon: Icons.play_arrow_rounded,
          color: AppColors.red,
          onTap: () => _openTrail(context),
        ),
        const SizedBox(height: AppSizes.gap12),
        _HomeButton(
          key: const ValueKey('home-minigame'),
          label: l10n.homeMinigame,
          icon: Icons.extension_rounded,
          color: AppColors.teal,
          onTap: () => _openMinigame(context),
        ),
        const SizedBox(height: AppSizes.gap12),
        _HomeButton(
          key: const ValueKey('home-coding'),
          label: l10n.homeCoding,
          icon: Icons.code_rounded,
          color: AppColors.success,
          onTap: () => _openCoding(context),
        ),
      ],
    );
  }
}

/// One big chunky home button: icon + label.
class _HomeButton extends StatelessWidget {
  const _HomeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: color,
      radius: AppSizes.radiusLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.gap24,
        vertical: AppSizes.homeButtonPadding,
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.homeButtonIconSize),
          const SizedBox(width: AppSizes.gap12),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              // No color here: the label takes the button's text color
              // (white on red/teal, dark on yellow-green).
              style: const TextStyle(
                fontFamily: AppFonts.title,
                fontSize: AppSizes.fontTitle + 4,
                fontWeight: FontWeight.w700,
                fontVariations: [FontVariation.weight(700)],
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Starts Python quietly in the background once, when the home screen
/// opens. If it cannot start here (e.g. no WebView), nothing happens; the
/// playground shows "Starting Python..." and tries again on Run.
class _WarmUpPython extends StatefulWidget {
  const _WarmUpPython({required this.child});

  final Widget child;

  @override
  State<_WarmUpPython> createState() => _WarmUpPythonState();
}

class _WarmUpPythonState extends State<_WarmUpPython> {
  @override
  void initState() {
    super.initState();
    PyodideEngine.instance.warmUp().ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
