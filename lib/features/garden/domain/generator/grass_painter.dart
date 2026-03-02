import 'dart:math';

import 'package:flutter/material.dart';

import 'color_resolver.dart';
import 'plant_params.dart';

/// CustomPainter for grass — a decorative filler element on the Time Path.
///
/// Renders naturalistic grass tufts with:
/// - **Blade clusters** — curved bezier blades of varying height and lean.
/// - **Wildflowers** — occasional small flowers among the grass.
/// - **Ground texture** — soft base for natural grounding.
class GrassPainter extends CustomPainter {
  GrassPainter({required this.params});

  final GenerationParams params;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(params.seed);
    final scale = params.scaleFactor;

    final centerX = size.width / 2;
    final baseY = size.height * 0.88;

    // Soft ground base
    _drawGround(canvas, centerX, baseY, size, rng, scale);

    // Grass blade clusters
    final numTufts =
        (3 + (params.absoluteCompletions * 0.2).round()).clamp(2, 7);
    for (var i = 0; i < numTufts; i++) {
      final tx = centerX + (rng.nextDouble() - 0.5) * size.width * 0.5;
      final ty = baseY + (rng.nextDouble() - 0.5) * size.height * 0.06;
      _drawGrassTuft(canvas, tx, ty, rng, scale);
    }

    // Occasional wildflowers
    final numFlowers =
        (params.absoluteCompletions * 0.15).round().clamp(0, 4);
    for (var i = 0; i < numFlowers; i++) {
      final fx = centerX + (rng.nextDouble() - 0.5) * size.width * 0.45;
      final fy = baseY + (rng.nextDouble() - 0.5) * size.height * 0.05;
      _drawWildflower(canvas, fx, fy, rng, scale);
    }

    // Small decorative elements: fallen leaves, seeds
    _drawDecorations(canvas, centerX, baseY, size, rng, scale);
  }

  void _drawGround(Canvas canvas, double cx, double baseY, Size size,
      Random rng, double scale) {
    // Soft dirt/earth base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 2 * scale),
        width: size.width * 0.4,
        height: 8 * scale,
      ),
      Paint()
        ..color = const Color(0xFFA89880).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawGrassTuft(Canvas canvas, double cx, double baseY, Random rng,
      double scale) {
    final numBlades = 5 + rng.nextInt(6);
    final colors = ColorResolver.leafGradient(
      morningRatio: params.morningRatio,
      afternoonRatio: params.afternoonRatio,
      eveningRatio: params.eveningRatio,
    );

    for (var i = 0; i < numBlades; i++) {
      final lean = (rng.nextDouble() - 0.5) * 25 * scale;
      final height = (12 + rng.nextDouble() * 22) * scale;
      final bladeWidth = (1.0 + rng.nextDouble() * 1.5) * scale;
      final curveAmount = (rng.nextDouble() - 0.5) * 12 * scale;

      final tipX = cx + lean;
      final tipY = baseY - height;
      final ctrlX = cx + lean * 0.4 + curveAmount;
      final ctrlY = baseY - height * 0.55;

      final color = colors[rng.nextInt(colors.length)]
          .withValues(alpha: 0.45 + rng.nextDouble() * 0.45);

      // Draw blade as a tapered path
      final bladePath = Path()
        ..moveTo(cx - bladeWidth * 0.5, baseY)
        ..quadraticBezierTo(ctrlX - bladeWidth * 0.3, ctrlY, tipX, tipY)
        ..quadraticBezierTo(
            ctrlX + bladeWidth * 0.3, ctrlY, cx + bladeWidth * 0.5, baseY)
        ..close();

      canvas.drawPath(
        bladePath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawWildflower(Canvas canvas, double cx, double baseY, Random rng,
      double scale) {
    // Stem
    final stemH = (10 + rng.nextDouble() * 15) * scale;
    final lean = (rng.nextDouble() - 0.5) * 8 * scale;
    final tipX = cx + lean;
    final tipY = baseY - stemH;

    canvas.drawPath(
      Path()
        ..moveTo(cx, baseY)
        ..quadraticBezierTo(
            cx + lean * 0.5, baseY - stemH * 0.5, tipX, tipY),
      Paint()
        ..color = ColorResolver.mossGreen.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Flower petals
    final petalPaint = Paint()..style = PaintingStyle.fill;
    final flowerColor = _randomFlowerColor(rng);
    final numPetals = 4 + rng.nextInt(3);
    final petalR = (2 + rng.nextDouble() * 2.5) * scale;

    for (var p = 0; p < numPetals; p++) {
      final a = (p / numPetals) * 2 * pi + rng.nextDouble() * 0.3;
      petalPaint.color = flowerColor.withValues(alpha: 0.5 + rng.nextDouble() * 0.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tipX + cos(a) * petalR * 0.7, tipY + sin(a) * petalR * 0.7),
          width: petalR * 1.1,
          height: petalR * 0.7,
        ),
        petalPaint,
      );
    }

    // Center
    petalPaint.color = const Color(0xFFFFF176).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(tipX, tipY), petalR * 0.3, petalPaint);
  }

  Color _randomFlowerColor(Random rng) {
    const flowers = [
      Color(0xFFFFB7C5), // pink
      Color(0xFFB8A9D4), // lavender
      Color(0xFFFFE082), // yellow
      Color(0xFFADD8E6), // light blue
      Color(0xFFFFCBA4), // peach
    ];
    return flowers[rng.nextInt(flowers.length)];
  }

  void _drawDecorations(Canvas canvas, double cx, double baseY, Size size,
      Random rng, double scale) {
    // Fallen leaf or two
    final numLeaves = rng.nextInt(3);
    final leafPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < numLeaves; i++) {
      final lx = cx + (rng.nextDouble() - 0.5) * size.width * 0.4;
      final ly = baseY + (rng.nextDouble() - 0.3) * 8 * scale;
      final rot = rng.nextDouble() * pi;
      final leafLen = (3 + rng.nextDouble() * 4) * scale;

      leafPaint.color = Color.lerp(
        const Color(0xFFC8A84E),
        const Color(0xFFB08030),
        rng.nextDouble(),
      )!.withValues(alpha: 0.25 + rng.nextDouble() * 0.2);

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(rot);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-leafLen * 0.4, -leafLen * 0.5, 0, -leafLen)
          ..quadraticBezierTo(leafLen * 0.4, -leafLen * 0.5, 0, 0),
        leafPaint,
      );
      canvas.restore();
    }

    // Tiny pebbles/seeds
    final seedPaint = Paint()..style = PaintingStyle.fill;
    final numSeeds = 1 + rng.nextInt(3);
    for (var i = 0; i < numSeeds; i++) {
      final sx = cx + (rng.nextDouble() - 0.5) * size.width * 0.35;
      final sy = baseY + (rng.nextDouble() - 0.3) * 5 * scale;
      final sr = (1 + rng.nextDouble() * 2) * scale;
      seedPaint.color =
          ColorResolver.pebbleGrey.withValues(alpha: 0.2 + rng.nextDouble() * 0.15);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sx, sy),
          width: sr * 2,
          height: sr * 1.3,
        ),
        seedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GrassPainter oldDelegate) =>
      params.seed != oldDelegate.params.seed ||
      params.absoluteCompletions != oldDelegate.params.absoluteCompletions;
}
