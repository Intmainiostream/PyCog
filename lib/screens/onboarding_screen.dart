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
import 'splash_screen.dart';

/// First launch only: three short screens about PyCog, with Skip on each,
/// Next, and "Let's start!" at the end. The first screen also has the
/// language switch (at its top). Finishing (or skipping) saves that it was seen and
/// opens [home].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.home,
  });

  final SettingsController settings;
  final WidgetBuilder home;

  static const pageCount = 3;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _leaving = false;

  bool get _isLast => _page == OnboardingScreen.pageCount - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _done();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _done() {
    if (_leaving) return;
    _leaving = true;
    widget.settings.markOnboardingSeen();
    Navigator.of(context).pushReplacement(fadeRoute(widget.home));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (CogPose.waving, l10n.onbTitle1, l10n.onbText1),
      (CogPose.waving, l10n.onbTitle2, l10n.onbText2),
      (CogPose.cheering, l10n.onbTitle3, l10n.onbText3),
    ];

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
                // Skip, on every screen.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSizes.gap12,
                    side,
                    AppSizes.gap8,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    // Only as wide as its word (buttons fill the row otherwise).
                    child: IntrinsicWidth(
                      child: ChunkyButton(
                        key: const ValueKey('onb-skip'),
                        color: AppColors.surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.gap16,
                          vertical: AppSizes.gap8,
                        ),
                        onTap: _done,
                        child: Text(l10n.onbSkip),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    key: const ValueKey('onb-pages'),
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (final (i, (pose, title, text)) in pages.indexed)
                        SingleChildScrollView(
                          key: ValueKey('onb-page-$i'),
                          padding: EdgeInsets.fromLTRB(
                            side,
                            AppSizes.gap8,
                            side,
                            AppSizes.gap16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The language switch, on the first screen.
                              if (i == 0) ...[
                                _language(l10n),
                                const SizedBox(height: AppSizes.gap16),
                              ],
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.display,
                                ),
                              ),
                              const SizedBox(height: AppSizes.gap16),
                              Center(
                                child: CogArt(
                                  pose: pose,
                                  // Smaller with very big text, so the words
                                  // get the room.
                                  size:
                                      MediaQuery.textScalerOf(context)
                                              .scale(1) >
                                          1.3
                                      ? CogPlaceholder.lessonSizeFor(context)
                                      : CogPlaceholder.sizeFor(context),
                                ),
                              ),
                              SpeechBubble(text: text),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.gap8),
                _dots(l10n),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSizes.gap12,
                    side,
                    AppSizes.gap16,
                  ),
                  child: ChunkyButton(
                    key: const ValueKey('onb-next'),
                    color: _isLast ? AppColors.success : AppColors.red,
                    onTap: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _isLast ? l10n.onbStart : l10n.onbNext,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (!_isLast) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded),
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

  /// The language switch (same picker as in Settings).
  Widget _language(AppLocalizations l10n) {
    return Semantics(
      label: l10n.settingsLanguage,
      child: OptionPicker<Locale>(
        key: const ValueKey('onb-language'),
        options: {
          SettingsController.english: l10n.languageEnglish,
          SettingsController.tagalog: l10n.languageTagalog,
        },
        selected: widget.settings.locale,
        onChanged: widget.settings.setLocale,
      ),
    );
  }

  /// Which screen this is: three dots, the current one long and teal.
  Widget _dots(AppLocalizations l10n) {
    return Semantics(
      label: l10n.onbPage(_page + 1, OnboardingScreen.pageCount),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < OnboardingScreen.pageCount; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _page ? 22 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.teal : AppColors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.outline, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}
