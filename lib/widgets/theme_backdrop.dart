import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/shop.dart';

/// The extra picture behind the home screen and the Play trail for each
/// app color theme (Star Shop): a soft sun for Sunset, leaves for Mint,
/// waves and bubbles for Ocean, sprinkles for Candy. Classic has none.
///
/// Made to cost nothing while the app runs: no animation, fixed shapes
/// (no randomness), only light see-through colors so text stays easy to
/// read. It is painted once and only again if the size or theme changes;
/// the RepaintBoundary around it (see ShopThemed) keeps scrolling and taps
/// from repainting it.
class ThemeBackdropPainter extends CustomPainter {
  const ThemeBackdropPainter(this.look);

  final ThemeLook look;

  /// Every color a decoration may use (with its see-through amount), so a
  /// test can check text contrast on top of the worst one.
  static List<Color> colorsFor(ThemeDecor decor) => switch (decor) {
    ThemeDecor.none => const [],
    ThemeDecor.sunset => [
      _sunsetBottom,
      _sunGlow.withValues(alpha: 0.9),
      Colors.white.withValues(alpha: 0.6),
    ],
    ThemeDecor.mint => [_mintBottom, _leaf.withValues(alpha: 0.4)],
    ThemeDecor.ocean => [
      _oceanBottom,
      _waveBack.withValues(alpha: 0.7),
      _waveFront.withValues(alpha: 0.7),
      Colors.white.withValues(alpha: 0.7),
    ],
    ThemeDecor.candy => [
      _candyBottom,
      for (final c in _sprinkles) c.withValues(alpha: 0.6),
    ],
  };

  static const _sunsetBottom = Color(0xFFFFDCC8);
  static const _sunGlow = Color(0xFFFFE6A6);
  static const _mintBottom = Color(0xFFD9F4E7);
  static const _leaf = Color(0xFF9FD9B9);
  static const _oceanBottom = Color(0xFFD5ECFF);
  static const _waveBack = Color(0xFFBFE0F8);
  static const _waveFront = Color(0xFFAFD7F5);
  static const _candyBottom = Color(0xFFFFE6F1);
  static const _sprinkles = [
    Color(0xFFFFB8D2),
    Color(0xFFB8EAD8),
    Color(0xFFFFE19C),
    Color(0xFFCFC8F6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = look.background);
    switch (look.decor) {
      case ThemeDecor.none:
        break;
      case ThemeDecor.sunset:
        _wash(canvas, rect, _sunsetBottom);
        _sunset(canvas, size);
      case ThemeDecor.mint:
        _wash(canvas, rect, _mintBottom);
        _leaves(canvas, size);
      case ThemeDecor.ocean:
        _wash(canvas, rect, _oceanBottom);
        _ocean(canvas, size);
      case ThemeDecor.candy:
        _wash(canvas, rect, _candyBottom);
        _candy(canvas, size);
    }
  }

  /// A soft color wash that gets a little deeper towards the bottom.
  void _wash(Canvas canvas, Rect rect, Color bottom) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.background, bottom],
        ).createShader(rect),
    );
  }

  void _sunset(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // A big soft sun in the top-right corner.
    final sun = Rect.fromCircle(
      center: Offset(w * 0.86, h * 0.1),
      radius: math.min(w, h) * 0.32,
    );
    canvas.drawOval(
      sun,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _sunGlow.withValues(alpha: 0.9),
            _sunGlow.withValues(alpha: 0),
          ],
        ).createShader(sun),
    );
    // Two faint cloud streaks.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (final (x, y, len) in [(0.04, 0.22, 0.34), (0.62, 0.42, 0.3)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * y, w * len, 14),
          const Radius.circular(7),
        ),
        cloud,
      );
    }
  }

  void _leaves(Canvas canvas, Size size) {
    final paint = Paint()..color = _leaf.withValues(alpha: 0.4);
    // Fixed places near the edges, so the middle stays clean.
    for (final (x, y, s, turn) in [
      (0.06, 0.14, 26.0, -0.6),
      (0.92, 0.22, 22.0, 0.8),
      (0.1, 0.48, 18.0, 0.3),
      (0.9, 0.58, 28.0, -0.4),
      (0.05, 0.8, 24.0, 0.9),
      (0.94, 0.88, 20.0, -0.9),
      (0.5, 0.97, 22.0, 0.2),
    ]) {
      canvas
        ..save()
        ..translate(size.width * x, size.height * y)
        ..rotate(turn);
      final leaf = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.7, 0, 0, s)
        ..quadraticBezierTo(-s * 0.7, 0, 0, -s)
        ..close();
      canvas
        ..drawPath(leaf, paint)
        ..restore();
    }
  }

  void _ocean(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Two soft waves along the bottom.
    for (final (top, amp, color) in [
      (0.86, 10.0, _waveBack),
      (0.91, 8.0, _waveFront),
    ]) {
      final path = Path()..moveTo(0, h * top);
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final x = w * i / steps;
        path.lineTo(x, h * top + math.sin(i / steps * math.pi * 4) * amp);
      }
      path
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.7));
    }
    // A few bubbles near the sides.
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final (x, y, r) in [
      (0.07, 0.3, 9.0),
      (0.11, 0.38, 5.0),
      (0.92, 0.5, 11.0),
      (0.88, 0.6, 6.0),
      (0.06, 0.72, 7.0),
      (0.94, 0.78, 5.0),
    ]) {
      final c = Offset(w * x, h * y);
      canvas
        ..drawCircle(c, r, fill)
        ..drawCircle(c, r, ring);
    }
  }

  void _candy(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Sprinkles: little rounded sticks in pastel colors, near the edges.
    const spots = [
      (0.06, 0.12, 0.5),
      (0.93, 0.18, -0.7),
      (0.12, 0.3, 1.1),
      (0.88, 0.36, 0.2),
      (0.05, 0.52, -0.3),
      (0.95, 0.6, 0.9),
      (0.1, 0.7, 0.4),
      (0.9, 0.76, -1.0),
      (0.06, 0.9, 0.8),
      (0.94, 0.94, -0.2),
      (0.3, 0.97, 0.6),
      (0.7, 0.96, -0.5),
    ];
    for (final (i, (x, y, turn)) in spots.indexed) {
      final color = _sprinkles[i % _sprinkles.length].withValues(alpha: 0.6);
      canvas
        ..save()
        ..translate(w * x, h * y)
        ..rotate(turn)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-9, -3, 18, 6),
            const Radius.circular(3),
          ),
          Paint()..color = color,
        )
        ..restore();
      // A small dot next to every other sprinkle.
      if (i.isEven) {
        canvas.drawCircle(
          Offset(w * x + 16, h * y + 10),
          3.5,
          Paint()..color = _sprinkles[(i + 2) % 4].withValues(alpha: 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ThemeBackdropPainter oldDelegate) =>
      oldDelegate.look.decor != look.decor ||
      oldDelegate.look.background != look.background;
}
