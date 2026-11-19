import 'package:material_ui/material_ui.dart';

/// ============================================================================
///  PyCog theme: the ONE place to change colors, fonts and sizes.
///  Flat cartoon "sticker" style to match RoboFrontier.
/// ============================================================================
///
/// NOTE: these colors are placeholders picked by eye. When the RoboFrontier
/// reference image is available, sample the real values and replace them here.
/// Nothing else in the app hard-codes a color.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFFFFF3DA); // cream
  static const surface = Color(0xFFFFFBF1); // card fill (lighter cream)

  // Outlines and text
  static const outline = Color(0xFF3B2416); // thick dark brown outline
  static const text = Color(0xFF3B2416);
  static const textMuted = Color(0xFF7D6352);

  // Cog's colors
  static const teal = Color(0xFF26A69A); // main color (Cog's body)
  static const tealDark = Color(0xFF1B7A71);
  static const red = Color(0xFFE5483B); // accent: buttons and highlights
  static const redDark = Color(0xFFB33529);
  static const mint = Color(0xFFC4F2DD); // Cog's face screen
  static const success = Color(0xFFA8D83A); // yellow-green: correct answers
  static const successDark = Color(0xFF7DA626);
  static const star = Color(0xFFFFC93C); // XP / star counter

  // Locked / disabled things
  static const locked = Color(0xFFE3D6BC);
  static const lockedDark = Color(0xFFB9A88A);

  // Code boxes (dark box, light text, simple syntax colors)
  static const codeBackground = Color(0xFF2E211A);
  static const codeText = Color(0xFFFFF3DA);
  static const codeString = Color(0xFFB9E35A); // "Cog"
  static const codeNumber = Color(0xFFFFC93C); // 100
  static const codeKeyword = Color(0xFFFF8F80); // True / False
  static const codeOperator = Color(0xFF8FE3C0); // =
  static const codeInline = Color(0xFF1B7A71); // `code` inside sentences
  static const codeComment = Color(0xFFA8968A); // # comments (muted, italic)
  static const codeNote = Color(0xFF6FD3C8); // ← arrow notes (light Cog teal)

  // Quiz feedback
  static const hintBackground = Color(0xFFFFDCD3); // soft coral: "try again"

  // Clouds at the end of the lesson trail (back to front)
  static const cloudBack = Color(0xFFD6F4E6); // pale mint
  static const cloudMiddle = Color(0xFFFFF8E8); // warm cream
  static const cloudFront = Color(0xFFFFFFFF); // white
  static const cloudEdge = Color(0x333B2416); // soft outline (outline at 20%)
}

/// Font family names. They match the `family:` names in pubspec.yaml.
class AppFonts {
  AppFonts._();

  static const title = 'Fredoka';
  static const body = 'Nunito';
  static const code = 'JetBrainsMono';
}

/// Sizes, spacing, corner radii and the "sticker" outline and shadow.
class AppSizes {
  AppSizes._();

  // Outline and shadow
  static const outlineWidth = 3.0;
  static const shadowDepth = 5.0; // how far the hard shadow sits below a button
  static const pressDuration = Duration(milliseconds: 70);

  // Corners: rounded, but not too soft
  static const radiusSmall = 10.0;
  static const radius = 14.0;
  static const radiusLarge = 20.0;

  // Spacing
  static const gap4 = 4.0;
  static const gap8 = 8.0;
  static const gap12 = 12.0;
  static const gap16 = 16.0;
  static const gap24 = 24.0;
  static const screenPadding = 20.0;

  // Responsive layout
  static const minTouchTarget = 48.0; // smallest tappable size (accessibility)
  static const maxContentWidth = 600.0; // content column width on big screens
  static const maxWideContentWidth =
      1000.0; // same, for the side-by-side layout
  static const wideLayoutMinWidth =
      640.0; // landscape wider than this = 2 columns
  static const maxTextScale = 2.0; // system font size x app "Text size", capped

  // Home screen: Cog scales with the screen (a fraction of its shorter side)
  static const cogSizeFraction = 0.38;
  static const cogSizeMin = 96.0;
  static const cogSizeMax = 160.0;

  // Lesson path
  static const lessonNodeSize = 76.0;
  static const lessonPathSwing = 90.0; // max distance the path winds left/right
  static const lessonLabelMaxWidth = 180.0;
  static const lessonLabelWidthFraction = 0.62; // max share of the path's width
  static const lessonRowGap = 28.0; // space between a label and the next node
  static const pathWidth = 10.0;

  // Lesson screen
  static const lessonCogFraction = 0.24; // of the screen's shorter side
  static const lessonCogMin = 72.0;
  static const lessonCogMax = 120.0;
  static const progressBarHeight = 18.0;
  static const maxCodeTextScale = 1.5; // code doesn't wrap, so cap its growth
  static const variableBoxMinWidth = 96.0;

  // Quiz
  static const feedbackCogSize = 52.0; // mini Cog in the feedback card
  static const resultsStarMax = 80.0; // biggest star on the results screen
  static const resultsStarFraction = 0.2; // of the content width

  // Home screen (PLAY / MINIGAME / CODING)
  static const homeButtonIconSize = 34.0;
  static const homeButtonPadding = 20.0; // vertical padding inside each button
  // PyCog wordmark in the home top bar: as tall as the buttons beside it,
  // so the bar (and everything under it) keeps its height.
  static const wordmarkHeight = 48.0;

  // End of the lesson trail
  static const trailTailHeight = 70.0; // path past the last lesson
  static const cloudFooterMinHeight = 230.0;
  static const cloudOverlap = 40.0; // clouds cover the end of the path

  // Game: "Label the Robot Box"
  static const gameBoxMinHeight = 56.0; // drop area (well above 48)
  static const gameCogSize = 64.0; // Cog beside the speech bubble
  static const gameWideBoxColumns = 4; // boxes per row on wide screens
  static const gameNarrowBoxColumns = 2; // boxes per row on phones
  static const gameWideBoxMinWidth = 520.0; // area width needed for 4 columns
  static const gameTrayMaxFraction = 0.45; // max share of height for the tray

  // Text sizes
  static const fontDisplay = 32.0;
  static const fontTitle = 22.0;
  static const fontSubtitle = 18.0;
  static const fontBody = 16.0;
  static const fontSmall = 13.0;
}

/// Reusable text styles. Each sets the weight two ways: `fontWeight` and the
/// variable-font `wght` axis, so bold text is bold on every device.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _style(
    String family,
    double size,
    int weight, {
    Color color = AppColors.text,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
      color: color,
      height: 1.25,
    );
  }

  static final display = _style(AppFonts.title, AppSizes.fontDisplay, 700);
  static final title = _style(AppFonts.title, AppSizes.fontTitle, 600);
  static final subtitle = _style(AppFonts.title, AppSizes.fontSubtitle, 600);
  static final button = _style(AppFonts.title, AppSizes.fontSubtitle, 600);
  static final body = _style(AppFonts.body, AppSizes.fontBody, 600);
  static final bodyBold = _style(AppFonts.body, AppSizes.fontBody, 800);
  static final small = _style(
    AppFonts.body,
    AppSizes.fontSmall,
    700,
    color: AppColors.textMuted,
  );

  /// Code font with ligatures OFF: JetBrains Mono would otherwise draw
  /// `!=` as ≠ and `>=` as ≥, and students must see what they really type.
  static final code = _style(
    AppFonts.code,
    AppSizes.fontBody,
    500,
  ).copyWith(fontFeatures: codeFontFeatures);

  static const codeFontFeatures = [
    FontFeature.disable('calt'),
    FontFeature.disable('liga'),
  ];

  /// Arrow notes in code boxes: body font (not code font), smaller, italic,
  /// so they never look like something to type.
  static final codeNote = _style(
    AppFonts.body,
    AppSizes.fontSmall + 1,
    700,
    color: AppColors.codeNote,
  ).copyWith(fontStyle: FontStyle.italic);
}

/// The outline and hard shadow that give everything the sticker look.
class AppDecorations {
  AppDecorations._();

  static Border get outline =>
      Border.all(color: AppColors.outline, width: AppSizes.outlineWidth);

  static List<BoxShadow> hardShadow([double depth = AppSizes.shadowDepth]) => [
    BoxShadow(
      color: AppColors.outline,
      offset: Offset(0, depth),
      blurRadius: 0, // no blur = flat cartoon shadow
    ),
  ];

  /// A cream card with a thick outline and a hard shadow.
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = AppSizes.radius,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: outline,
      boxShadow: shadow ? hardShadow(4) : null,
    );
  }
}

/// The app-wide theme, built from the values above.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.red,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      outline: AppColors.outline,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.body,
      splashFactory: NoSplash.splashFactory, // flat look: no ripples
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        displaySmall: AppTextStyles.display,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.button,
        bodySmall: AppTextStyles.small,
      ),
      iconTheme: const IconThemeData(color: AppColors.outline),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.outline,
        contentTextStyle: AppTextStyles.bodyBold.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
      ),
    );
  }
}
