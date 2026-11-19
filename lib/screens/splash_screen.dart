import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

/// A page change that fades the new screen in.
Route<void> fadeRoute(WidgetBuilder builder) => PageRouteBuilder<void>(
  transitionDuration: SplashScreen.fade,
  reverseTransitionDuration: SplashScreen.fade,
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

/// The first thing the app shows: the PyCog wordmark on the cream
/// background. It fades in, stays for [hold], fades out, and then the
/// [next] screen fades in.
///
/// It is drawn by Flutter (no native splash package), right after the
/// phone's own short launch screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  /// The screen after the splash (onboarding or home).
  final WidgetBuilder next;

  static const fade = Duration(milliseconds: 400);
  static const hold = Duration(milliseconds: 1200);

  /// Fade in + stay + fade out.
  static Duration get total => fade + hold + fade;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // One animation for the whole splash, so tests (and pumpAndSettle) can
  // run straight through it.
  late final _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.total,
  );

  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: SplashScreen.fade.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: ConstantTween(1.0),
      weight: SplashScreen.hold.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: SplashScreen.fade.inMilliseconds.toDouble(),
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.of(context).pushReplacement(fadeRoute(widget.next));
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = math.min(
      MediaQuery.sizeOf(context).width * 0.7,
      AppSizes.splashWordmarkMaxWidth,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Semantics(
            label: l10n.appTitle,
            image: true,
            child: ExcludeSemantics(
              child: Image.asset(
                AppTopBar.wordmarkAsset,
                key: const ValueKey('splash-wordmark'),
                width: width,
                height: width / AppTopBar.wordmarkAspect,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Text(
                  l10n.appTitle,
                  style: AppTextStyles.display.copyWith(
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
