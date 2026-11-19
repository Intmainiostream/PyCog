import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/cog_art.dart';
import '../widgets/cog_placeholder.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/speech_bubble.dart';
import '../sound/sounds.dart';

/// About PyCog: what the app is and who made it, the version number, and
/// (very small, at the bottom) a link to the open-source notices.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  // The version and the notices link sit at the very bottom
                  // of the screen (or after the text, if it has to scroll).
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          AppSizes.gap8,
                          sidePadding,
                          AppSizes.gap8,
                        ),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  l10n.aboutTitle,
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
                              SpeechBubble(
                                key: const ValueKey('about-text'),
                                text: l10n.aboutText,
                                textAlign: TextAlign.start,
                                style: AppTextStyles.body,
                              ),
                              const SizedBox(height: AppSizes.gap24),
                              const Spacer(),
                              Text(
                                l10n.aboutVersion(appVersion),
                                key: const ValueKey('about-version'),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.small,
                              ),
                              Center(child: _NoticesLink(l10n.aboutNotices)),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// Small, light gray text that opens the license page (Pyodide, CPython,
/// fonts, Flutter packages). The text is small on purpose, but the tap
/// area is still a full 48px tall.
class _NoticesLink extends StatelessWidget {
  const _NoticesLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const ValueKey('about-notices'),
      onPressed: Sounds.tapThen(
        () => showLicensePage(context: context, applicationName: 'PyCog'),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textFaint,
        minimumSize: const Size(
          AppSizes.minTouchTarget,
          AppSizes.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.gap8),
        textStyle: AppTextStyles.small.copyWith(fontSize: 11),
      ),
      child: Text(label),
    );
  }
}
