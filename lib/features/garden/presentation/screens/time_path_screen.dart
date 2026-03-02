import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/generator/plant_params.dart';
import '../../domain/generator/plant_widget.dart';
import '../../providers/garden_providers.dart';
import '../widgets/path_trail_painter.dart';

/// Time Path (Тропа Времени) — scrollable garden of crystallized plants.
/// Renders months in reverse chronological order, each with focus plants on the
/// path and background forest canopy.
class TimePathScreen extends ConsumerWidget {
  const TimePathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenByMonth = ref.watch(gardenByMonthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final months = gardenByMonth.keys.toList()
      ..sort((a, b) {
        final cmp = b.$1.compareTo(a.$1);
        return cmp != 0 ? cmp : b.$2.compareTo(a.$2);
      });

    return Scaffold(
      body: SafeArea(
        child: months.isEmpty
            ? _buildEmptyState(theme)
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Тропа Времени',
                        key: K.timePathTitle,
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final key = months[index];
                      final objects = gardenByMonth[key]!;
                      return _MonthSegment(
                        year: key.$1,
                        month: key.$2,
                        objects: objects,
                        isDark: isDark,
                      );
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.park_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Тропа пока пуста',
              key: K.timePathEmpty,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Растения появятся здесь в конце месяца, когда ваши привычки кристаллизуются в сад',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single month's section on the Time Path.
class _MonthSegment extends ConsumerWidget {
  const _MonthSegment({
    required this.year,
    required this.month,
    required this.objects,
    required this.isDark,
  });

  final int year, month;
  final List<GardenObject> objects;
  final bool isDark;

  static const _months = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.of(context).size.height;
    final habitNames = ref.watch(habitNamesProvider).value ?? {};

    // Trees (Layer 1) follow the main path — large, labelled, interactive.
    // Bushes/moss/sleeping bulbs (Layer 0) scatter as background forest —
    // smaller and dimmed, but still tappable to see monthly stats.
    var focus = objects
        .where((o) =>
            GardenObjectType.fromString(o.objectType) ==
            GardenObjectType.tree)
        .toList();
    final background = objects
        .where((o) =>
            GardenObjectType.fromString(o.objectType) !=
            GardenObjectType.tree)
        .toList();

    // If many habits (>30 total), limit displayed focus plants to 8
    if (objects.length > 30 && focus.length > 8) {
      focus = focus.sublist(0, 8);
    }

    // Each month takes at least full screen height
    final segmentHeight = max(screenH, 300.0 + focus.length * 80.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            '${_months[month]} $year',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),

        // Garden segment
        SizedBox(
          height: segmentHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segW = constraints.maxWidth;
              const amplitude = 60.0;
              final centerX = segW / 2;

              return Stack(
                children: [
                  // Trail path in background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PathTrailPainter(
                        segmentCount: 1,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // Background forest (Layer 0) — smaller plants near path, tappable
                  if (background.isNotEmpty)
                    Positioned.fill(
                      child: _ForestCanopy(
                        objects: background,
                        habitNames: habitNames,
                        onTap: (obj, name) =>
                            _showMemoryCard(context, obj, name),
                      ),
                    ),

                  // Decorative grass fill elements along the path
                  ..._buildPathGrass(segW, segmentHeight, centerX, amplitude),

                  // Focus plants (Layer 1) — positioned along the winding path
                  for (var i = 0; i < focus.length; i++)
                    Builder(
                      builder: (_) {
                        // Distribute evenly across the full segment height
                        final spacing = segmentHeight / (focus.length + 1);
                        final posY = spacing * (i + 1) - 70;
                        final t = posY / segmentHeight;
                        final pathX = centerX +
                            sin(t * 3.14159 * 2) * amplitude;
                        // Alternate left/right of the trail with small offset
                        final offset = i.isEven ? -75.0 : 5.0;
                        final posX =
                            (pathX + offset).clamp(5.0, segW - 145.0);

                        final habitName =
                            habitNames[focus[i].habitId] ?? '';

                        return Positioned(
                          left: posX,
                          top: posY,
                          child: GestureDetector(
                            onTap: () => _showMemoryCard(
                                context, focus[i], habitName),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PlantThumbnail(object: focus[i], size: 140),
                                if (habitName.isNotEmpty)
                                  Container(
                                    width: 140,
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      habitName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Decorative grass filler widgets scattered along the path edges.
  List<Widget> _buildPathGrass(
      double segW, double segH, double centerX, double amplitude) {
    final rng = Random(year * 100 + month);
    final widgets = <Widget>[];
    final numGrass = 3 + rng.nextInt(4);

    for (var i = 0; i < numGrass; i++) {
      final t = (rng.nextDouble() * 0.8 + 0.1);
      final pathX = centerX + sin(t * 3.14159 * 2) * amplitude;
      final side = rng.nextBool() ? -1.0 : 1.0;
      final gx = (pathX + side * (35 + rng.nextDouble() * 30))
          .clamp(5.0, segW - 40.0);
      final gy = t * segH;
      final seed = rng.nextInt(100000);

      widgets.add(Positioned(
        left: gx,
        top: gy,
        child: Opacity(
          opacity: 0.4,
          child: PlantWidget(
            params: GenerationParams(
              archetype: SeedArchetype.oak,
              completionPct: 30,
              absoluteCompletions: 5,
              maxStreak: 3,
              morningRatio: 0.33,
              afternoonRatio: 0.33,
              eveningRatio: 0.34,
              seed: seed,
              isShortPerfect: false,
              objectType: GardenObjectType.grass,
            ),
            size: 50,
          ),
        ),
      ));
    }
    return widgets;
  }

  void _showMemoryCard(
      BuildContext context, GardenObject obj, String habitName) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MemoryCard(object: obj, theme: theme, habitName: habitName),
    );
  }
}

/// Background forest canopy (Layer 0) — smaller plants scattered near the path.
/// Each plant is placed so its bounding slot doesn't overlap any earlier plant.
/// The first attempt uses a path-aligned position (same visual style as before);
/// up to 40 random fallback positions are tried before the plant is skipped.
class _ForestCanopy extends StatelessWidget {
  const _ForestCanopy({
    required this.objects,
    required this.habitNames,
    required this.onTap,
  });

  final List<GardenObject> objects;
  final Map<int, String> habitNames;
  final void Function(GardenObject, String) onTap;

  static const double _amplitude = 60.0;
  // Clearance zone per plant: thumbnail + label area + a little breathing room
  static const double _slotW = 108.0;
  static const double _slotH = 116.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segW = constraints.maxWidth;
        final segH = constraints.maxHeight;
        final positions = _placeItems(segW, segH);

        return Stack(
          children: [
            for (final (obj, pos) in positions)
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: _BackgroundItem(
                  object: obj,
                  habitName: habitNames[obj.habitId] ?? '',
                  onTap: onTap,
                ),
              ),
          ],
        );
      },
    );
  }

  List<(GardenObject, Offset)> _placeItems(double segW, double segH) {
    final result = <(GardenObject, Offset)>[];
    final placed = <Rect>[];
    final centerX = segW / 2;
    final limit = objects.length.clamp(0, 10);

    for (var i = 0; i < limit; i++) {
      final obj = objects[i];
      final seed = obj.generationSeed;
      Offset? chosen;

      for (var attempt = 0; attempt < 40; attempt++) {
        double x, y;

        if (attempt == 0) {
          // Attempt 0: deterministic path-aligned position
          final rng = Random(seed);
          final yFrac = 0.05 + rng.nextDouble() * 0.88;
          y = (yFrac * (segH - _slotH)).clamp(4.0, segH - _slotH);
          final t = (y + _slotH / 2) / segH;
          final pathX = centerX + sin(t * 3.14159 * 2) * _amplitude;
          final side = rng.nextBool() ? -1.0 : 1.0;
          final off = side * (30 + rng.nextDouble() * 50);
          x = (pathX + off).clamp(4.0, segW - _slotW);
        } else {
          // Subsequent attempts: seeded-random positions spread through segment
          final rng = Random(seed ^ (attempt * 0x9e3779b9));
          x = (rng.nextDouble() * (segW - _slotW)).clamp(4.0, segW - _slotW);
          y = (rng.nextDouble() * (segH - _slotH)).clamp(4.0, segH - _slotH);
        }

        final candidate = Rect.fromLTWH(x, y, _slotW, _slotH);
        if (placed.every((r) => !r.overlaps(candidate))) {
          chosen = Offset(x, y);
          placed.add(candidate);
          break;
        }
      }

      // chosen is null only when the segment is extremely crowded — skip plant
      if (chosen != null) result.add((obj, chosen));
    }

    return result;
  }
}

// ── Single background plant widget ───────────────────────────

class _BackgroundItem extends StatelessWidget {
  const _BackgroundItem({
    required this.object,
    required this.habitName,
    required this.onTap,
  });

  final GardenObject object;
  final String habitName;
  final void Function(GardenObject, String) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap(object, habitName),
      child: SizedBox(
        width: 100,
        child: Opacity(
          opacity: 0.72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlantThumbnail(object: object, size: 70),
              if (habitName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    habitName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a plant either from its cached PNG or live via CustomPaint.
class _PlantThumbnail extends StatelessWidget {
  const _PlantThumbnail({required this.object, required this.size});

  final GardenObject object;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Try to load cached PNG first
    if (object.pngPath != null && object.pngPath!.isNotEmpty) {
      final file = File(object.pngPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        );
      }
    }

    // Fallback: render live with CustomPaint
    final objectType = GardenObjectType.fromString(object.objectType);
    final archetype = _resolveArchetype(objectType);

    final params = GenerationParams(
      archetype: archetype,
      completionPct: object.completionPct,
      absoluteCompletions: object.absoluteCompletions,
      maxStreak: object.maxStreak,
      morningRatio: object.morningRatio,
      afternoonRatio: object.afternoonRatio,
      eveningRatio: object.eveningRatio,
      seed: object.generationSeed,
      isShortPerfect: object.isShortPerfect,
      objectType: objectType,
    );

    return PlantWidget(params: params, size: size);
  }

  /// Map object type back to an archetype for rendering.
  /// Uses the generation seed to deterministically assign an archetype.
  SeedArchetype _resolveArchetype(GardenObjectType type) {
    return switch (type) {
      GardenObjectType.tree => SeedArchetype.values[
          object.generationSeed % SeedArchetype.values.length],
      GardenObjectType.bush => SeedArchetype.values[
          object.generationSeed % SeedArchetype.values.length],
      GardenObjectType.moss => SeedArchetype.oak,
      GardenObjectType.grass => SeedArchetype.oak,
      GardenObjectType.sleepingBulb => SeedArchetype.oak,
    };
  }
}

/// Memory Card bottom sheet — shown when tapping a tree on the path.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.object,
    required this.theme,
    required this.habitName,
  });

  final GardenObject object;
  final ThemeData theme;
  final String habitName;

  static const _months = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final pct = object.completionPct.round();
    final objectType = GardenObjectType.fromString(object.objectType);
    final archetype = _resolveArchetype(objectType, object.generationSeed);

    // Derived stats
    final daysInMonth =
        DateUtils.getDaysInMonth(object.year, object.month);
    final avgPerWeek =
        (object.absoluteCompletions / (daysInMonth / 7.0)).toStringAsFixed(1);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: AppRadius.borderS,
                ),
              ),
            ),

            // Plant thumbnail + habit name + month
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PlantThumbnail(object: object, size: 88),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (habitName.isNotEmpty)
                        Text(
                          habitName,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${_months[object.month]} ${object.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ArchetypeChip(archetype: archetype, theme: theme),
                          _TypeChip(
                              objectType: GardenObjectType.fromString(
                                  object.objectType),
                              theme: theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Completion ring
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: object.completionPct / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                _StatChip(
                  label: 'Выполнений',
                  value: '${object.absoluteCompletions}',
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Макс. серия',
                  value: '${object.maxStreak} дн',
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Ср. в нед',
                  value: avgPerWeek,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Short perfect badge
            if (object.isShortPerfect) ...
              [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x20FFD700),
                    borderRadius: AppRadius.borderM,
                    border: Border.all(color: const Color(0x40FFD700)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Аура идеального старта',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFFFFD700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

            // Time-of-day distribution
            Text('Время выполнения', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _TimeDistribution(
              morningRatio: object.morningRatio,
              afternoonRatio: object.afternoonRatio,
              eveningRatio: object.eveningRatio,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  SeedArchetype _resolveArchetype(GardenObjectType type, int seed) =>
      switch (type) {
        GardenObjectType.tree ||
        GardenObjectType.bush =>
          SeedArchetype.values[seed % SeedArchetype.values.length],
        _ => SeedArchetype.oak,
      };
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label, value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderM,
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Archetype chip for Memory Card ──────────────────────────

class _ArchetypeChip extends StatelessWidget {
  const _ArchetypeChip({required this.archetype, required this.theme});

  final SeedArchetype archetype;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderS,
      ),
      child: Text(
        archetype.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ── Object-type chip ─────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.objectType, required this.theme});

  final GardenObjectType objectType;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (objectType) {
      GardenObjectType.tree => ('Дерево', const Color(0xFF5A9B5A)),
      GardenObjectType.bush => ('Куст', const Color(0xFF8FAF7A)),
      GardenObjectType.moss => ('Мох', const Color(0xFF8FAF7A)),
      GardenObjectType.grass => ('Трава', const Color(0xFF8FAF7A)),
      GardenObjectType.sleepingBulb => ('Спящая луковица', const Color(0xFFB8A9D4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderS,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _TimeDistribution extends StatelessWidget {
  const _TimeDistribution({
    required this.morningRatio,
    required this.afternoonRatio,
    required this.eveningRatio,
    required this.theme,
  });

  final double morningRatio, afternoonRatio, eveningRatio;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bar('Утро', morningRatio, const Color(0xFF8FAF7A)),
        const SizedBox(width: 8),
        _bar('День', afternoonRatio, const Color(0xFFD4A767)),
        const SizedBox(width: 8),
        _bar('Вечер', eveningRatio, const Color(0xFFB8A9D4)),
      ],
    );
  }

  Widget _bar(String label, double ratio, Color color) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.7),
                    borderRadius: AppRadius.borderS,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(ratio * 100).round()}%',
            style: theme.textTheme.bodySmall,
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
