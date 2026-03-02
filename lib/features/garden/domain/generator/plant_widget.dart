import 'package:flutter/material.dart';

import '../../../../core/database/enums.dart';
import 'bush_painter.dart';
import 'grass_painter.dart';
import 'moss_painter.dart';
import 'plant_params.dart';
import 'tree_painter.dart';

/// Unified widget that renders the correct plant type based on [GenerationParams].
/// Selects TreePainter, BushPainter, or MossPainter automatically.
class PlantWidget extends StatelessWidget {
  const PlantWidget({
    required this.params,
    this.size = 200,
    super.key,
  });

  final GenerationParams params;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: _painterFor(params),
      ),
    );
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
