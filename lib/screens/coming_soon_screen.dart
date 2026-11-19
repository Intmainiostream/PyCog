import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_art.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';

/// Which home button opened the "Coming soon" screen.
enum ComingSoonKind { minigame, coding }

/// A simple placeholder screen: Cog says the feature is coming soon, with a
/// back arrow at the top and a big Back button.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.kind,
    required this.settings,
  });

  final ComingSoonKind kind;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, message) = switch (kind) {
      ComingSoonKind.minigame => (
        Icons.extension_rounded,
        l10n.homeMinigameSoon,
      ),
      ComingSoonKind.coding => (Icons.code_rounded, l10n.homeCodingSoon),
    };
    void back() => Navigator.of(context).pop();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = math.max(
              AppSizes.screenPadding,
              (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
            );
            return Column(
              children: [
                // Back arrow and gear, like the other screens.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    AppSizes.gap12,
                    sidePadding,
                    AppSizes.gap8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChunkyButton(
                        circle: true,
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                        padding: EdgeInsets.zero,
                        color: AppColors.surface,
                        semanticLabel: l10n.lessonBack,
                        onTap: back,
                        child: const Icon(Icons.arrow_back_rounded, size: 28),
                      ),
                      ChunkyButton(
                        circle: true,
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                        padding: EdgeInsets.zero,
                        color: AppColors.surface,
                        semanticLabel: l10n.settingsTooltip,
                        onTap: () => showSettingsSheet(context, settings),
                        child: const Icon(Icons.settings_rounded, size: 28),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      AppSizes.gap8,
                      sidePadding,
                      AppSizes.gap24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          icon,
                          size: MediaQuery.textScalerOf(context).scale(40),
                          color: AppColors.tealDark,
                        ),
                        const SizedBox(height: AppSizes.gap8),
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.homeComingSoonTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display,
                          ),
                        ),
                        const SizedBox(height: AppSizes.gap16),
                        Center(
                          child: CogArt(
                            pose: CogPose.waving,
                            size: CogPlaceholder.lessonSizeFor(context),
                          ),
                        ),
                        SpeechBubble(text: message),
                        const SizedBox(height: AppSizes.gap24),
                        ChunkyButton(
                          color: AppColors.red,
                          onTap: back,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_back_rounded),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  l10n.lessonBack,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
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
