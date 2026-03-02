import 'dart:math';

import 'package:flutter/material.dart';

import 'color_resolver.dart';
import 'plant_params.dart';

/// CustomPainter for bush-type plants (40-79% completion).
///
/// Anatomy of a real bush: **one short central trunk** emerging from the
/// ground, with **many lateral branches diverging low on the trunk**,
/// creating a dense rounded mound of foliage that starts near ground level.
class BushPainter extends CustomPainter {
  BushPainter({required this.params});

  final GenerationParams params;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.90;

    // Bush dimensions
    final bushW = size.width * 0.52 * s;
    final bushH = size.height * 0.40 * s;

    // Draw aura if short-perfect
    if (params.isShortPerfect) {
      canvas.drawCircle(
        Offset(cx, baseY - bushH * 0.4),
        size.width * 0.3,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
          ..color = const Color(0x30FFD700),
      );
    }

    final colors = ColorResolver.leafGradient(
      morningRatio: params.morningRatio,
      afternoonRatio: params.afternoonRatio,
      eveningRatio: params.eveningRatio,
    );

    // ── 1. Single short trunk from ground ──────────────────
    final trunkH = bushH * (0.25 + rng.nextDouble() * 0.10);
    final trunkW = (2.5 + rng.nextDouble() * 2.0) * s;
    final trunkTopY = baseY - trunkH;

    // Slight lean for natural look
    final lean = (rng.nextDouble() - 0.5) * 4 * s;

    _drawTrunk(canvas, cx, baseY, cx + lean, trunkTopY, trunkW, rng);

    // ── 2. Many lateral branches from low on the trunk ─────
    final numBranches = 10 + rng.nextInt(6); // 10-15 branches
    final branchTips = <Offset>[];

    for (var i = 0; i < numBranches; i++) {
      // Branch origin: along the trunk, concentrated low (70% from bottom half)
      final tFrac = rng.nextDouble() < 0.7
          ? rng.nextDouble() * 0.5 // lower half of trunk
          : 0.5 + rng.nextDouble() * 0.5; // upper half
      final originY = baseY - tFrac * trunkH;
      final originX = cx + lean * tFrac;

      // Fan out radially — spread branches in a wide arc
      final spreadAngle =
          (i / (numBranches - 1) - 0.5) * 2.0; // -1.0 to 1.0
      final baseAngle = -pi / 2 + spreadAngle * 0.85;
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.30;

      final branchLen = bushH * (0.45 + rng.nextDouble() * 0.50);
      final branchW = (1.0 + rng.nextDouble() * 1.5) * s;

      // Tip position
      final tipX = originX + cos(angle) * branchLen * 0.65;
      final tipY = originY + sin(angle) * branchLen;

      // Draw main branch
      _drawThinBranch(canvas, originX, originY, tipX, tipY, branchW, rng);
      branchTips.add(Offset(tipX, tipY));

      // Sub-branches — each main branch forks into 2-3
      final numSub = 2 + rng.nextInt(2);
      for (var j = 0; j < numSub; j++) {
        final subAngle = angle +
            (j - (numSub - 1) / 2) * 0.38 +
            (rng.nextDouble() - 0.5) * 0.18;
        final subLen = branchLen * (0.35 + rng.nextDouble() * 0.30);
        final subTipX = tipX + cos(subAngle) * subLen * 0.5;
        final subTipY = tipY + sin(subAngle) * subLen;

        _drawThinBranch(
            canvas, tipX, tipY, subTipX, subTipY, branchW * 0.55, rng);
        branchTips.add(Offset(subTipX, subTipY));
      }
    }

    // ── 3. Fluffy foliage mound ────────────────────────────
    final moundCY = baseY - bushH * 0.50;
    for (var layer = 0; layer < 4; layer++) {
      final ox = (rng.nextDouble() - 0.5) * bushW * 0.15;
      final oy = (rng.nextDouble() - 0.5) * bushH * 0.1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + ox, moundCY + oy),
          width: bushW * (1.5 + layer * 0.12),
          height: bushH * (0.95 + layer * 0.08),
        ),
        Paint()
          ..color = colors[layer % colors.length]
              .withValues(alpha: 0.12 + l * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // ── 4. Dense fluffy clusters at each branch tip ────────
    for (final tip in branchTips) {
      final clusterR = (8 + rng.nextDouble() * 10 + l * 6) * s;
      _drawFluffyCluster(canvas, tip.dx, tip.dy, clusterR, colors, rng, l);
    }

    // ── 5. Extra fill clusters between tips ────────────────
    final fillCount = (5 + l * 7).round();
    for (var i = 0; i < fillCount; i++) {
      final ox = (rng.nextDouble() - 0.5) * bushW * 1.3;
      final oy = (rng.nextDouble() - 0.6) * bushH * 0.85;
      final clR = (6 + rng.nextDouble() * 8 + l * 4) * s;
      _drawFluffyCluster(canvas, cx + ox, moundCY + oy, clR, colors, rng, l);
    }

    // ── 6. Top highlight layer — brighter puffs ────────────
    final hlCount = (3 + l * 4).round();
    for (var i = 0; i < hlCount; i++) {
      final ox = (rng.nextDouble() - 0.5) * bushW * 1.0;
      final oy = (rng.nextDouble() - 0.7) * bushH * 0.6;
      final r = (5 + rng.nextDouble() * 7) * s;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + ox, moundCY + oy),
          width: r * 2,
          height: r * 1.5,
        ),
        Paint()
          ..color = colors[rng.nextInt(colors.length)]
              .withValues(alpha: 0.15 + rng.nextDouble() * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── 7. Optional small flowers / berries ────────────────
    if (l > 0.5) {
      final berryPaint = Paint()..style = PaintingStyle.fill;
      final berryCount = (3 + l * 6).round();
      for (var i = 0; i < berryCount; i++) {
        final ox = (rng.nextDouble() - 0.5) * bushW * 1.2;
        final oy = (rng.nextDouble() - 0.5) * bushH * 0.7;
        final bx = cx + ox;
        final by = moundCY + oy;
        final br = (1.5 + rng.nextDouble() * 2.5) * s;

        // Small 4-petal flower
        final flowerColor = Color.lerp(
          colors[rng.nextInt(colors.length)],
          const Color(0xFFFFE4B5),
          0.3 + rng.nextDouble() * 0.3,
        )!;

        for (var p = 0; p < 4; p++) {
          final pa = p * pi / 2 + rng.nextDouble() * 0.3;
          berryPaint.color =
              flowerColor.withValues(alpha: 0.4 + rng.nextDouble() * 0.4);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(bx + cos(pa) * br, by + sin(pa) * br),
              width: br * 1.2,
              height: br * 0.8,
            ),
            berryPaint,
          );
        }
        // Center dot
        berryPaint.color = const Color(0xFFFFF176).withValues(alpha: 0.6);
        canvas.drawCircle(Offset(bx, by), br * 0.3, berryPaint);
      }
    }

    // ── 8. Ground shadow ─────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 2 * s),
        width: bushW * 2.2,
        height: 6 * s,
      ),
      Paint()
        ..color = const Color(0x10000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  /// Draws the short central trunk with a tapered bezier shape.
  void _drawTrunk(Canvas canvas, double x1, double y1, double x2, double y2,
      double width, Random rng) {
    final ctrlX = (x1 + x2) / 2 + (rng.nextDouble() - 0.5) * 3;
    final ctrlY = (y1 + y2) / 2;

    // Tapered trunk: wider at bottom, narrower at top
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        ColorResolver.trunkColorDark,
        ColorResolver.trunkColorLight,
        rng.nextDouble() * 0.3,
      )!;

    canvas.drawPath(
      Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(ctrlX, ctrlY, x2, y2),
      paint,
    );

    // Thinner top portion for taper effect
    canvas.drawPath(
      Path()
        ..moveTo((x1 + x2) / 2, (y1 + y2) / 2)
        ..quadraticBezierTo(
            ctrlX + (rng.nextDouble() - 0.5) * 2, ctrlY - 5, x2, y2),
      paint..strokeWidth = width * 0.6,
    );
  }

  /// Draws a thin curved branch via quadratic bezier.
  void _drawThinBranch(Canvas canvas, double x1, double y1, double x2,
      double y2, double width, Random rng) {
    final ctrlX = (x1 + x2) / 2 + (rng.nextDouble() - 0.5) * 12;
    final ctrlY = (y1 + y2) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        ColorResolver.trunkColorDark,
        ColorResolver.trunkColorLight,
        rng.nextDouble() * 0.5,
      )!;

    canvas.drawPath(
      Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(ctrlX, ctrlY, x2, y2),
      paint,
    );
  }

  /// Draws a soft fluffy cluster of overlapping circles/ovals — like a pom-pom.
  void _drawFluffyCluster(Canvas canvas, double cx, double cy, double radius,
      List<Color> colors, Random rng, double lushness) {
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (5 + lushness * 5).round();

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * radius * 0.6;
      final ox = cos(angle) * dist;
      final oy = sin(angle) * dist;
      final r = radius * (0.35 + rng.nextDouble() * 0.45);

      paint.color = colors[rng.nextInt(colors.length)]
          .withValues(alpha: 0.25 + rng.nextDouble() * 0.40);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + ox, cy + oy),
          width: r * (1.3 + rng.nextDouble() * 0.4),
          height: r * (1.0 + rng.nextDouble() * 0.4),
        ),
        paint,
      );
    }

    // Soft blur puff over the whole cluster
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.65,
      Paint()
        ..color = colors[rng.nextInt(colors.length)]
            .withValues(alpha: 0.10 + lushness * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(BushPainter oldDelegate) =>
      params.seed != oldDelegate.params.seed ||
      params.completionPct != oldDelegate.params.completionPct ||
      params.maxStreak != oldDelegate.params.maxStreak;
}
