import '../../features/garden/domain/generator/plant_params.dart';
import '../database/enums.dart';
import 'generation_fixtures.dart';

/// A named debug profile for testing plant generation in debug mode.
class DebugProfile {
  const DebugProfile({
    required this.name,
    required this.description,
    required this.params,
  });

  final String name;
  final String description;
  final GenerationParams params;
}

/// Pre-built profiles grouped by category, derived from [allFixtures].
abstract final class DebugProfiles {
  /// Categories for the debug menu UI.
  static final Map<String, List<DebugProfile>> categories = {
    'По типу объекта': _byType(),
    'По архетипу': _byArchetype(),
    'Short-perfect': _shortPerfect(),
    'Время суток': _byTime(),
  };

  // ── By object type (one per completion level, oak + mixed) ─

  static List<DebugProfile> _byType() {
    return [
      for (final level in completionLevels)
        DebugProfile(
          name: '${_objectEmoji(level.objectType)} ${_levelRu(level.name)} — '
              '${level.pct.toInt()}%',
          description: '${level.objectType.name}, стрик ${level.streak}',
          params: allFixtures.firstWhere(
            (p) =>
                p.archetype == SeedArchetype.oak &&
                p.completionPct == level.pct &&
                p.morningRatio == 0.4, // mixed distribution
          ),
        ),
    ];
  }

  // ── By archetype (high completion, mixed time) ─────────────

  static List<DebugProfile> _byArchetype() {
    return [
      for (final arch in SeedArchetype.values)
        DebugProfile(
          name: '${_archetypeEmoji(arch)} ${arch.displayName} — 95%',
          description: 'Дерево, стрик 20',
          params: allFixtures.firstWhere(
            (p) =>
                p.archetype == arch &&
                p.completionPct == 95 &&
                p.morningRatio == 0.4,
          ),
        ),
    ];
  }

  // ── Short-perfect (one per archetype) ──────────────────────

  static List<DebugProfile> _shortPerfect() {
    return [
      for (final p in shortPerfectFixtures)
        DebugProfile(
          name: '✨ Short-perfect ${p.archetype.displayName}',
          description: '100% за неполный месяц',
          params: p,
        ),
    ];
  }

  // ── Time distribution extremes (oak, high) ─────────────────

  static List<DebugProfile> _byTime() {
    return [
      for (final dist in timeDistributions)
        DebugProfile(
          name: '${_timeEmoji(dist.name)} ${_timeRu(dist.name)} — 95%',
          description: 'Дуб, '
              '${(dist.morning * 100).toInt()}/'
              '${(dist.afternoon * 100).toInt()}/'
              '${(dist.evening * 100).toInt()}',
          params: allFixtures.firstWhere(
            (p) =>
                p.archetype == SeedArchetype.oak &&
                p.completionPct == 95 &&
                p.morningRatio == dist.morning &&
                p.afternoonRatio == dist.afternoon,
          ),
        ),
    ];
  }

  // ── Display helpers ────────────────────────────────────────

  static String _objectEmoji(GardenObjectType type) => switch (type) {
        GardenObjectType.sleepingBulb => '🌱',
        GardenObjectType.moss => '🌿',
        GardenObjectType.bush => '🌳',
        GardenObjectType.tree => '🌲',
        GardenObjectType.grass => '🌾',
      };

  static String _levelRu(String name) => switch (name) {
        'zero' => 'Спящая луковица',
        'low' => 'Мох — низкий',
        'mid' => 'Куст — средний',
        'threshold' => 'Дерево — порог',
        'high' => 'Дерево — высокий',
        _ => name,
      };

  static String _archetypeEmoji(SeedArchetype arch) => switch (arch) {
        SeedArchetype.oak => '🌳',
        SeedArchetype.sakura => '🌸',
        SeedArchetype.pine => '🌲',
        SeedArchetype.willow => '🍃',
        SeedArchetype.baobab => '🏛️',
        SeedArchetype.palm => '🌴',
      };

  static String _timeEmoji(String name) => switch (name) {
        'morning' => '🌅',
        'afternoon' => '☀️',
        'evening' => '🌙',
        'mixed' => '🔄',
        _ => '⏰',
      };

  static String _timeRu(String name) => switch (name) {
        'morning' => 'Только утро',
        'afternoon' => 'Только день',
        'evening' => 'Только вечер',
        'mixed' => 'Смешанный',
        _ => name,
      };
}
