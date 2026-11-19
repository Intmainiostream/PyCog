import 'package:material_ui/material_ui.dart';

import '../data/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';
import 'sticker_switch.dart';

/// Opens the settings panel from the bottom of the screen.
Future<void> showSettingsSheet(
  BuildContext context,
  SettingsController settings,
) {
  return showModalBottomSheet<void>(
    context: context,
    // Tall content scrolls inside the panel; it never goes under the notch,
    // and on tablets it doesn't stretch wider than the content column.
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
    backgroundColor: Colors.transparent,
    builder: (_) => SettingsSheet(settings: settings),
  );
}

/// The settings panel: language, sound, music and text size.
/// Every change is applied and saved immediately.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLarge),
            ),
            // Rounded corners need an outline on all sides; the sides and
            // bottom just run off the screen edges.
            border: Border.fromBorderSide(
              BorderSide(
                color: AppColors.outline,
                width: AppSizes.outlineWidth,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.gap12,
                AppSizes.screenPadding,
                AppSizes.screenPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Grabber(),
                  const SizedBox(height: AppSizes.gap12),
                  Text(
                    l10n.settingsTitle,
                    style: AppTextStyles.display,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.gap16),

                  // ---- Language ----
                  _SettingCard(
                    icon: Icons.translate,
                    label: l10n.settingsLanguage,
                    below: OptionPicker<Locale>(
                      selected: settings.locale,
                      onChanged: settings.setLocale,
                      options: {
                        SettingsController.english: l10n.languageEnglish,
                        SettingsController.tagalog: l10n.languageTagalog,
                      },
                    ),
                  ),

                  // ---- Sound and music ----
                  _SettingCard(
                    icon: Icons.volume_up_rounded,
                    label: l10n.settingsSound,
                    trailing: StickerSwitch(
                      value: settings.soundOn,
                      onChanged: settings.setSoundOn,
                      semanticLabel: l10n.settingsSound,
                    ),
                  ),
                  _SettingCard(
                    icon: Icons.music_note_rounded,
                    label: l10n.settingsMusic,
                    trailing: StickerSwitch(
                      value: settings.musicOn,
                      onChanged: settings.setMusicOn,
                      semanticLabel: l10n.settingsMusic,
                    ),
                  ),

                  // ---- Text size ----
                  _SettingCard(
                    icon: Icons.format_size_rounded,
                    label: l10n.settingsTextSize,
                    below: OptionPicker<TextSize>(
                      selected: settings.textSize,
                      onChanged: settings.setTextSize,
                      options: {
                        TextSize.small: l10n.textSizeSmall,
                        TextSize.medium: l10n.textSizeMedium,
                        TextSize.large: l10n.textSizeLarge,
                      },
                    ),
                  ),

                  const SizedBox(height: AppSizes.gap8),
                  ChunkyButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(l10n.settingsDone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The little bar at the top of the panel that hints it can be dragged down.
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.lockedDark,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// One outlined card in the settings panel: icon + label, then either a
/// control on the right ([trailing]) or a row of options underneath ([below]).
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.label,
    this.trailing,
    this.below,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.gap16),
      padding: const EdgeInsets.all(AppSizes.gap12),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Icon grows with the text so it doesn't look tiny at big sizes.
              Icon(
                icon,
                color: AppColors.teal,
                size: MediaQuery.textScalerOf(context).scale(24),
              ),
              const SizedBox(width: AppSizes.gap8),
              Expanded(child: Text(label, style: AppTextStyles.subtitle)),
              ?trailing,
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: AppSizes.gap12),
            below!,
          ],
        ],
      ),
    );
  }
}

/// A row of chunky buttons where exactly one is selected (teal).
class OptionPicker<T> extends StatelessWidget {
  const OptionPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  static const _padding = EdgeInsets.symmetric(
    horizontal: AppSizes.gap8,
    vertical: AppSizes.gap8,
  );
  static final _labelStyle = AppTextStyles.button.copyWith(
    fontSize: AppSizes.fontBody,
  );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the longest label at the current text size. If the options
        // don't all fit side by side, stack them in a column instead.
        final widest = options.values
            .map(
              (label) => (TextPainter(
                text: TextSpan(text: label, style: _labelStyle),
                textDirection: TextDirection.ltr,
                textScaler: scaler,
                maxLines: 1,
              )..layout()).width,
            )
            .reduce((a, b) => a > b ? a : b);
        final perOption =
            widest + _padding.horizontal + AppSizes.outlineWidth * 2 + 4;
        final needed =
            perOption * options.length + AppSizes.gap8 * (options.length - 1);
        final fitsInRow = needed <= constraints.maxWidth;

        final buttons = [
          for (final MapEntry(key: value, value: label) in options.entries)
            Semantics(
              selected: value == selected,
              child: ChunkyButton(
                color: value == selected ? AppColors.teal : AppColors.surface,
                radius: AppSizes.radiusSmall,
                padding: _padding,
                onTap: () => onChanged(value),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _labelStyle,
                ),
              ),
            ),
        ];

        if (fitsInRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizes.gap8),
                Expanded(child: buttons[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSizes.gap4),
              buttons[i],
            ],
          ],
        );
      },
    );
  }
}
