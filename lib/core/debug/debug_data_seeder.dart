import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../utils/date_helpers.dart';
import '../../features/habits/domain/scheduling.dart';

/// A scenario that can be loaded via the debug menu.
class DebugScenario {
  const DebugScenario({
    required this.name,
    required this.description,
    required this.habitCount,
    required this.months,
    this.icon = '📦',
  });

  final String name;
  final String description;
  final int habitCount;

  /// How many past months of data to generate (1 / 3 / 6 / 12).
  final int months;
  final String icon;
}

/// All available scenarios for the debug menu.
const debugScenarios = [
  // ── Small ──
  DebugScenario(
    name: '5 привычек · 1 мес',
    description: 'Минимальный набор',
    habitCount: 5,
    months: 1,
    icon: '🌱',
  ),
  DebugScenario(
    name: '5 привычек · 3 мес',
    description: 'Квартал с малым числом',
    habitCount: 5,
    months: 3,
    icon: '🌿',
  ),
  DebugScenario(
    name: '5 привычек · 6 мес',
    description: 'Полгода',
    habitCount: 5,
    months: 6,
    icon: '🌳',
  ),
  DebugScenario(
    name: '5 привычек · 12 мес',
    description: 'Полный год',
    habitCount: 5,
    months: 12,
    icon: '🌲',
  ),
  // ── Medium ──
  DebugScenario(
    name: '30 привычек · 1 мес',
    description: 'Много привычек, мало истории',
    habitCount: 30,
    months: 1,
    icon: '📋',
  ),
  DebugScenario(
    name: '30 привычек · 3 мес',
    description: 'Активный пользователь',
    habitCount: 30,
    months: 3,
    icon: '📊',
  ),
  DebugScenario(
    name: '30 привычек · 6 мес',
    description: 'Полгода активности',
    habitCount: 30,
    months: 6,
    icon: '📈',
  ),
  DebugScenario(
    name: '30 привычек · 12 мес',
    description: 'Тяжёлый юзер, год',
    habitCount: 30,
    months: 12,
    icon: '🏋️',
  ),
  // ── Large ──
  DebugScenario(
    name: '90 привычек · 1 мес',
    description: 'Стресс-тест UI',
    habitCount: 90,
    months: 1,
    icon: '🔥',
  ),
  DebugScenario(
    name: '90 привычек · 3 мес',
    description: 'Массивный набор',
    habitCount: 90,
    months: 3,
    icon: '💥',
  ),
  DebugScenario(
    name: '90 привычек · 12 мес',
    description: 'Максимальная нагрузка',
    habitCount: 90,
    months: 12,
    icon: '🚀',
  ),
];

// ── Habit name pool ────────────────────────────────────────

const _habitNames = [
  'Утренняя пробежка',
  'Чтение книг',
  'Медитация',
  'Тренировка',
  'Журнал благодарности',
  'Водный баланс',
  'Растяжка',
  'Практика языка',
  'Уборка 15 мин',
  'Без сахара',
  'Холодный душ',
  'Прогулка',
  'Йога',
  'Дыхательная гимнастика',
  'Учеба 30 мин',
  'Здоровый завтрак',
  'Рисование',
  'Музыка',
  'Писательство',
  'Фокус 2ч без телефона',
  'Вечерний ритуал',
  'Витамины',
  'Планирование дня',
  'Осанка',
  'Бег 5 км',
  'Отжимания',
  'Подтягивания',
  'Скакалка',
  'Лестница',
  'Зубная нить',
  'Код 1 час',
  'Рецепт дня',
  'Фото дня',
  'Новые знакомства',
  'Инвестиции',
  'Бюджет',
  'Ранний подъём',
  'Экран < 2ч вечером',
  'Массаж лица',
  'Уход за кожей',
  'Без кофеина',
  'Без алкоголя',
  'Без курения',
  'Практика речи',
  'Шахматы',
  'Отжимания 100',
  'Планка 3 мин',
  'Без фастфуда',
  'Сон до 23',
  'Благотворительность',
  'Обнять близкого',
  'Позвонить родителям',
  'Пресс',
  'Турник',
  'Плавание',
  'Велосипед',
  'Танцы',
  'Скалолазание',
  'Сёрфинг',
  'Навык дня',
  'Дневник снов',
  'Аффирмации',
  'Визуализация',
  'Комплимент',
  'Новая еда',
  'Уроки гитары',
  'Подкаст',
  'TED Talk',
  'Документалка',
  'Растения полив',
  'Стирка',
  'Посуда сразу',
  'Заправить кровать',
  'Порядок стол',
  'Расхламление',
  'Ноль отходов',
  'Сортировка мусора',
  'Экономия воды',
  'Eco-bag',
  'Вегетарианство',
  'Порция овощей',
  'Без перекусов',
  'Калории в норме',
  'Белок 100 г',
  'Клетчатка',
  'Магний',
  'Омега-3',
  'Тишина 15 мин',
  'Самоанализ',
  'Благодарность',
];

const _timeSlots = [
  TimeOfDay.morning,
  TimeOfDay.afternoon,
  TimeOfDay.evening,
  TimeOfDay.anytime,
];

// ── Frequency templates ────────────────────────────────────

class _FreqTemplate {
  const _FreqTemplate(this.type, this.value);
  final FrequencyType type;
  final String value;
}

const _freqTemplates = [
  _FreqTemplate(FrequencyType.daily, '{}'),
  _FreqTemplate(FrequencyType.daily, '{}'),
  _FreqTemplate(FrequencyType.weekdays, '{"days":[1,2,3,4,5]}'),
  _FreqTemplate(FrequencyType.weekdays, '{"days":[1,3,5]}'),
  _FreqTemplate(FrequencyType.xPerWeek, '{"x":3}'),
  _FreqTemplate(FrequencyType.xPerWeek, '{"x":5}'),
  _FreqTemplate(FrequencyType.everyXDays, '{"x":2}'),
  _FreqTemplate(FrequencyType.everyXDays, '{"x":3}'),
];

/// Seeds the database with realistic data for a [DebugScenario].
///
/// **Wipes all existing data** before inserting.
class DebugDataSeeder {
  DebugDataSeeder(this.db);

  final AppDatabase db;

  /// Clear the database and populate it with the given scenario.
  /// Returns the number of habits created.
  Future<int> seed(DebugScenario scenario) async {
    // 1. Wipe everything
    await db.habitLogsDao.deleteAllLogs();
    await db.habitsDao.deleteAllHabits();
    await db.dayNotesDao.deleteAllNotes();
    await db.monthlyGoalsDao.deleteAllGoals();

    final rng = Random(scenario.habitCount * 1000 + scenario.months);
    final now = DateTime.now().toMidnight;
    // Per-day done/expected counts across all habits — feeds the mood notes.
    final dayAgg = <int, _DayAgg>{};

    // 2. Determine the time window
    final endMonth = DateTime.utc(
      now.year,
      now.month,
      1,
    ); // current month start
    final startMonth = DateTime.utc(now.year, now.month - scenario.months, 1);

    // 3. Create habits
    final habitIds = <int>[];
    final habitMeta = <_HabitMeta>[];

    for (var i = 0; i < scenario.habitCount; i++) {
      final name = _habitNames[i % _habitNames.length];
      final suffix = i >= _habitNames.length
          ? ' (${i ~/ _habitNames.length + 1})'
          : '';
      final icon = HabitIcon.values[i % HabitIcon.values.length];
      final freq = _freqTemplates[i % _freqTemplates.length];
      final tod = _timeSlots[i % _timeSlots.length];

      // Stagger creation dates: first 60% start at the beginning,
      // 30% start 1–3 months in, 10% start mid-month.
      DateTime createdDate;
      if (i < scenario.habitCount * 0.6) {
        createdDate = startMonth;
      } else if (i < scenario.habitCount * 0.9) {
        final offsetMonths = rng.nextInt(scenario.months.clamp(1, 3));
        createdDate = DateTime.utc(
          startMonth.year,
          startMonth.month + offsetMonths,
          1,
        );
      } else {
        final offsetMonths = rng.nextInt(scenario.months.clamp(1, 2));
        createdDate = DateTime.utc(
          startMonth.year,
          startMonth.month + offsetMonths,
          rng.nextInt(20) + 5, // day 5–24
        );
      }
      // Clamp: can't be in the future
      if (createdDate.isAfter(now)) createdDate = now;

      final id = await db.habitsDao.insertHabit(
        HabitsCompanion.insert(
          name: '$name$suffix',
          createdAt: createdDate.unixSeconds,
          icon: Value(icon.name),
          frequencyType: Value(freq.type.name),
          frequencyValue: Value(freq.value),
          timeOfDay: Value(tod.name),
        ),
      );

      habitIds.add(id);
      habitMeta.add(
        _HabitMeta(
          id: id,
          icon: icon,
          freq: freq,
          tod: tod,
          createdAt: createdDate,
          // Base "skill" that slowly improves — random starting quality
          quality: 0.2 + rng.nextDouble() * 0.3, // 0.2–0.5 base
        ),
      );
    }

    // 4. Generate logs month by month
    var m = startMonth;
    while (m.isBefore(endMonth)) {
      for (final meta in habitMeta) {
        // Skip months before creation
        if (m.isBefore(
          DateTime.utc(meta.createdAt.year, meta.createdAt.month, 1),
        )) {
          continue;
        }

        await _generateMonth(
          meta: meta,
          year: m.year,
          month: m.month,
          now: now,
          rng: rng,
          dayAgg: dayAgg,
        );
      }
      m = DateTime.utc(m.year, m.month + 1, 1);
    }

    // 5. Generate today's logs as pending (so Greenhouse shows them)
    await _generateTodayLogs(habitMeta, now);

    // 6. Day notes («Момент дня»): mood + time quality correlated with
    //    daily completion, so the stats insights and month charts look
    //    meaningful.
    await _generateDayNotes(dayAgg, now, rng);

    // 7. A few month goals for the current month (Цели месяца).
    await _generateMonthGoals(now);

    return scenario.habitCount;
  }

  Future<void> _generateMonth({
    required _HabitMeta meta,
    required int year,
    required int month,
    required DateTime now,
    required Random rng,
    required Map<int, _DayAgg> dayAgg,
  }) async {
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 0);
    final effectiveStart = meta.createdAt.isAfter(monthStart)
        ? meta.createdAt
        : monthStart;
    // Don't generate logs for the current month — that's "live" data
    final currentMonthStart = DateTime.utc(now.year, now.month, 1);
    if (!monthStart.isBefore(currentMonthStart)) return;

    final totalDays = daysBetweenInclusive(effectiveStart, monthEnd);
    if (totalDays <= 0) return;

    // Quality drifts upward over months (simulates user getting better)
    final monthIndex =
        (year - meta.createdAt.year) * 12 + (month - meta.createdAt.month);
    final quality = (meta.quality + monthIndex * 0.06 + rng.nextDouble() * 0.1)
        .clamp(0.05, 0.98);

    // Occasionally, have a "slump" month
    final isSlump = rng.nextDouble() < 0.12;
    final effectiveQuality = isSlump ? quality * 0.4 : quality;

    // Collect this (habit, month)'s logs and write them in ONE batched
    // transaction instead of a query per day.
    final entries = <HabitLogsCompanion>[];
    for (var d = 0; d < totalDays; d++) {
      final date = effectiveStart.add(Duration(days: d));
      if (date.isAfter(now)) break;

      // Determine if this day should have a log based on frequency
      if (!_shouldLogDay(meta, date)) continue;

      // Track the day for mood generation (expected vs actually done).
      final agg = dayAgg.putIfAbsent(date.unixSeconds, () => _DayAgg());
      agg.expected++;

      // Decide outcome: done / skip / (missed day → no log)
      final roll = rng.nextDouble();

      if (roll < effectiveQuality) {
        agg.done++;
        entries.add(
          HabitLogsCompanion.insert(
            habitId: meta.id,
            date: date.unixSeconds,
            status: const Value(LogStatus.done),
            loggedHour: Value(_hourForTimeOfDay(meta.tod, rng)),
          ),
        );
      } else if (roll < effectiveQuality + 0.1) {
        entries.add(
          HabitLogsCompanion.insert(
            habitId: meta.id,
            date: date.unixSeconds,
            status: const Value(LogStatus.skip),
          ),
        );
      }
    }
    await db.habitLogsDao.upsertLogs(entries);
  }

  /// Generate a «Момент дня» note for every past day that had expectations:
  /// mood 🟢/🟡/🔴 + time quality (1–5) correlated with that day's completion
  /// ratio, plus a memorable moment line for ~half of the days.
  Future<void> _generateDayNotes(
    Map<int, _DayAgg> dayAgg,
    DateTime now,
    Random rng,
  ) async {
    for (final entry in dayAgg.entries) {
      final date = dateFromUnix(entry.key);
      // Today is the user's live «Момент дня» — don't pre-fill it.
      if (!date.isBefore(now)) continue;

      final agg = entry.value;
      final ratio = agg.expected == 0 ? 0.0 : agg.done / agg.expected;
      final mood = _moodForRatio(ratio, rng);
      final quality = _qualityForRatio(ratio, rng);
      final moment = rng.nextDouble() < 0.55
          ? _momentPool[rng.nextInt(_momentPool.length)]
          : null;
      await db.dayNotesDao.upsertNote(
        entry.key,
        moment: moment,
        mood: mood,
        timeQuality: quality,
      );
    }
  }

  /// Maps a day's completion ratio to «рациональность времени» (1–5)
  /// with noise — mirrors the idea's «чем выше точка, тем я счастливее».
  static int? _qualityForRatio(double ratio, Random rng) {
    // ~15% of days have no rating at all (user skipped the ritual).
    if (rng.nextDouble() < 0.15) return null;
    final roll = rng.nextDouble();
    if (ratio >= 0.8) {
      return roll < 0.7
          ? 5
          : roll < 0.95
          ? 4
          : 3;
    } else if (ratio >= 0.4) {
      return roll < 0.25
          ? 4
          : roll < 0.8
          ? 3
          : 2;
    } else {
      return roll < 0.2
          ? 2
          : roll < 0.75
          ? 1
          : 3;
    }
  }

  /// Seed a few «Цели месяца» for the current month so the card has content.
  Future<void> _generateMonthGoals(DateTime now) async {
    final monthTs = DateTime.utc(now.year, now.month, 1).unixSeconds;
    final goals = [
      'Снять 4 видео на YouTube',
      'Сдать тесты по учёбе',
      'Прочитать книгу',
    ];
    for (final g in goals) {
      await db.monthlyGoalsDao.addGoal(monthTs, g);
    }
  }

  /// Maps a day's completion ratio to a mood with noise — good days are
  /// usually 🟢, skipped days usually 🟡, empty days usually 🔴.
  static DayMood _moodForRatio(double ratio, Random rng) {
    final roll = rng.nextDouble();
    if (ratio >= 0.8) {
      return roll < 0.75
          ? DayMood.good
          : roll < 0.95
          ? DayMood.ok
          : DayMood.bad;
    } else if (ratio >= 0.4) {
      return roll < 0.3
          ? DayMood.good
          : roll < 0.8
          ? DayMood.ok
          : DayMood.bad;
    } else {
      return roll < 0.1
          ? DayMood.good
          : roll < 0.4
          ? DayMood.ok
          : DayMood.bad;
    }
  }

  /// Generate pending logs for today so the Greenhouse screen shows habits.
  Future<void> _generateTodayLogs(List<_HabitMeta> metas, DateTime now) async {
    await db.habitLogsDao.upsertLogs([
      for (final meta in metas)
        if (!meta.createdAt.isAfter(now))
          HabitLogsCompanion.insert(
            habitId: meta.id,
            date: now.unixSeconds,
            status: const Value(LogStatus.pending),
          ),
    ]);
  }

  bool _shouldLogDay(_HabitMeta meta, DateTime date) {
    switch (meta.freq.type) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekdays:
        final days = parseWeekdays(meta.freq.value);
        return days.contains(date.weekday);
      case FrequencyType.xPerWeek:
        // Simplified: log on ~x random days per week
        return true;
      case FrequencyType.everyXDays:
        final x = parseXValue(meta.freq.value);
        final diff = date.difference(meta.createdAt.toMidnight).inDays;
        return diff % x == 0;
      case FrequencyType.cycle:
        return true;
    }
  }

  static int _hourForTimeOfDay(TimeOfDay tod, Random rng) => switch (tod) {
    TimeOfDay.morning => 6 + rng.nextInt(5), // 6–10
    TimeOfDay.afternoon => 12 + rng.nextInt(5), // 12–16
    TimeOfDay.evening => 18 + rng.nextInt(4), // 18–21
    TimeOfDay.anytime => 7 + rng.nextInt(14), // 7–20
  };
}

/// Per-day done/expected counts across all habits (for mood generation).
class _DayAgg {
  int expected = 0;
  int done = 0;
}

/// Memorable-moment lines for the seeded «Момент дня» notes.
const _momentPool = [
  'Встретил друга, гуляли у залива',
  'Красивый закат после работы',
  'Прочитал главу книги',
  'Поговорил с мамой по телефону',
  'Сходил на тренировку — бодрость весь день',
  'Удачный день на работе',
  'Приготовил новое блюдо',
  'Золотой вечер, белые ночи',
  'Написал пост в блог',
  'Долгая прогулка по городу',
  'Ранний подъём и продуктивное утро',
  'Созвонился с другом',
  'Получил комплимент',
  'Поработал над своим проектом',
  'Медитация и тишина',
  'Прочитал 30 минут перед сном',
  'Выучил новые слова',
  'День был ленивый',
  'Голова болела — день насмарку',
  'Сорвался со сном, встал поздно',
  'Хороший кофе и книга',
  'Пробежка в парке',
  'Интересный разговор, новые мысли',
  'Дождь весь день, остался дома',
];

class _HabitMeta {
  _HabitMeta({
    required this.id,
    required this.icon,
    required this.freq,
    required this.tod,
    required this.createdAt,
    required this.quality,
  });

  final int id;
  final HabitIcon icon;
  final _FreqTemplate freq;
  final TimeOfDay tod;
  final DateTime createdAt;

  /// Base "quality" of the user's habit — how likely they are to do it.
  final double quality;
}
