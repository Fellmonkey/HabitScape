import 'dart:math';

import 'package:flutter/material.dart';

import 'color_resolver.dart';
import 'plant_params.dart';

/// CustomPainter for moss/pebble landscape (0-39% completion).
///
/// Uses fractal techniques for organic, natural-looking results:
/// 1. **Fractal moss** — recursive subdivision creates natural branching textures.
/// 2. **Fractal stones** — subdivision-based polygon shapes with realistic shading.
/// 3. **Lichen patches** — circular fractal growth patterns.
/// 4. **Connecting runners** — organic bezier vines between moss clusters.
class MossPainter extends CustomPainter {
  MossPainter({required this.params});

  final GenerationParams params;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final scale = params.scaleFactor;

    final centerX = size.width / 2;
    final baseY = size.height * 0.85;

    // Draw aura if short-perfect
    if (params.isShortPerfect) {
      canvas.drawCircle(
        Offset(centerX, baseY),
        size.width * 0.25,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
          ..color = const Color(0x25FFD700),
      );
    }

    // ── 1. Fractal stones ────────────────────────────
    _drawFractalStones(canvas, centerX, baseY, size, rng, scale);

    // ── 2. Fractal moss clusters ─────────────────────
    final numClusters =
        (2 + (params.absoluteCompletions * 0.15).round()).clamp(2, 5);
    final centers = <Offset>[];
    for (var i = 0; i < numClusters; i++) {
      final cx = centerX + (rng.nextDouble() - 0.5) * size.width * 0.5;
      final cy = baseY + (rng.nextDouble() - 0.5) * size.height * 0.12;
      centers.add(Offset(cx, cy));
      _drawFractalMoss(canvas, cx, cy, (16 + rng.nextDouble() * 14) * scale,
          0, 3 + (params.absoluteCompletions * 0.1).round().clamp(0, 2), rng, scale);
    }

    // ── 3. Connecting runners ────────────────────────
    _drawRunners(canvas, centers, rng, scale);

    // ── 4. Lichen rings ──────────────────────────────
    _drawLichenPatches(canvas, centerX, baseY, size, rng, scale);

    // ── 5. Sleeping bulb if 0 completions ────────────
    if (params.absoluteCompletions == 0) {
      _drawSleepingBulb(canvas, size, centerX, baseY, scale);
    }
  }

  // ── Fractal moss — recursive branching cluster ─────

  void _drawFractalMoss(Canvas canvas, double cx, double cy, double radius,
      int depth, int maxDepth, Random rng, double scale) {
    if (depth > maxDepth || radius < 2) return;

    // At each level: draw a soft blurred ellipse, then subdivide
    final color = depth.isEven
        ? ColorResolver.mossGreen
        : ColorResolver.mossGreenLight;
    final alpha = 0.15 + (depth / maxDepth) * 0.25 + rng.nextDouble() * 0.10;

    // Soft base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * (1.8 + rng.nextDouble() * 0.4),
        height: radius * (1.2 + rng.nextDouble() * 0.4),
      ),
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(1, 6.0 - depth * 1.5)),
    );

    // Detailed texture at deeper levels
    if (depth >= maxDepth - 1) {
      _drawMossTexture(canvas, cx, cy, radius, rng, scale);
    }

    // Subdivide into 2-4 child clusters
    final nChildren = 2 + rng.nextInt(2);
    for (var i = 0; i < nChildren; i++) {
      final angle = (i / nChildren) * 2 * pi + (rng.nextDouble() - 0.5) * 1.2;
      final dist = radius * (0.5 + rng.nextDouble() * 0.4);
      final childR = radius * (0.45 + rng.nextDouble() * 0.15);
      _drawFractalMoss(
        canvas,
        cx + cos(angle) * dist,
        cy + sin(angle) * dist,
        childR,
        depth + 1,
        maxDepth,
        rng,
        scale,
      );
    }
  }

  /// Fine texture: tiny leaf/frond shapes for organic detail
  void _drawMossTexture(Canvas canvas, double cx, double cy, double radius,
      Random rng, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (4 + params.absoluteCompletions * 0.3).round().clamp(3, 10);

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * radius * 0.8;
      final dx = cx + cos(angle) * dist;
      final dy = cy + sin(angle) * dist;
      final leafAngle = angle + pi + (rng.nextDouble() - 0.5) * 1.0;
      final leafLen = (2 + rng.nextDouble() * 4) * scale;

      final color = Color.lerp(
        ColorResolver.mossGreen,
        ColorResolver.mossGreenLight,
        rng.nextDouble(),
      )!;
      paint.color = color.withValues(alpha: 0.4 + rng.nextDouble() * 0.4);

      // Tiny leaf shape (pointed oval)
      canvas.drawPath(
        Path()
          ..moveTo(dx, dy)
          ..quadraticBezierTo(
            dx + cos(leafAngle - 0.4) * leafLen * 0.6,
            dy + sin(leafAngle - 0.4) * leafLen * 0.6,
            dx + cos(leafAngle) * leafLen,
            dy + sin(leafAngle) * leafLen,
          )
          ..quadraticBezierTo(
            dx + cos(leafAngle + 0.4) * leafLen * 0.6,
            dy + sin(leafAngle + 0.4) * leafLen * 0.6,
            dx,
            dy,
          ),
        paint,
      );
    }

    // Dew highlights
    final hlPaint = Paint()..style = PaintingStyle.fill;
    final hlCount = 1 + rng.nextInt(2);
    for (var i = 0; i < hlCount; i++) {
      final hx = cx + (rng.nextDouble() - 0.5) * radius;
      final hy = cy + (rng.nextDouble() - 0.5) * radius * 0.6;
      hlPaint.color = const Color(0xFFDDFFDD)
          .withValues(alpha: 0.12 + rng.nextDouble() * 0.12);
      canvas.drawCircle(
        Offset(hx, hy),
        (1 + rng.nextDouble() * 1.5) * scale,
        hlPaint,
      );
    }
  }

  // ── Fractal stones — subdivision polygon shapes ────

  void _drawFractalStones(Canvas canvas, double centerX, double baseY,
      Size size, Random rng, double scale) {
    final count =
        (3 + params.absoluteCompletions * 0.4).round().clamp(2, 8);

    for (var i = 0; i < count; i++) {
      final px = centerX + (rng.nextDouble() - 0.5) * size.width * 0.5;
      final py = baseY + (rng.nextDouble() - 0.5) * size.height * 0.10;
      final stoneSize = (8 + rng.nextDouble() * 14) * scale;

      _drawFractalStone(canvas, px, py, stoneSize, rng, scale);
    }
  }

  void _drawFractalStone(Canvas canvas, double cx, double cy, double radius,
      Random rng, double scale) {
    // Generate irregular polygon using angular subdivision
    final numVerts = 6 + rng.nextInt(4);
    final vertices = <Offset>[];
    for (var i = 0; i < numVerts; i++) {
      final baseAngle = (i / numVerts) * 2 * pi;
      final angle = baseAngle + (rng.nextDouble() - 0.5) * (2 * pi / numVerts) * 0.4;
      final r = radius * (0.6 + rng.nextDouble() * 0.4);
      vertices.add(Offset(cx + cos(angle) * r, cy + sin(angle) * r * 0.6));
    }

    // Apply one level of fractal subdivision — midpoint displacement
    final subdivided = <Offset>[];
    for (var i = 0; i < vertices.length; i++) {
      final next = vertices[(i + 1) % vertices.length];
      subdivided.add(vertices[i]);
      final midX = (vertices[i].dx + next.dx) / 2 +
          (rng.nextDouble() - 0.5) * radius * 0.15;
      final midY = (vertices[i].dy + next.dy) / 2 +
          (rng.nextDouble() - 0.5) * radius * 0.10;
      subdivided.add(Offset(midX, midY));
    }

    final stonePath = Path()..moveTo(subdivided.first.dx, subdivided.first.dy);
    for (var i = 1; i < subdivided.length; i++) {
      stonePath.lineTo(subdivided[i].dx, subdivided[i].dy);
    }
    stonePath.close();

    // Shadow
    canvas.save();
    canvas.translate(1.5 * scale, 2.0 * scale);
    canvas.drawPath(
      stonePath,
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

    // Main body with gradient
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: radius * 2, height: radius * 1.4);
    canvas.drawPath(
      stonePath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorResolver.pebbleLight, ColorResolver.pebbleGrey],
        ).createShader(rect),
    );

    // Edge darkening for 3D
    canvas.drawPath(
      stonePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * scale
        ..color = ColorResolver.pebbleGrey.withValues(alpha: 0.3),
    );

    // Inner lighter spot (highlight)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - radius * 0.15, cy - radius * 0.1),
        width: radius * 0.5,
        height: radius * 0.3,
      ),
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Tiny cracks / texture lines
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4 * scale
      ..color = ColorResolver.pebbleGrey.withValues(alpha: 0.25);
    for (var c = 0; c < 2; c++) {
      final sx = cx + (rng.nextDouble() - 0.5) * radius * 0.6;
      final sy = cy + (rng.nextDouble() - 0.5) * radius * 0.3;
      final ex = sx + (rng.nextDouble() - 0.5) * radius * 0.5;
      final ey = sy + (rng.nextDouble() - 0.5) * radius * 0.3;
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), crackPaint);
    }
  }

  // ── Lichen rings — circular fractal-like growth ────

  void _drawLichenPatches(Canvas canvas, double centerX, double baseY,
      Size size, Random rng, double scale) {
    final count = (1 + params.absoluteCompletions * 0.08).round().clamp(0, 3);
    for (var i = 0; i < count; i++) {
      final lx = centerX + (rng.nextDouble() - 0.5) * size.width * 0.45;
      final ly = baseY + (rng.nextDouble() - 0.5) * size.height * 0.08;
      final r = (5 + rng.nextDouble() * 8) * scale;
      _drawLichenRing(canvas, lx, ly, r, rng, scale);
    }
  }

  void _drawLichenRing(Canvas canvas, double cx, double cy, double radius,
      Random rng, double scale) {
    // Soft ring made of overlapping small circles around a center
    final paint = Paint()..style = PaintingStyle.fill;
    final numDots = 8 + rng.nextInt(6);
    for (var i = 0; i < numDots; i++) {
      final angle = (i / numDots) * 2 * pi + (rng.nextDouble() - 0.5) * 0.3;
      final dist = radius * (0.7 + rng.nextDouble() * 0.3);
      final dotR = radius * (0.25 + rng.nextDouble() * 0.2);

      final color = Color.lerp(
        const Color(0xFFC8D89A),
        const Color(0xFFB0C878),
        rng.nextDouble(),
      )!;
      paint.color = color.withValues(alpha: 0.20 + rng.nextDouble() * 0.15);

      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        dotR,
        paint,
      );
    }

    // Center darker spot
    paint.color = const Color(0xFF8B9B6B).withValues(alpha: 0.15);
    canvas.drawCircle(Offset(cx, cy), radius * 0.3, paint);
  }

  // ── Connecting runners — organic bezier vines ──────

  void _drawRunners(
      Canvas canvas, List<Offset> centers, Random rng, double scale) {
    if (centers.length < 2) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.6 + rng.nextDouble() * 0.5) * scale
      ..strokeCap = StrokeCap.round
      ..color = ColorResolver.mossGreen.withValues(alpha: 0.20);

    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      final midX = (a.dx + b.dx) / 2 + (rng.nextDouble() - 0.5) * 18 * scale;
      final midY = (a.dy + b.dy) / 2 + (rng.nextDouble() - 0.5) * 10 * scale;

      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(midX, midY, b.dx, b.dy),
        paint,
      );

      // Tiny leaf sprouts along the runner
      final leafPaint = Paint()..style = PaintingStyle.fill;
      for (var t = 0.2; t < 0.85; t += 0.2 + rng.nextDouble() * 0.15) {
        final u = 1 - t;
        final px = u * u * a.dx + 2 * u * t * midX + t * t * b.dx;
        final py = u * u * a.dy + 2 * u * t * midY + t * t * b.dy;
        final leafAngle = rng.nextDouble() * 2 * pi;
        final leafLen = (2 + rng.nextDouble() * 3) * scale;

        leafPaint.color = ColorResolver.mossGreenLight
            .withValues(alpha: 0.25 + rng.nextDouble() * 0.20);
        canvas.drawPath(
          Path()
            ..moveTo(px, py)
            ..quadraticBezierTo(
              px + cos(leafAngle - 0.3) * leafLen * 0.6,
              py + sin(leafAngle - 0.3) * leafLen * 0.6,
              px + cos(leafAngle) * leafLen,
              py + sin(leafAngle) * leafLen,
            )
            ..quadraticBezierTo(
              px + cos(leafAngle + 0.3) * leafLen * 0.6,
              py + sin(leafAngle + 0.3) * leafLen * 0.6,
              px,
              py,
            ),
          leafPaint,
        );
      }
    }
  }

  // ── Sleeping bulb ────────────────────────────────

  void _drawSleepingBulb(
      Canvas canvas, Size size, double cx, double cy, double scale) {
    // Bulb body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 6 * scale),
        width: 20 * scale,
        height: 28 * scale,
      ),
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF9E8B7E),
    );

    // Subtle shading on bulb
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 3 * scale, cy - 10 * scale),
        width: 8 * scale,
        height: 14 * scale,
      ),
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x18FFFFFF),
    );

    // Tiny sprout tip
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - 20 * scale)
        ..quadraticBezierTo(
          cx + 4 * scale,
          cy - 30 * scale,
          cx + 2 * scale,
          cy - 36 * scale,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round
        ..color = ColorResolver.mossGreen.withValues(alpha: 0.5),
    );

    // Small leaf at sprout tip
    final leafColor = ColorResolver.mossGreen.withValues(alpha: 0.4);
    canvas.drawPath(
      Path()
        ..moveTo(cx + 2 * scale, cy - 36 * scale)
        ..quadraticBezierTo(
          cx + 7 * scale,
          cy - 40 * scale,
          cx + 5 * scale,
          cy - 34 * scale,
        ),
      Paint()
        ..style = PaintingStyle.fill
        ..color = leafColor,
    );
  }

  @override
  bool shouldRepaint(MossPainter oldDelegate) =>
      params.seed != oldDelegate.params.seed ||
      params.absoluteCompletions != oldDelegate.params.absoluteCompletions;
}
