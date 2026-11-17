import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';

/// Lessons drawn as a winding trail of numbered round buttons.
///
/// The first [unlockedCount] lessons are open (red); the rest show a lock.
///
/// Responsive: the trail winds less on narrow screens, labels get narrower,
/// and each row's height is measured from the real label text at the current
/// text size, so big system fonts push rows apart instead of overlapping.
class LessonPath extends StatelessWidget {
  const LessonPath({
    super.key,
    required this.lessons,
    required this.unlockedCount,
    required this.onLessonTap,
    this.showTail = false,
  });

  final List<Lesson> lessons;
  final int unlockedCount;
  final void Function(Lesson lesson, bool unlocked) onLessonTap;

  /// Draws the path on past the last lesson, ending at the bottom center
  /// (where the trail's cloud area begins).
  final bool showTail;

  static const _labelMaxLines = 3;
  static const _labelPadding = EdgeInsets.symmetric(
    horizontal: AppSizes.gap8,
    vertical: 2,
  );
  static const _tagPadding = EdgeInsets.symmetric(
    horizontal: AppSizes.gap12,
    vertical: 2,
  );
  static final _tagStyle = AppTextStyles.small.copyWith(
    color: AppColors.text,
    fontWeight: FontWeight.w900,
    fontVariations: const [FontVariation.weight(900)],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layOut(l10n, scaler, constraints.maxWidth);

        return SizedBox(
          height: layout.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    layout.nodes.map((n) => n.center).toList(),
                    unlockedCount,
                    tail: showTail && lessons.isNotEmpty,
                  ),
                ),
              ),
              for (var i = 0; i < lessons.length; i++)
                ..._buildNode(
                  l10n: l10n,
                  lesson: lessons[i],
                  number: i + 1,
                  node: layout.nodes[i],
                  labelWidth: layout.labelWidth,
                  unlocked: i < unlockedCount,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Works out where every node, label and tag goes for this width and text
  /// size, from top to bottom.
  _PathLayout _layOut(AppLocalizations l10n, TextScaler scaler, double width) {
    const node = AppSizes.lessonNodeSize;
    const outline = AppSizes.outlineWidth * 2;

    // Labels get wider with bigger text (up to 1.5x) so words don't break
    // mid-word, but never take more than a share of the available width.
    final textGrowth = (scaler.scale(1)).clamp(1.0, 1.5);
    final labelWidth = math.max(
      node,
      math.min(
        AppSizes.lessonLabelMaxWidth * textGrowth,
        width * AppSizes.lessonLabelWidthFraction,
      ),
    );
    // Wind less on narrow screens so labels never go off the edge.
    final swing = math.min(
      AppSizes.lessonPathSwing,
      math.max(0.0, (width - labelWidth) / 2),
    );

    double textHeight(String text, TextStyle style, double maxWidth) {
      return (TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: _labelMaxLines,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth)).height;
    }

    final tagHeight =
        textHeight(l10n.startLabel.toUpperCase(), _tagStyle, labelWidth) +
        _tagPadding.vertical +
        outline;

    final nodes = <_NodeLayout>[];
    var y = 0.0;
    for (var i = 0; i < lessons.length; i++) {
      final isNext = i == unlockedCount - 1;
      double? tagTop;
      if (isNext) {
        tagTop = y;
        y += tagHeight + AppSizes.gap8;
      }

      final center = Offset(
        width / 2 + swing * math.sin(i * math.pi / 2),
        y + node / 2,
      );
      // Node + its hard shadow + a small gap.
      y += node + AppSizes.shadowDepth + AppSizes.gap8;

      final labelTop = y;
      final labelHeight =
          textHeight(
            lessons[i].title(l10n),
            AppTextStyles.bodyBold,
            labelWidth - _labelPadding.horizontal - outline,
          ) +
          _labelPadding.vertical +
          outline;
      y = labelTop + labelHeight + AppSizes.lessonRowGap;

      nodes.add(
        _NodeLayout(center: center, labelTop: labelTop, tagTop: tagTop),
      );
    }

    return _PathLayout(
      nodes: nodes,
      labelWidth: labelWidth,
      height:
          math.max(0, y - AppSizes.lessonRowGap + AppSizes.gap8) +
          (showTail && lessons.isNotEmpty ? AppSizes.trailTailHeight : 0),
    );
  }

  List<Widget> _buildNode({
    required AppLocalizations l10n,
    required Lesson lesson,
    required int number,
    required _NodeLayout node,
    required double labelWidth,
    required bool unlocked,
  }) {
    const size = AppSizes.lessonNodeSize;
    final title = lesson.title(l10n);
    final center = node.center;

    return [
      // "Start" tag above the lesson to do next
      if (node.tagTop != null)
        Positioned(
          left: center.dx - labelWidth / 2,
          width: labelWidth,
          top: node.tagTop,
          child: Center(child: _StartTag(style: _tagStyle)),
        ),

      // The round numbered button
      Positioned(
        key: ValueKey('lesson-node-${lesson.id}'),
        left: center.dx - size / 2,
        top: center.dy - size / 2,
        child: ChunkyButton(
          circle: true,
          width: size,
          height: size,
          padding: const EdgeInsets.all(AppSizes.gap8),
          color: unlocked ? AppColors.red : AppColors.locked,
          semanticLabel:
              '${l10n.lessonNumber(number)}: $title'
              '${unlocked ? '' : ' (${l10n.lessonLocked})'}',
          onTap: () => onLessonTap(lesson, unlocked),
          child: ExcludeSemantics(
            child: unlocked
                // Shrinks the number to fit if the text size is very large.
                ? FittedBox(
                    child: Text(
                      '$number',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.lock_rounded,
                    size: 30,
                    color: AppColors.lockedDark,
                  ),
          ),
        ),
      ),

      // Lesson title under the node, on a small sticker label so it sits
      // on top of the trail instead of being crossed by it.
      Positioned(
        key: ValueKey('lesson-label-${lesson.id}'),
        left: center.dx - labelWidth / 2,
        width: labelWidth,
        top: node.labelTop,
        child: ExcludeSemantics(
          child: Center(
            child: Container(
              padding: _labelPadding,
              decoration: AppDecorations.card(
                radius: AppSizes.radiusSmall,
                shadow: false,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: _labelMaxLines,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyBold.copyWith(
                  color: unlocked ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

class _NodeLayout {
  const _NodeLayout({
    required this.center,
    required this.labelTop,
    required this.tagTop,
  });

  final Offset center;
  final double labelTop;
  final double? tagTop; // only set for the "next" lesson
}

class _PathLayout {
  const _PathLayout({
    required this.nodes,
    required this.labelWidth,
    required this.height,
  });

  final List<_NodeLayout> nodes;
  final double labelWidth;
  final double height;
}

/// Small yellow-green "Start" label shown above the next lesson.
class _StartTag extends StatelessWidget {
  const _StartTag({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: LessonPath._tagPadding,
      decoration: AppDecorations.card(
        color: AppColors.success,
        radius: AppSizes.radiusSmall,
        shadow: false,
      ),
      child: Text(
        AppLocalizations.of(context).startLabel.toUpperCase(),
        style: style,
      ),
    );
  }
}

/// Draws the thick winding trail that connects the nodes.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.centers, this.unlockedCount, {this.tail = false});

  final List<Offset> centers;
  final int unlockedCount;

  /// Also draw a locked-color stretch from the last node down to the
  /// bottom center (into the clouds below).
  final bool tail;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      final midY = (a.dy + b.dy) / 2;
      final segment = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);

      // A segment is "open" once the lesson it leads to is unlocked.
      final open = i + 1 < unlockedCount;

      // Brown outline first, then the colored fill on top.
      canvas.drawPath(
        segment,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = AppSizes.pathWidth + AppSizes.outlineWidth * 2,
      );
      canvas.drawPath(
        segment,
        Paint()
          ..color = open ? AppColors.teal : AppColors.locked
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = AppSizes.pathWidth,
      );
    }

    if (tail && centers.isNotEmpty) {
      final a = centers.last;
      final b = Offset(size.width / 2, size.height);
      final midY = (a.dy + b.dy) / 2;
      final segment = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
      canvas.drawPath(
        segment,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = AppSizes.pathWidth + AppSizes.outlineWidth * 2,
      );
      canvas.drawPath(
        segment,
        Paint()
          ..color = AppColors.locked
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = AppSizes.pathWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.tail != tail ||
      old.unlockedCount != unlockedCount ||
      !_sameOffsets(old.centers, centers);

  static bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
