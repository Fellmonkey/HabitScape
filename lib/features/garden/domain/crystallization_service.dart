import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../habits/data/habit_logs_dao.dart';
import '../../habits/data/habits_dao.dart';
import '../../habits/domain/habit_engine.dart';
import '../data/garden_objects_dao.dart';
import '../domain/generator/bush_painter.dart';
import '../domain/generator/grass_painter.dart';
import '../domain/generator/moss_painter.dart';
import '../domain/generator/plant_params.dart';
import '../domain/generator/tree_painter.dart';

/// Crystallization service — end-of-month rasterizer.
///
/// When the app opens in a new month, this service:
/// 1. Computes metrics for each active habit for the previous month.
/// 2. Renders each plant via CustomPainter on a PictureRecorder.
/// 3. Saves the resulting PNG to the app's document directory.
/// 4. Stores a GardenObject record in the database.
class CrystallizationService {
  CrystallizationService({
    required this.habitsDao,
    required this.habitLogsDao,
    required this.gardenObjectsDao,
    required this.prefs,
  });

  final HabitsDao habitsDao;
  final HabitLogsDao habitLogsDao;
  final GardenObjectsDao gardenObjectsDao;
  final SharedPreferences prefs;

  static const _lastProcessedKey = 'last_processed_month';
  static const double _renderSize = 800;

  /// Check if crystallization is needed and run it.
  /// Returns the number of plants crystallized.
  Future<int> runIfNeeded() async {
    final now = DateTime.now();
    final currentMonthKey = now.year * 100 + now.month; // e.g. 202603
    final lastProcessed = prefs.getInt(_lastProcessedKey) ?? 0;

    if (lastProcessed >= currentMonthKey) return 0;

    // Process the previous month
    var prevMonth = now.month - 1;
    var prevYear = now.year;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }

    // Only process if we haven't processed it yet
    final prevKey = prevYear * 100 + prevMonth;
    if (lastProcessed >= prevKey) {
      // Edge case: we already processed previous month, just update key
      await prefs.setInt(_lastProcessedKey, currentMonthKey);
      return 0;
    }

    final count = await _crystallizeMonth(prevYear, prevMonth);

    await prefs.setInt(_lastProcessedKey, currentMonthKey);

    // Cleanup old logs (older than 13 months)
    await _cleanupOldLogs(now);

    return count;
  }

  Future<int> _crystallizeMonth(int year, int month) async {
    final habits = await habitsDao.getActiveHabits();
    if (habits.isEmpty) return 0;

    final docDir = await getApplicationDocumentsDirectory();
    final gardenDir = Directory('${docDir.path}/garden');
    if (!gardenDir.existsSync()) {
      gardenDir.createSync(recursive: true);
    }

    var count = 0;
    final rng = Random(year * 12 + month);

    for (final habit in habits) {
      // Check if already crystallized
      final existing = await gardenObjectsDao.getObjectForHabitMonth(
        habit.id,
        year,
        month,
      );
      if (existing != null) continue;

      // Get logs for this month
      final monthStart = DateTime.utc(year, month, 1);
      final monthEnd = DateTime.utc(year, month + 1, 1);

      final logs = await habitLogsDao.getLogsForHabitInRange(
        habit.id,
        monthStart.millisecondsSinceEpoch ~/ 1000,
        monthEnd.millisecondsSinceEpoch ~/ 1000,
      );

      // Calculate metrics
      final metrics = HabitEngine.calculateMetrics(habit, logs, year, month);
      final genSeed = rng.nextInt(1 << 31);

      // Create generation params
      final params = GenerationParams(
        archetype: SeedArchetype.fromString(habit.seedArchetype),
        completionPct: metrics.completionPct,
        absoluteCompletions: metrics.absoluteCompletions,
        maxStreak: metrics.maxStreak,
        morningRatio: metrics.morningRatio,
        afternoonRatio: metrics.afternoonRatio,
        eveningRatio: metrics.eveningRatio,
        seed: genSeed,
        isShortPerfect: metrics.isShortPerfect,
        objectType: metrics.objectType,
      );

      // Render to PNG
      final pngPath = await _renderToPng(params, habit.id, year, month, gardenDir);

      // Save to database
      await gardenObjectsDao.insertObject(GardenObjectsCompanion(
        habitId: Value(habit.id),
        year: Value(year),
        month: Value(month),
        completionPct: Value(metrics.completionPct),
        absoluteCompletions: Value(metrics.absoluteCompletions),
        maxStreak: Value(metrics.maxStreak),
        morningRatio: Value(metrics.morningRatio),
        afternoonRatio: Value(metrics.afternoonRatio),
        eveningRatio: Value(metrics.eveningRatio),
        objectType: Value(metrics.objectType.name),
        generationSeed: Value(genSeed),
        pngPath: Value(pngPath),
        isShortPerfect: Value(metrics.isShortPerfect),
      ));

      count++;
    }

    return count;
  }

  Future<String> _renderToPng(
    GenerationParams params,
    int habitId,
    int year,
    int month,
    Directory gardenDir,
  ) async {
    // Create a PictureRecorder and Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_renderSize, _renderSize);

    // Select and paint the appropriate painter
    final painter = _painterFor(params);
    painter.paint(canvas, size);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _renderSize.toInt(),
      _renderSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    if (byteData == null) {
      throw StateError('Failed to encode plant image to PNG');
    }

    // Save to file
    final fileName = '${habitId}_${year}_$month.png';
    final file = File('${gardenDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path;
  }

  CustomPainter _painterFor(GenerationParams params) {
    return switch (params.objectType) {
      GardenObjectType.tree => TreePainter(params: params),
      GardenObjectType.bush => BushPainter(params: params),
      GardenObjectType.grass => GrassPainter(params: params),
      GardenObjectType.moss || GardenObjectType.sleepingBulb =>
        MossPainter(params: params),
    };
  }

  Future<void> _cleanupOldLogs(DateTime now) async {
    // Delete logs older than 13 months
    final cutoff = DateTime.utc(now.year, now.month - 13, 1);
    final cutoffTs = cutoff.millisecondsSinceEpoch ~/ 1000;
    await habitLogsDao.deleteLogsBefore(cutoffTs);
  }
}
