import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../garden/domain/generator/bush_painter.dart';
import '../../garden/domain/generator/grass_painter.dart';
import '../../garden/domain/generator/moss_painter.dart';
import '../../garden/domain/generator/plant_params.dart';
import '../../garden/domain/generator/tree_painter.dart';

/// Generates a shareable card image for a given month's garden objects.
class CardGeneratorService {
  static const double _cardWidth = 1080;
  static const double _cardHeight = 1920;
  static const double _plantSize = 200;

  /// Render a month card to PNG bytes.
  /// Returns raw PNG data that can be shared or saved.
  static Future<List<int>> generateMonthCard({
    required int year,
    required int month,
    required List<GardenObject> objects,
    required Map<int, String> habitNames,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background gradient.
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, _cardHeight),
        [AppColors.lightBackground, AppColors.sageGreen.withValues(alpha: 0.15)],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _cardWidth, _cardHeight),
      bgPaint,
    );

    // Header.
    _drawHeader(canvas, year, month);

    // Stats summary.
    _drawStats(canvas, objects);

    // Plants grid.
    _drawPlants(canvas, objects, habitNames);

    // Footer branding.
    _drawFooter(canvas);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _cardWidth.toInt(),
      _cardHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    if (byteData == null) {
      throw StateError('Failed to encode card image');
    }

    return byteData.buffer.asUint8List().toList();
  }

  static void _drawHeader(Canvas canvas, int year, int month) {
    const months = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    final title = '${months[month]} $year';

    final titleStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 56,
      fontWeight: FontWeight.bold,
    );
    final titleBuilder = ui.ParagraphBuilder(titleStyle)
      ..pushStyle(ui.TextStyle(
        color: AppColors.lightText,
        fontSize: 56,
        fontWeight: FontWeight.bold,
      ))
      ..addText(title);
    final titleParagraph = titleBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: _cardWidth));
    canvas.drawParagraph(titleParagraph, const Offset(0, 80));

    // Subtitle.
    final subtitleBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 28,
    ))
      ..pushStyle(ui.TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 28,
      ))
      ..addText('Мой сад привычек');
    final subtitleParagraph = subtitleBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: _cardWidth));
    canvas.drawParagraph(subtitleParagraph, const Offset(0, 150));
  }

  static void _drawStats(Canvas canvas, List<GardenObject> objects) {
    if (objects.isEmpty) return;

    final avgPct = objects.map((o) => o.completionPct).reduce((a, b) => a + b) /
        objects.length;
    final trees = objects.where((o) => o.objectType == 'tree').length;
    final bushes = objects.where((o) => o.objectType == 'bush').length;

    final statsText =
        '${(avgPct * 100).round()}% среднее  |  $trees деревьев  |  $bushes кустов  |  ${objects.length} всего';

    final statsBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 24,
    ))
      ..pushStyle(ui.TextStyle(
        color: AppColors.sageGreen,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ))
      ..addText(statsText);
    final statsParagraph = statsBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: _cardWidth));
    canvas.drawParagraph(statsParagraph, const Offset(0, 220));
  }

  static void _drawPlants(
    Canvas canvas,
    List<GardenObject> objects,
    Map<int, String> habitNames,
  ) {
    const columns = 3;
    const startY = 300.0;
    const padX = 60.0;
    final cellWidth = (_cardWidth - padX * 2) / columns;
    const cellHeight = _plantSize + 60;

    for (var i = 0; i < objects.length; i++) {
      final obj = objects[i];
      final col = i % columns;
      final row = i ~/ columns;

      final cx = padX + col * cellWidth + cellWidth / 2;
      final cy = startY + row * cellHeight;

      // Paint the plant.
      canvas.save();
      canvas.translate(cx - _plantSize / 2, cy);

      final params = GenerationParams(
        archetype: SeedArchetype.fromString(
            habitNames.containsKey(obj.habitId) ? 'oak' : obj.objectType),
        completionPct: obj.completionPct,
        absoluteCompletions: obj.absoluteCompletions,
        maxStreak: obj.maxStreak,
        morningRatio: obj.morningRatio,
        afternoonRatio: obj.afternoonRatio,
        eveningRatio: obj.eveningRatio,
        seed: obj.generationSeed,
        isShortPerfect: obj.isShortPerfect,
        objectType: GardenObjectType.values.firstWhere(
          (t) => t.name == obj.objectType,
          orElse: () => GardenObjectType.moss,
        ),
      );

      final painter = _painterFor(params);
      painter.paint(canvas, Size(_plantSize, _plantSize));
      canvas.restore();

      // Draw habit name below plant.
      final name = habitNames[obj.habitId] ?? '';
      final nameBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 18,
        maxLines: 1,
        ellipsis: '...',
      ))
        ..pushStyle(ui.TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
        ))
        ..addText(name);
      final nameParagraph = nameBuilder.build()
        ..layout(ui.ParagraphConstraints(width: cellWidth));
      canvas.drawParagraph(
        nameParagraph,
        Offset(padX + col * cellWidth, cy + _plantSize + 4),
      );
    }
  }

  static void _drawFooter(Canvas canvas) {
    final footerBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 22,
    ))
      ..pushStyle(ui.TextStyle(
        color: AppColors.lightTextSecondary.withValues(alpha: 0.6),
        fontSize: 22,
      ))
      ..addText('Rythm');
    final footerParagraph = footerBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: _cardWidth));
    canvas.drawParagraph(footerParagraph, const Offset(0, _cardHeight - 80));
  }

  static CustomPainter _painterFor(GenerationParams params) {
    return switch (params.objectType) {
      GardenObjectType.tree => TreePainter(params: params),
      GardenObjectType.bush => BushPainter(params: params),
      GardenObjectType.grass => GrassPainter(params: params),
      GardenObjectType.moss || GardenObjectType.sleepingBulb =>
        MossPainter(params: params),
    };
  }
}
