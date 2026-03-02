import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/database/enums.dart';
import 'color_resolver.dart';
import 'plant_params.dart';

/// CustomPainter that renders trees using archetype-specific algorithms.
///
/// Each archetype uses a dedicated drawing method to produce a truly
/// distinct visual form:
/// - **Oak** — recursive fractal branching, wide dome canopy
/// - **Sakura** — curved bezier branches, pink blossom clusters, petals
/// - **Pine** — layered triangular tiers on a straight trunk
/// - **Willow** — upward branches with cascading drooping strands
/// - **Baobab** — massive bottle-shaped trunk (bezier outline)
/// - **Palm** — curved trunk with ring marks + radiating fronds
class TreePainter extends CustomPainter {
  TreePainter({required this.params});

  final GenerationParams params;

  // ────────────────────────────────────────────────────────────
  // Dispatch
  // ────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    if (params.isShortPerfect) _drawAura(canvas, size);

    switch (params.archetype) {
      case SeedArchetype.oak:
        _paintOak(canvas, size);
      case SeedArchetype.sakura:
        _paintSakura(canvas, size);
      case SeedArchetype.pine:
        _paintPine(canvas, size);
      case SeedArchetype.willow:
        _paintWillow(canvas, size);
      case SeedArchetype.baobab:
        _paintBaobab(canvas, size);
      case SeedArchetype.palm:
        _paintPalm(canvas, size);
    }
  }

  @override
  bool shouldRepaint(TreePainter old) =>
      params.seed != old.params.seed ||
      params.completionPct != old.params.completionPct ||
      params.maxStreak != old.params.maxStreak ||
      params.archetype != old.params.archetype;

  // ────────────────────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────────────────────

  List<Color> get _leafColors => ColorResolver.leafGradient(
        morningRatio: params.morningRatio,
        afternoonRatio: params.afternoonRatio,
        eveningRatio: params.eveningRatio,
      );

  /// Tapered branch segment rendered as a filled trapezoid — looks far more
  /// natural than a constant-width stroke.
  void _drawTaperedBranch(
    Canvas canvas,
    double x1, double y1,
    double x2, double y2,
    double w1, double w2,
    Color color,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.5) return;

    final nx = -dy / len;
    final ny = dx / len;

    final path = Path()
      ..moveTo(x1 + nx * w1 / 2, y1 + ny * w1 / 2)
      ..lineTo(x2 + nx * w2 / 2, y2 + ny * w2 / 2)
      ..lineTo(x2 - nx * w2 / 2, y2 - ny * w2 / 2)
      ..lineTo(x1 - nx * w1 / 2, y1 - ny * w1 / 2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  /// Horizontal bark-texture lines across a segment.
  void _drawBarkLines(Canvas canvas, double x1, double y1, double x2,
      double y2, double width, Random rng) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.25);

    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 5) return;

    final nx = -dy / len;
    final ny = dx / len;

    final n = (len / 8).round().clamp(2, 12);
    for (var i = 0; i < n; i++) {
      final t = (i + 0.5) / n;
      final mx = x1 + dx * t;
      final my = y1 + dy * t;
      final w = width * (1 - t * 0.35) * 0.35;
      canvas.drawLine(
        Offset(mx + nx * w, my + ny * w),
        Offset(mx - nx * w, my - ny * w),
        paint,
      );
    }
  }

  /// Overlapping soft ovals forming a leaf cluster.
  void _drawLeafCluster(Canvas canvas, double cx, double cy, double radius,
      Color color, Random rng, int count) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final ox = (rng.nextDouble() - 0.5) * radius * 1.4;
      final oy = (rng.nextDouble() - 0.5) * radius * 1.2;
      final r = radius * (0.4 + rng.nextDouble() * 0.5);
      paint.color = color.withValues(alpha: 0.45 + rng.nextDouble() * 0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + ox, cy + oy),
          width: r * 2,
          height: r * (1.2 + rng.nextDouble() * 0.6),
        ),
        paint,
      );
    }
  }

  void _drawAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..shader = ui.Gradient.radial(
        center,
        size.width * 0.35,
        [const Color(0x40FFD700), const Color(0x00FFD700)],
      );
    canvas.drawCircle(center, size.width * 0.35, glowPaint);
  }

  /// Trunk drawn as a chain of small tapered segments following a
  /// quadratic bezier — gives a natural curve.
  void _drawCurvedTrunk(Canvas canvas, double x1, double y1, double x2,
      double y2, double width, Random rng,
      {double curveAmount = 1.0}) {
    const segs = 10;
    final ctrlX =
        (x1 + x2) / 2 + (rng.nextDouble() - 0.5) * width * curveAmount * 2;
    final ctrlY = (y1 + y2) / 2;

    for (var i = 0; i < segs; i++) {
      final t1 = i / segs;
      final t2 = (i + 1) / segs;
      final px1 = _qBez(x1, ctrlX, x2, t1);
      final py1 = _qBez(y1, ctrlY, y2, t1);
      final px2 = _qBez(x1, ctrlX, x2, t2);
      final py2 = _qBez(y1, ctrlY, y2, t2);

      final w1 = width * (1 - t1 * 0.4);
      final w2 = width * (1 - t2 * 0.4);
      _drawTaperedBranch(
        canvas, px1, py1, px2, py2, w1, w2,
        Color.lerp(ColorResolver.trunkColorDark, ColorResolver.trunkColorLight,
            t1 * 0.4)!,
      );
    }
  }

  // ── Bezier helpers ─────────────────────────────────

  double _qBez(double p0, double p1, double p2, double t) =>
      (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;

  double _qBezDeriv(double p0, double p1, double p2, double t) =>
      2 * (1 - t) * (p1 - p0) + 2 * t * (p2 - p1);

  double _cBez(double p0, double p1, double p2, double p3, double t) {
    final u = 1 - t;
    return u * u * u * p0 +
        3 * u * u * t * p1 +
        3 * u * t * t * p2 +
        t * t * t * p3;
  }

  // ══════════════════════════════════════════════════════════
  //  OAK — recursive fractal branching, wide dome canopy
  // ══════════════════════════════════════════════════════════

  void _paintOak(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final trunkH = size.height * 0.28 * s;
    final trunkW = 14.0 * s;

    final topX = cx + (rng.nextDouble() - 0.5) * 8 * s;
    final topY = baseY - trunkH;

    // Trunk with mild natural curve
    _drawCurvedTrunk(canvas, cx, baseY, topX, topY, trunkW, rng);
    _drawBarkLines(canvas, cx, baseY, topX, topY, trunkW, rng);

    // Exposed roots
    _drawRoots(canvas, cx, baseY, trunkW, rng, s);

    // Collect leaf tip positions via recursive branching
    final tips = <Offset>[];
    final numMajor = 4 + rng.nextInt(3);
    for (var i = 0; i < numMajor; i++) {
      final a = -pi / 2 +
          (i - (numMajor - 1) / 2) * 0.5 +
          (rng.nextDouble() - 0.5) * 0.18;
      _oakBranch(canvas, topX, topY, a, trunkH * 0.6, trunkW * 0.50, 0,
          4 + (l * 2).round(), rng, s, tips);
    }

    // Draw dome canopy from collected leaf tips
    final leafR = (12.0 + l * 18.0) * s;
    final colors = _leafColors;

    // Base canopy dome — large soft blurred mass for fullness
    if (tips.isNotEmpty) {
      double minX = tips.first.dx, maxX = tips.first.dx;
      double minY = tips.first.dy, maxY = tips.first.dy;
      for (final t in tips) {
        if (t.dx < minX) minX = t.dx;
        if (t.dx > maxX) maxX = t.dx;
        if (t.dy < minY) minY = t.dy;
        if (t.dy > maxY) maxY = t.dy;
      }
      final domeCX = (minX + maxX) / 2;
      final domeCY = (minY + maxY) / 2;
      final domeW = (maxX - minX) + leafR * 3;
      final domeH = (maxY - minY) + leafR * 2.5;

      // Soft blurred base dome
      for (var layer = 0; layer < 3; layer++) {
        final ox = (rng.nextDouble() - 0.5) * leafR * 0.5;
        final oy = (rng.nextDouble() - 0.5) * leafR * 0.3;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(domeCX + ox, domeCY + oy),
            width: domeW * (0.85 + layer * 0.08),
            height: domeH * (0.80 + layer * 0.1),
          ),
          Paint()
            ..color = colors[layer % colors.length].withValues(alpha: 0.18 + l * 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }

    // Detail leaf clusters at each branch tip
    for (final tip in tips) {
      final c = colors[rng.nextInt(colors.length)];
      _drawLeafCluster(
          canvas, tip.dx, tip.dy, leafR, c, rng, (4 + l * 4).round());
    }

    // Extra mid-canopy fill clusters for density
    if (tips.length >= 2) {
      for (var i = 0; i < tips.length - 1; i++) {
        final mx = (tips[i].dx + tips[i + 1].dx) / 2 + (rng.nextDouble() - 0.5) * leafR * 0.4;
        final my = (tips[i].dy + tips[i + 1].dy) / 2 + (rng.nextDouble() - 0.5) * leafR * 0.3;
        final c = colors[rng.nextInt(colors.length)];
        _drawLeafCluster(canvas, mx, my, leafR * 0.8, c, rng, (3 + l * 2).round());
      }
    }

    // Soft shadow under canopy
    if (tips.isNotEmpty) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, topY + 4 * s),
          width: leafR * 5,
          height: leafR * 1.8,
        ),
        Paint()
          ..color = const Color(0x14000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _oakBranch(Canvas canvas, double x, double y, double angle,
      double length, double thick, int depth, int maxD, Random rng, double s,
      List<Offset> tips) {
    if (depth >= maxD || thick < 0.8) return;

    final a = angle + (rng.nextDouble() - 0.5) * 0.15;
    final len = length * (0.90 + (rng.nextDouble() - 0.5) * 0.1);
    final ex = x + cos(a) * len;
    final ey = y + sin(a) * len;

    final c = Color.lerp(ColorResolver.trunkColorDark,
        ColorResolver.trunkColorLight, (depth / maxD).clamp(0.0, 0.8))!;
    _drawTaperedBranch(canvas, x, y, ex, ey, thick, thick * 0.62, c);

    // Collect tips from deeper levels for denser canopy
    if (depth >= maxD - 3) tips.add(Offset(ex, ey));

    // Gnarled knot at fork
    if (depth >= 1 && depth < maxD - 1 && rng.nextDouble() > 0.6) {
      canvas.drawCircle(
        Offset(ex, ey),
        thick * 0.38,
        Paint()
          ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }

    final nc = depth < 2 ? 2 + rng.nextInt(2) : 2 + rng.nextInt(2);
    for (var i = 0; i < nc; i++) {
      final ca = a + (i - (nc - 1) / 2) * (0.42 + rng.nextDouble() * 0.22);
      _oakBranch(canvas, ex, ey, ca, length * (0.55 + rng.nextDouble() * 0.12),
          thick * (0.52 + rng.nextDouble() * 0.1), depth + 1, maxD, rng, s, tips);
    }
  }

  void _drawRoots(Canvas canvas, double cx, double baseY, double trunkW,
      Random rng, double scale) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.50);

    final numRoots = 3 + rng.nextInt(3);
    for (var i = 0; i < numRoots; i++) {
      final side = rng.nextBool() ? -1.0 : 1.0;
      paint.strokeWidth = trunkW * (0.12 + rng.nextDouble() * 0.12);
      final rootLen = trunkW * (0.8 + rng.nextDouble() * 1.2);
      final path = Path()
        ..moveTo(cx + side * trunkW * 0.15, baseY)
        ..quadraticBezierTo(
          cx + side * rootLen * 0.6,
          baseY + rootLen * 0.15,
          cx + side * rootLen,
          baseY + rootLen * 0.04,
        );
      canvas.drawPath(path, paint);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  SAKURA — curved bezier branches, cherry blossoms, petals
  // ══════════════════════════════════════════════════════════

  void _paintSakura(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final trunkH = size.height * 0.32 * s;
    final trunkW = 10.0 * s;

    // Slightly leaning trunk
    final lean = (rng.nextDouble() - 0.5) * 14 * s;
    final topX = cx + lean;
    final topY = baseY - trunkH;
    _drawCurvedTrunk(canvas, cx, baseY, topX, topY, trunkW, rng);

    final blossomPts = <Offset>[];

    // Many graceful curved branches spreading wide — reaching to the horizon
    final nb = 5 + rng.nextInt(4); // 5-8 main branches (was 3-5)
    for (var i = 0; i < nb; i++) {
      // Wider angular spread so branches reach far left/right
      final a = -pi / 2 +
          (i - (nb - 1) / 2) * 0.55 +
          (rng.nextDouble() - 0.5) * 0.2;
      _sakuraBranch(canvas, topX, topY, a, trunkH * 0.65, trunkW * 0.38, 0,
          4 + (l * 2).round(), rng, s, blossomPts);
    }

    // Draw big dense blossom clusters at all collected positions
    for (final p in blossomPts) {
      _drawBlossomCluster(canvas, p.dx, p.dy, (7 + l * 12) * s, rng);
    }

    // NO falling petals — only attached blossoms on branches
  }

  void _sakuraBranch(Canvas canvas, double x, double y, double angle,
      double length, double thick, int depth, int maxD, Random rng, double s,
      List<Offset> blossoms) {
    if (depth >= maxD || thick < 0.6) return;

    // Curved segment via two halves with curve offset
    final curve = (rng.nextDouble() - 0.5) * 0.3;
    final midA = angle + curve;
    final midX = x + cos(midA) * length * 0.5;
    final midY = y + sin(midA) * length * 0.5;
    final endA = angle + curve * 0.4;
    final ex = midX + cos(endA) * length * 0.5;
    final ey = midY + sin(endA) * length * 0.5;

    final c = Color.lerp(ColorResolver.trunkColorDark,
        const Color(0xFF8B7355), (depth / maxD).clamp(0.0, 1.0))!;
    _drawTaperedBranch(canvas, x, y, midX, midY, thick, thick * 0.8, c);
    _drawTaperedBranch(
        canvas, midX, midY, ex, ey, thick * 0.8, thick * 0.55, c);

    // Add blossoms along ALL branch segments — lots of flowers on each
    if (depth >= 1) {
      blossoms.add(Offset(ex, ey));
      blossoms.add(Offset(midX, midY));
      // Multiple intermediate points for maximum density
      final ix1 = (x + midX) / 2 + (rng.nextDouble() - 0.5) * 4;
      final iy1 = (y + midY) / 2 + (rng.nextDouble() - 0.5) * 4;
      blossoms.add(Offset(ix1, iy1));
      if (depth >= maxD - 2) {
        final ix2 = (midX + ex) / 2 + (rng.nextDouble() - 0.5) * 4;
        final iy2 = (midY + ey) / 2 + (rng.nextDouble() - 0.5) * 4;
        blossoms.add(Offset(ix2, iy2));
      }
    }

    // More child branches for denser canopy
    final nc = 2 + rng.nextInt(2); // 2-3 children (was 1-2)
    for (var i = 0; i < nc; i++) {
      final ca =
          endA + (i - (nc - 1) / 2) * 0.45 + (rng.nextDouble() - 0.5) * 0.2;
      _sakuraBranch(canvas, ex, ey, ca,
          length * (0.58 + rng.nextDouble() * 0.1), thick * 0.52,
          depth + 1, maxD, rng, s, blossoms);
    }
  }

  void _drawBlossomCluster(
      Canvas canvas, double cx, double cy, double size, Random rng) {
    final paint = Paint()..style = PaintingStyle.fill;
    final count = 4 + rng.nextInt(5);

    for (var i = 0; i < count; i++) {
      final ox = (rng.nextDouble() - 0.5) * size * 0.9;
      final oy = (rng.nextDouble() - 0.5) * size * 0.9;
      final r = size * (0.18 + rng.nextDouble() * 0.28);

      final petalColor = Color.lerp(
        const Color(0xFFFFB7C5),
        const Color(0xFFFFE4EC),
        rng.nextDouble(),
      )!;

      // 5-petal flower: overlapping rotated ovals
      final fc = Offset(cx + ox, cy + oy);
      for (var p = 0; p < 5; p++) {
        final pa = p * (2 * pi / 5) + rng.nextDouble() * 0.3;
        final pr = r * 0.45;
        paint.color =
            petalColor.withValues(alpha: 0.40 + rng.nextDouble() * 0.45);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fc.dx + cos(pa) * pr, fc.dy + sin(pa) * pr),
            width: r * 0.7,
            height: r * 0.5,
          ),
          paint,
        );
      }
      // Yellow stamen center
      paint.color = const Color(0xFFFFF176).withValues(alpha: 0.65);
      canvas.drawCircle(fc, r * 0.12, paint);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  PINE — long exposed trunk with tiered horizontal branches + needle pairs
  // ══════════════════════════════════════════════════════════

  void _paintPine(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final treeH = size.height * 0.72 * s;
    final trunkW = 7.0 * s;
    final topY = baseY - treeH;

    // Long straight trunk — exposed for ~60% of height
    _drawTaperedBranch(canvas, cx, baseY, cx, topY, trunkW, trunkW * 0.40,
        ColorResolver.trunkColorDark);
    _drawBarkLines(canvas, cx, baseY, cx, topY, trunkW, rng);

    // Crown starts at ~40% from top
    final crownBottom = baseY - treeH * 0.35;
    final crownTop = topY + treeH * 0.02;
    final numTiers = (4 + l * 4).round();
    final colors = _leafColors;

    for (var tier = 0; tier < numTiers; tier++) {
      final t = tier / (numTiers - 1).clamp(1, numTiers);
      final tierY = crownBottom + (crownTop - crownBottom) * t;

      final maxBranchLen = treeH * (0.18 + l * 0.08) * (1 - t * 0.65) * s;
      final branchThick = (3.0 + rng.nextDouble() * 2) * s * (1 - t * 0.4);

      // Slight upward angle, more horizontal than fir
      final leftAngle = pi + 0.15 + (rng.nextDouble() - 0.5) * 0.2;
      final rightAngle = -0.15 + (rng.nextDouble() - 0.5) * 0.2;

      // Left branch
      final lLen = maxBranchLen * (0.75 + rng.nextDouble() * 0.25);
      final lx = cx + cos(leftAngle) * lLen;
      final ly = tierY + sin(leftAngle) * lLen;
      final branchColor = Color.lerp(
          ColorResolver.trunkColorDark, ColorResolver.trunkColorLight, 0.3 + t * 0.3)!;
      _drawTaperedBranch(canvas, cx, tierY, lx, ly,
          branchThick, branchThick * 0.3, branchColor);

      // Right branch
      final rLen = maxBranchLen * (0.75 + rng.nextDouble() * 0.25);
      final rx = cx + cos(rightAngle) * rLen;
      final ry = tierY + sin(rightAngle) * rLen;
      _drawTaperedBranch(canvas, cx, tierY, rx, ry,
          branchThick, branchThick * 0.3, branchColor);

      // Needle pairs along left branch (feathery, like palm leaflets)
      _drawPineNeedles(canvas, cx, tierY, lx, ly, lLen, colors, rng, s, l);
      // Needle pairs along right branch
      _drawPineNeedles(canvas, cx, tierY, rx, ry, rLen, colors, rng, s, l);
    }

    // Small tuft at very top
    final topColor = colors[0].withValues(alpha: 0.7);
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + (i - 1) * 0.4 + (rng.nextDouble() - 0.5) * 0.2;
      final tLen = treeH * 0.04 * s;
      _drawPineNeedles(
        canvas, cx, crownTop,
        cx + cos(a) * tLen, crownTop + sin(a) * tLen,
        tLen, colors, rng, s, l,
      );
      canvas.drawLine(
        Offset(cx, crownTop),
        Offset(cx + cos(a) * tLen, crownTop + sin(a) * tLen),
        Paint()
          ..color = topColor
          ..strokeWidth = 1.5 * s
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Feathery needle pairs along a pine branch segment.
  void _drawPineNeedles(Canvas canvas, double x1, double y1, double x2,
      double y2, double branchLen, List<Color> colors, Random rng, double s, double l) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 2) return;

    final spineAngle = atan2(dy, dx);
    final numPairs = (6 + l * 6).round();
    final needlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i <= numPairs; i++) {
      final t = i / (numPairs + 1);
      final px = x1 + dx * t;
      final py = y1 + dy * t;
      final needleLen = branchLen * 0.18 * (1.0 - t * 0.45) * s;

      needlePaint.color = colors[rng.nextInt(colors.length)]
          .withValues(alpha: 0.35 + rng.nextDouble() * 0.45);

      // Left needle
      final la = spineAngle - pi / 2 + 0.2 + (rng.nextDouble() - 0.5) * 0.2;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + cos(la) * needleLen, py + sin(la) * needleLen),
        needlePaint,
      );
      // Right needle
      final ra = spineAngle + pi / 2 - 0.2 + (rng.nextDouble() - 0.5) * 0.2;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + cos(ra) * needleLen, py + sin(ra) * needleLen),
        needlePaint,
      );
    }

    // Soft green cluster at branch tip for fullness
    final tipColor = colors[rng.nextInt(colors.length)];
    final clusterR = branchLen * 0.12 * s;
    for (var i = 0; i < 3; i++) {
      final ox = (rng.nextDouble() - 0.5) * clusterR;
      final oy = (rng.nextDouble() - 0.5) * clusterR;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x2 + ox, y2 + oy),
          width: clusterR * (1.2 + rng.nextDouble() * 0.5),
          height: clusterR * (0.8 + rng.nextDouble() * 0.4),
        ),
        Paint()
          ..color = tipColor.withValues(alpha: 0.25 + rng.nextDouble() * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  //  WILLOW — cascading curtain of drooping strands
  // ══════════════════════════════════════════════════════════

  void _paintWillow(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final trunkH = size.height * 0.30 * s;
    final trunkW = 10.0 * s;

    final topX = cx + (rng.nextDouble() - 0.5) * 6 * s;
    final topY = baseY - trunkH;

    _drawCurvedTrunk(canvas, cx, baseY, topX, topY, trunkW, rng);
    _drawBarkLines(canvas, cx, baseY, topX, topY, trunkW, rng);

    // Wide multi-tier branches — three levels for wide dramatic cascade
    final branchTiers = [
      (y: topY, len: trunkH * 0.70, count: 7 + rng.nextInt(3)),
      (y: topY + trunkH * 0.12, len: trunkH * 0.55, count: 6 + rng.nextInt(3)),
      (y: topY + trunkH * 0.25, len: trunkH * 0.40, count: 4 + rng.nextInt(2)),
    ];

    for (final tier in branchTiers) {
      for (var i = 0; i < tier.count; i++) {
        // Much wider angular spread for a broad silhouette
        final angle = -pi / 2 +
            (i - (tier.count - 1) / 2) * 0.70 +
            (rng.nextDouble() - 0.5) * 0.20;
        final bLen = tier.len * (0.65 + rng.nextDouble() * 0.35);
        final bx = topX + cos(angle) * bLen;
        final by = tier.y + sin(angle) * bLen;
        final bThick = trunkW * (0.22 + rng.nextDouble() * 0.12);

        _drawTaperedBranch(canvas, topX, tier.y, bx, by, bThick, bThick * 0.4,
            ColorResolver.trunkColorLight);

        // More strands per branch
        final ns = (4 + l * 6).round();
        for (var j = 0; j < ns; j++) {
          _drawWillowStrand(canvas, bx, by, rng, s, l);
        }
      }
    }
  }

  void _drawWillowStrand(Canvas canvas, double sx, double sy, Random rng,
      double scale, double lushness) {
    final colors = _leafColors;
    final strandLen = (50 + rng.nextDouble() * 90) * scale; // much longer
    final swayX = (rng.nextDouble() - 0.5) * 80 * scale; // much wider sway

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.8 + rng.nextDouble() * 0.8) * scale
      ..strokeCap = StrokeCap.round
      ..color = colors[rng.nextInt(colors.length)]
          .withValues(alpha: 0.22 + rng.nextDouble() * 0.35);

    canvas.drawPath(
      Path()
        ..moveTo(sx, sy)
        ..cubicTo(
          sx + swayX * 0.3,
          sy + strandLen * 0.25,
          sx + swayX * 0.8,
          sy + strandLen * 0.65,
          sx + swayX * 0.7,
          sy + strandLen,
        ),
      paint,
    );

    // Small oval leaves along the strand
    if (lushness > 0.4) {
      final leafPaint = Paint()..style = PaintingStyle.fill;
      final nl = (2 + lushness * 4).round();
      for (var k = 0; k < nl; k++) {
        final t = (k + 1) / (nl + 1);
        final lx = sx + swayX * t * 0.7 + (rng.nextDouble() - 0.5) * 3;
        final ly = sy + strandLen * t;
        leafPaint.color = colors[rng.nextInt(colors.length)]
            .withValues(alpha: 0.30 + rng.nextDouble() * 0.40);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(lx, ly),
            width: 3 * scale,
            height: 5.5 * scale,
          ),
          leafPaint,
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  //  BAOBAB — massive bottle-shaped trunk, stubby crown
  // ══════════════════════════════════════════════════════════

  void _paintBaobab(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final treeH = size.height * 0.62 * s;
    final topY = baseY - treeH;

    final baseW = 22.0 * s;
    final bulgeW = 32.0 * s;
    final topW = 15.0 * s;
    final bulgeY = baseY - treeH * 0.42;

    // Build bottle-shaped trunk outline (cubic bezier silhouette)
    final trunkPath = Path();

    // Left edge
    trunkPath.moveTo(cx - baseW / 2, baseY);
    trunkPath.cubicTo(
      cx - baseW / 2 - 3 * s, baseY - treeH * 0.18,
      cx - bulgeW / 2, bulgeY + treeH * 0.12,
      cx - bulgeW / 2, bulgeY,
    );
    trunkPath.cubicTo(
      cx - bulgeW / 2, bulgeY - treeH * 0.14,
      cx - topW / 2 - 2 * s, topY + treeH * 0.1,
      cx - topW / 2, topY,
    );

    trunkPath.lineTo(cx + topW / 2, topY);

    // Right edge (mirror)
    trunkPath.cubicTo(
      cx + topW / 2 + 2 * s, topY + treeH * 0.1,
      cx + bulgeW / 2, bulgeY - treeH * 0.14,
      cx + bulgeW / 2, bulgeY,
    );
    trunkPath.cubicTo(
      cx + bulgeW / 2, bulgeY + treeH * 0.12,
      cx + baseW / 2 + 3 * s, baseY - treeH * 0.18,
      cx + baseW / 2, baseY,
    );
    trunkPath.close();

    // Gradient fill for 3D roundness
    canvas.drawPath(
      trunkPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(cx - bulgeW / 2, 0),
          Offset(cx + bulgeW / 2, 0),
          [
            ColorResolver.trunkColorDark,
            ColorResolver.trunkColorLight,
            ColorResolver.trunkColorLight,
            ColorResolver.trunkColorDark,
          ],
          [0.0, 0.35, 0.65, 1.0],
        ),
    );

    // Subtle outline
    canvas.drawPath(
      trunkPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.30),
    );

    // Horizontal bark creases
    final barkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.18);
    for (var i = 0; i < 10; i++) {
      final t = 0.08 + i * 0.08;
      final ly = baseY - treeH * t;
      final halfW = _baobabHalfWidth(t, baseW, bulgeW, topW) * 0.82;
      final waviness = (rng.nextDouble() - 0.5) * 3 * s;
      canvas.drawLine(
        Offset(cx - halfW + waviness, ly),
        Offset(cx + halfW - waviness, ly),
        barkPaint,
      );
    }

    // Denser crown branches
    final nb = 7 + rng.nextInt(4);
    final colors = _leafColors;
    final crownTips = <Offset>[];

    for (var i = 0; i < nb; i++) {
      final angle = -pi / 2 +
          (i - (nb - 1) / 2) * 0.45 +
          (rng.nextDouble() - 0.5) * 0.3;
      final bLen = treeH * (0.08 + rng.nextDouble() * 0.10);
      final bStartX = cx + (rng.nextDouble() - 0.5) * topW * 0.5;
      final bx = bStartX + cos(angle) * bLen;
      final by = topY + sin(angle) * bLen;
      final bThick = (3.5 + rng.nextDouble() * 3) * s;

      _drawTaperedBranch(canvas, bStartX, topY, bx, by, bThick,
          bThick * 0.35, ColorResolver.trunkColorLight);
      crownTips.add(Offset(bx, by));
    }

    // Large soft dome canopy over the crown
    if (crownTips.isNotEmpty) {
      double minXT = crownTips.first.dx, maxXT = crownTips.first.dx;
      double minYT = crownTips.first.dy, maxYT = crownTips.first.dy;
      for (final t in crownTips) {
        if (t.dx < minXT) minXT = t.dx;
        if (t.dx > maxXT) maxXT = t.dx;
        if (t.dy < minYT) minYT = t.dy;
        if (t.dy > maxYT) maxYT = t.dy;
      }
      final domeCX = (minXT + maxXT) / 2;
      final domeCY = (minYT + maxYT) / 2 - 4 * s;
      final domeW = (maxXT - minXT) + 30 * s;
      final domeH = (maxYT - minYT) + 25 * s;

      // Blurred background canopy layers
      for (var layer = 0; layer < 3; layer++) {
        final ox = (rng.nextDouble() - 0.5) * 5 * s;
        final oy = (rng.nextDouble() - 0.5) * 3 * s;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(domeCX + ox, domeCY + oy),
            width: domeW * (0.9 + layer * 0.1),
            height: domeH * (0.85 + layer * 0.1),
          ),
          Paint()
            ..color = colors[layer % colors.length].withValues(alpha: 0.18 + l * 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // Detail leaf clusters at each branch tip
    for (final tip in crownTips) {
      final clR = (8 + l * 12) * s;
      _drawLeafCluster(canvas, tip.dx, tip.dy, clR,
          colors[rng.nextInt(colors.length)], rng, (3 + l * 3).round());
    }

    // Fill clusters between tips for density
    if (crownTips.length >= 2) {
      for (var i = 0; i < crownTips.length - 1; i++) {
        final mx = (crownTips[i].dx + crownTips[i + 1].dx) / 2;
        final my = (crownTips[i].dy + crownTips[i + 1].dy) / 2;
        final clR = (6 + l * 8) * s;
        _drawLeafCluster(canvas, mx, my, clR,
            colors[rng.nextInt(colors.length)], rng, (2 + l * 2).round());
      }
    }
  }

  double _baobabHalfWidth(
      double t, double baseW, double bulgeW, double topW) {
    if (t < 0.42) {
      final lt = t / 0.42;
      return (baseW + (bulgeW - baseW) * sin(lt * pi / 2)) / 2;
    } else {
      final lt = (t - 0.42) / 0.58;
      return (bulgeW + (topW - bulgeW) * lt) / 2;
    }
  }

  // ══════════════════════════════════════════════════════════
  //  PALM — curved trunk with rings, crown of radiating fronds
  // ══════════════════════════════════════════════════════════

  void _paintPalm(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final s = params.scaleFactor;
    final l = params.lushness;

    final cx = size.width / 2;
    final baseY = size.height * 0.88;
    final treeH = size.height * 0.68 * s;
    final topY = baseY - treeH;

    // S-curve trunk via cubic bezier
    final curve1 = (rng.nextDouble() - 0.5) * 28 * s;
    final curve2 = -curve1 * 0.55;

    final trunkPts = <Offset>[];
    const numSegs = 18;
    for (var i = 0; i <= numSegs; i++) {
      final t = i / numSegs;
      final px =
          _cBez(cx, cx + curve1, cx + curve2, cx + curve1 * 0.25, t);
      final py =
          _cBez(baseY, baseY - treeH * 0.28, baseY - treeH * 0.72, topY, t);
      trunkPts.add(Offset(px, py));
    }

    // Draw trunk segments with taper
    final trunkW = 9.0 * s;
    for (var i = 0; i < trunkPts.length - 1; i++) {
      final t = i / trunkPts.length;
      final w1 = trunkW * (1 - t * 0.55);
      final w2 = trunkW * (1 - (t + 1 / trunkPts.length) * 0.55);
      _drawTaperedBranch(
        canvas, trunkPts[i].dx, trunkPts[i].dy,
        trunkPts[i + 1].dx, trunkPts[i + 1].dy, w1, w2,
        Color.lerp(
            ColorResolver.trunkColorDark, const Color(0xFFA8946D), t)!,
      );
    }

    // Ring marks
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = ColorResolver.trunkColorDark.withValues(alpha: 0.30);
    for (var i = 2; i < trunkPts.length - 1; i += 2) {
      final p = trunkPts[i];
      final t = i / trunkPts.length;
      final w = trunkW * (1 - t * 0.55) * 0.45;
      canvas.drawLine(
          Offset(p.dx - w, p.dy), Offset(p.dx + w, p.dy), ringPaint);
    }

    // Crown center
    final crownX = trunkPts.last.dx;
    final crownY = trunkPts.last.dy;

    // Coconuts (drawn before fronds so they peek through)
    if (l > 0.4) {
      final coconutPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF8B6914);
      final nc = 2 + rng.nextInt(3);
      for (var i = 0; i < nc; i++) {
        final ca = (rng.nextDouble() - 0.5) * pi * 0.8;
        final cr = (2.5 + rng.nextDouble() * 2) * s;
        canvas.drawCircle(
          Offset(crownX + cos(ca) * 6 * s,
              crownY + 4 * s + rng.nextDouble() * 5 * s),
          cr,
          coconutPaint,
        );
      }
    }

    // Fronds radiating from crown — many wide leaves
    final numFronds = (10 + l * 8).round(); // more fronds
    final frondLen = treeH * (0.28 + l * 0.14); // longer fronds
    final colors = _leafColors;
    for (var i = 0; i < numFronds; i++) {
      final baseAngle = (i / numFronds) * 2 * pi - pi / 2;
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.35;
      final fLen = frondLen * (0.65 + rng.nextDouble() * 0.35);
      final droop = 0.35 + rng.nextDouble() * 0.35;
      _drawPalmFrond(canvas, crownX, crownY, angle, fLen, droop,
          colors[rng.nextInt(colors.length)], rng, s);
    }
  }

  void _drawPalmFrond(Canvas canvas, double sx, double sy, double angle,
      double length, double droop, Color color, Random rng, double scale) {
    // Spine: curve from crown outward then droop under gravity
    final endX = sx + cos(angle) * length;
    final endY = sy + sin(angle) * length + length * droop;
    final ctrlX = sx + cos(angle) * length * 0.55;
    final ctrlY = sy + sin(angle) * length * 0.25;

    // Draw spine
    canvas.drawPath(
      Path()
        ..moveTo(sx, sy)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(color, ColorResolver.trunkColorLight, 0.35)!,
    );

    // Wide palm leaflets along spine — filled broad curved shapes, not thin lines
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final numLeaflets = 10 + rng.nextInt(6); // more leaflets per frond

    for (var i = 1; i < numLeaflets; i++) {
      final t = i / numLeaflets;
      final px = _qBez(sx, ctrlX, endX, t);
      final py = _qBez(sy, ctrlY, endY, t);

      final spineAngle = atan2(
          _qBezDeriv(sy, ctrlY, endY, t), _qBezDeriv(sx, ctrlX, endX, t));
      final leafletLen = length * 0.28 * (1 - t * 0.35); // wider leaflets
      final leafletWidth = leafletLen * 0.42; // fatter leaflets

      leafPaint.color =
          color.withValues(alpha: 0.30 + rng.nextDouble() * 0.40);

      // Left leaflet — broad curved teardrop shape
      final la = spineAngle - pi / 2 + 0.2;
      final ltipX = px + cos(la) * leafletLen;
      final ltipY = py + sin(la) * leafletLen;
      final lPerp = la + pi / 2;
      canvas.drawPath(
        Path()
          ..moveTo(px, py)
          ..quadraticBezierTo(
            px + cos(la) * leafletLen * 0.5 + cos(lPerp) * leafletWidth,
            py + sin(la) * leafletLen * 0.5 + sin(lPerp) * leafletWidth,
            ltipX, ltipY,
          )
          ..quadraticBezierTo(
            px + cos(la) * leafletLen * 0.5 - cos(lPerp) * leafletWidth,
            py + sin(la) * leafletLen * 0.5 - sin(lPerp) * leafletWidth,
            px, py,
          ),
        leafPaint,
      );

      // Right leaflet
      final ra = spineAngle + pi / 2 - 0.2;
      final rtipX = px + cos(ra) * leafletLen;
      final rtipY = py + sin(ra) * leafletLen;
      final rPerp = ra + pi / 2;
      canvas.drawPath(
        Path()
          ..moveTo(px, py)
          ..quadraticBezierTo(
            px + cos(ra) * leafletLen * 0.5 + cos(rPerp) * leafletWidth,
            py + sin(ra) * leafletLen * 0.5 + sin(rPerp) * leafletWidth,
            rtipX, rtipY,
          )
          ..quadraticBezierTo(
            px + cos(ra) * leafletLen * 0.5 - cos(rPerp) * leafletWidth,
            py + sin(ra) * leafletLen * 0.5 - sin(rPerp) * leafletWidth,
            px, py,
          ),
        leafPaint,
      );
    }
  }
}
