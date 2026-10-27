import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/database_reset.dart';
import '../database/enums.dart';
import '../domain/mood_rule.dart';
import '../settings/today.dart';
import '../utils/date_helpers.dart';
import '../utils/time_bucket.dart';
import '../domain/scheduling.dart';

/// A scenario that can be loaded via the debug menu.
class DebugScenario {
  const DebugScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.habitCount,
    required this.months,
    this.icon = '📦',
  });

  /// Stable identifier — UI buttons and tests bind to this, never to the
  /// human-readable [name], which is presentation and may change.
  final String id;
  final String name;
  final String description;
  final int habitCount;

  /// How many past months of data to generate (1 / 3 / 6 / 12).
  final int months;
  final String icon;
}

/// Looks a scenario up by its stable [id]; null when unknown.
DebugScenario? debugScenarioById(String id) {
  for (final scenario in debugScenarios) {
    if (scenario.id == id) return scenario;
  }
  return null;
}

/// Available scenarios for the debug menu.
const debugScenarios = [
  // ── Small ──
  DebugScenario(
    id: '5-1m',
    name: '5 привычек · 1 мес',
    description: 'Минимальный набор',
    habitCount: 5,
    months: 1,
    icon: '🌱',
  ),
  DebugScenario(
    id: '5-3m',
    name: '5 привычек · 3 мес',
    description: 'Квартал с малым числом',
    habitCount: 5,
    months: 3,
    icon: '🌿',
  ),
  DebugScenario(
    id: '5-6m',
    name: '5 привычек · 6 мес',
    description: 'Полгода',
    habitCount: 5,
    months: 6,
    icon: '🌳',
  ),
  DebugScenario(
    id: '5-12m',
    name: '5 привычек · 12 мес',
    description: 'Полный год',
    habitCount: 5,
    months: 12,
    icon: '🌲',
  ),
  // ── Medium ──
  DebugScenario(
    id: '30-1m',
    name: '30 привычек · 1 мес',
    description: 'Много привычек, мало истории',
    habitCount: 30,
    months: 1,
    icon: '📋',
  ),
  DebugScenario(
    id: '30-3m',
    name: '30 привычек · 3 мес',
    description: 'Активный пользователь',
    habitCount: 30,
    months: 3,
    icon: '📊',
  ),
  DebugScenario(
    id: '30-6m',
    name: '30 привычек · 6 мес',
    description: 'Полгода активности',
    habitCount: 30,
    months: 6,
    icon: '📈',
  ),
  DebugScenario(
    id: '30-12m',
    name: '30 привычек · 12 мес',
    description: 'Тяжёлый юзер, год',
    habitCount: 30,
    months: 12,
    icon: '🏋️',
  ),
  // ── Large ──
  DebugScenario(
    id: '90-1m',
    name: '90 привычек · 1 мес',
    description: 'Стресс-тест UI',
    habitCount: 90,
    months: 1,
    icon: '🔥',
  ),
  DebugScenario(
    id: '90-3m',
    name: '90 привычек · 3 мес',
    description: 'Массивный набор',
    habitCount: 90,
    months: 3,
    icon: '💥',
  ),
  DebugScenario(
    id: '90-12m',
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
  const _FreqTemplate(this.frequency);
  final HabitFrequency frequency;
}

final _freqTemplates = [
  const _FreqTemplate(DailyFrequency()),
  const _FreqTemplate(DailyFrequency()),
  _FreqTemplate(WeekdaysFrequency(const [1, 2, 3, 4, 5])),
  _FreqTemplate(WeekdaysFrequency(const [1, 3, 5])),
  const _FreqTemplate(XPerWeekFrequency(3)),
  const _FreqTemplate(XPerWeekFrequency(5)),
  const _FreqTemplate(EveryXDaysFrequency(2)),
  const _FreqTemplate(EveryXDaysFrequency(3)),
];

/// Seeds the database with realistic data for a [DebugScenario].
/// **Wipes all existing data** first.
class DebugDataSeeder {
  DebugDataSeeder(this.db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase db;
  final Clock _clock;

  /// The "today" this seeder anchors to — the clock seam, never a hidden
  /// `DateTime.now()`, so seeded scenarios are reproducible and pin-able.
  DateTime get _todayMidnight => _clock.now().toMidnight;

  /// Clears the database and populates it with the given scenario.
  /// Returns the number of habits created.
  Future<int> seed(DebugScenario scenario) async {
    // 1. Wipe every collection through the one reset path.
    await DatabaseReset(db).all();

    final rng = Random(scenario.habitCount * 1000 + scenario.months);
    final now = _todayMidnight;
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
          frequencyType: Value(freq.frequency.type.name),
          frequencyValue: Value(freq.frequency.encode()),
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
        if (m.isBefore(firstOfMonth(meta.createdAt))) {
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
      m = nextMonthStart(m);
    }

    // 5. Day notes: mood + time quality correlated with daily completion.
    await _generateDayNotes(dayAgg, now, rng);

    // 6. Month goals for the current month.
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
    // Skip the current month — that's "live" data.
    final currentMonthStart = firstOfMonth(now);
    if (!monthStart.isBefore(currentMonthStart)) return;

    final totalDays = daysBetweenInclusive(effectiveStart, monthEnd);
    if (totalDays <= 0) return;

    // Quality drifts upward over months (simulates the user improving).
    final monthIndex =
        (year - meta.createdAt.year) * 12 + (month - meta.createdAt.month);
    final quality = (meta.quality + monthIndex * 0.06 + rng.nextDouble() * 0.1)
        .clamp(0.05, 0.98);

    // Occasionally, have a "slump" month
    final isSlump = rng.nextDouble() < 0.12;
    final effectiveQuality = isSlump ? quality * 0.4 : quality;

    // Write this (habit, month)'s logs in one batched transaction.
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

  /// Generates a day note for every past day with expectations: mood + time
  /// quality correlated with completion, a moment line for ~half the days.
  Future<void> _generateDayNotes(
    Map<int, _DayAgg> dayAgg,
    DateTime now,
    Random rng,
  ) async {
    for (final entry in dayAgg.entries) {
      final date = dateFromUnix(entry.key);
      if (!date.isBefore(now)) continue; // today is the user's live note

      final agg = entry.value;
      final ratio = agg.expected == 0 ? 0.0 : agg.done / agg.expected;
      final mood = moodForCompletionRatio(ratio, rng.nextDouble());
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

  /// Maps a day's completion ratio to time quality (1–5) with noise.
  static int? _qualityForRatio(double ratio, Random rng) {
    if (rng.nextDouble() < 0.15) return null; // ~15% of days unrated
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

  /// Seeds a few month goals for the current month.
  Future<void> _generateMonthGoals(DateTime now) async {
    final monthTs = firstOfMonth(now).unixSeconds;
    final goals = [
      'Снять 4 видео на YouTube',
      'Сдать тесты по учёбе',
      'Прочитать книгу',
    ];
    for (final g in goals) {
      await db.monthlyGoalsDao.addGoal(monthTs, g);
    }
  }

  /// Seeds a capsule that opens today — for verifying the Day-X letter flow.
  Future<void> seedCapsuleDueToday() async {
    final now = _todayMidnight;
    await db.lettersDao.addLetter(
      deliverAt: now.unixSeconds,
      body: 'Привет из прошлого! Это письмо ты написал себе — и вот день X.',
      createdAt: shiftMonths(now, -1).unixSeconds,
    );
  }

  /// Seeds a locked capsule that opens in a month — for verifying the closed card.
  Future<void> seedCapsuleLocked() async {
    final now = _todayMidnight;
    await db.lettersDao.addLetter(
      deliverAt: shiftMonths(now, 1).unixSeconds,
      body: 'Секретное письмо будущему себе.',
      createdAt: now.unixSeconds,
    );
  }

  /// Seeds a realistic capsule + intentions history: several opened capsules
  /// (one with a reply), several locked upcoming ones, and weekly intentions
  /// across the past weeks — so the capsule stats strip and the stats screen's
  /// «Намерения недель» card have something to show.
  Future<void> seedCapsulesAndIntentions() async {
    final now = _todayMidnight;

    // ── Capsules ────────────────────────────────────────────
    // Opened: written a month ago, opened weeks ago. One carries a reply.
    final opened = [
      (body: 'Не бросай бег', reply: 'Не бросил: 3 пробежки в неделю'),
      (body: 'Помни про цель года', reply: null),
      (body: 'Позвони маме чаще', reply: null),
    ];
    for (var i = 0; i < opened.length; i++) {
      final createdAt = shiftMonths(now, -3 - i).unixSeconds;
      final deliverAt = shiftMonths(now, -2 - i).unixSeconds;
      final id = await db.lettersDao.addLetter(
        deliverAt: deliverAt,
        body: opened[i].body,
        createdAt: createdAt,
      );
      final openedAt = shiftMonths(now, -1 - i).unixSeconds;
      if (opened[i].reply != null) {
        await db.lettersDao.setReply(id, opened[i].reply);
      }
      await db.lettersDao.markOpened(id, openedAt);
    }

    // Locked (upcoming): due next week and in a month.
    await db.lettersDao.addLetter(
      deliverAt: now.add(const Duration(days: 7)).unixSeconds,
      body: 'Что изменилось за неделю?',
      createdAt: now.unixSeconds,
    );
    await db.lettersDao.addLetter(
      deliverAt: shiftMonths(now, 1).unixSeconds,
      body: 'Письмо себе через месяц',
      createdAt: now.unixSeconds,
    );

    // ── Weekly intentions ───────────────────────────────────
    // Past weeks (2–8 weeks ago), so the following week of each has already
    // happened and the "reality" percentage can be computed.
    final intentions = [
      'Бег по вторникам',
      'Ложиться до полуночи',
      'Без сахара по будням',
      'Читать 20 минут в день',
      'Разобрать рабочий стол',
      'Звонить маме по воскресеньям',
      'Гулять в обед',
    ];
    for (var i = 0; i < intentions.length; i++) {
      final weekStart = weekStartOf(now).subtract(Duration(days: 7 * (i + 2)));
      await db.weeklyIntentionsDao.setIntention(
        weekStart.unixSeconds,
        intentions[i],
      );
    }
  }

  /// Seeds data for idea D — «Итог недели»: a realistic current week with
  /// moods, logs and a saved previous-week intention, so the card renders its
  /// full analysis + reminder state.
  Future<void> seedWeekSummary() async {
    final now = _todayMidnight;
    final start = weekStartOf(now);
    final rng = Random(42);

    // Two habits: one strong, one weak — the weakest pick should be readable.
    final strong = await db.habitsDao.insertHabit(
      HabitsCompanion(
        name: const Value('Чтение книг'),
        createdAt: Value(start.subtract(const Duration(days: 30)).unixSeconds),
        icon: const Value('book'),
        frequencyType: const Value('daily'),
        frequencyValue: const Value('{}'),
        timeOfDay: const Value('evening'),
      ),
    );
    final weak = await db.habitsDao.insertHabit(
      HabitsCompanion(
        name: const Value('Бег'),
        createdAt: Value(start.subtract(const Duration(days: 30)).unixSeconds),
        icon: const Value('run'),
        frequencyType: const Value('daily'),
        frequencyValue: const Value('{}'),
        timeOfDay: const Value('morning'),
      ),
    );

    // Log the elapsed days of the current week (Mon → today).
    var day = start;
    while (!day.isAfter(now)) {
      await db.habitLogsDao.upsertLog(
        HabitLogsCompanion(
          habitId: Value(strong),
          date: Value(day.unixSeconds),
          status: const Value(LogStatus.done),
          loggedHour: const Value(21),
        ),
      );
      // Weak habit: done ~1 day out of 3 so it clearly lags. Days without a
      // done log get no row at all — exactly what production produces.
      final doneToday = day.difference(start).inDays % 3 == 0;
      if (doneToday) {
        await db.habitLogsDao.upsertLog(
          HabitLogsCompanion(
            habitId: Value(weak),
            date: Value(day.unixSeconds),
            status: const Value(LogStatus.done),
            loggedHour: const Value(8),
          ),
        );
      }
      // Alternative a mood note, ~2/3 good.
      if (rng.nextDouble() < 0.85) {
        await db.dayNotesDao.upsertNote(
          day.unixSeconds,
          moment: rng.nextDouble() < 0.5 ? 'День в порядке' : null,
          mood: rng.nextDouble() < 0.66 ? DayMood.good : DayMood.ok,
        );
      }
      day = day.add(const Duration(days: 1));
    }

    // One past week's intention — shown as the reminder line.
    final previousWeekStart = start.subtract(const Duration(days: 7));
    await db.weeklyIntentionsDao.setIntention(
      previousWeekStart.unixSeconds,
      'Бег по вторникам',
    );
  }

  /// Seeds data for «Итог месяца»: a realistic closing month — two habits
  /// (strong/weak), logs across the elapsed days, moods and goals — so the
  /// month summary card (or the debug preview) has something to summarize.
  Future<void> seedMonthSummary() async {
    final now = _todayMidnight;
    final start = firstOfMonth(now);
    final rng = Random(43);

    // Two habits: one strong, one weak — the best-habit pick should be
    // readable, and the completion percentage neither 0 nor 100.
    final strong = await db.habitsDao.insertHabit(
      HabitsCompanion(
        name: const Value('Чтение книг'),
        createdAt: Value(start.subtract(const Duration(days: 30)).unixSeconds),
        icon: const Value('book'),
        frequencyType: const Value('daily'),
        frequencyValue: const Value('{}'),
        timeOfDay: const Value('evening'),
      ),
    );
    final weak = await db.habitsDao.insertHabit(
      HabitsCompanion(
        name: const Value('Бег'),
        createdAt: Value(start.subtract(const Duration(days: 30)).unixSeconds),
        icon: const Value('run'),
        frequencyType: const Value('daily'),
        frequencyValue: const Value('{}'),
        timeOfDay: const Value('morning'),
      ),
    );

    // Log the elapsed days of the current month (1st → today).
    var day = start;
    while (!day.isAfter(now)) {
      await db.habitLogsDao.upsertLog(
        HabitLogsCompanion(
          habitId: Value(strong),
          date: Value(day.unixSeconds),
          status: const Value(LogStatus.done),
          loggedHour: const Value(21),
        ),
      );
      // Weak habit: done ~1 day out of 3 so it clearly lags.
      final doneToday = day.difference(start).inDays % 3 == 0;
      if (doneToday) {
        await db.habitLogsDao.upsertLog(
          HabitLogsCompanion(
            habitId: Value(weak),
            date: Value(day.unixSeconds),
            status: const Value(LogStatus.done),
            loggedHour: const Value(8),
          ),
        );
      }
      // Most days carry a mood note, ~2/3 good.
      if (rng.nextDouble() < 0.85) {
        await db.dayNotesDao.upsertNote(
          day.unixSeconds,
          moment: rng.nextDouble() < 0.5 ? 'День в порядке' : null,
          mood: rng.nextDouble() < 0.66 ? DayMood.good : DayMood.ok,
        );
      }
      day = day.add(const Duration(days: 1));
    }

    // Three goals for the month; one already done.
    await _generateMonthGoals(now);
    final goals = await db.monthlyGoalsDao.getGoalsForMonth(start.unixSeconds);
    if (goals.isNotEmpty) {
      await db.monthlyGoalsDao.setGoalDone(goals.first.id, isDone: true);
    }
  }

  /// Maps a day's completion ratio to a mood with noise — the shared
  /// generation curve in `core/domain/mood_rule.dart`, which mirrors the
  /// relationship the stats insight measures.

  bool _shouldLogDay(_HabitMeta meta, DateTime date) {
    return isExpectedOn(
      frequency: meta.freq.frequency,
      createdAt: meta.createdAt,
      today: date,
    );
  }

  static int _hourForTimeOfDay(TimeOfDay tod, Random rng) => switch (tod) {
    TimeOfDay.morning => _jittered(rng, TimeBucket.morning),
    TimeOfDay.afternoon => _jittered(rng, TimeBucket.day),
    TimeOfDay.evening => _jittered(rng, TimeBucket.evening),
    TimeOfDay.anytime => switch (rng.nextInt(3)) {
      0 => _jittered(rng, TimeBucket.morning),
      1 => _jittered(rng, TimeBucket.day),
      _ => _jittered(rng, TimeBucket.evening),
    },
  };

  /// A plausible hour inside [bucket] (representative ± 2) — the same
  /// boundaries the rhythm stats use, so seeded hours always classify back
  /// into the bucket the habit belongs to.
  static int _jittered(Random rng, TimeBucket bucket) {
    final base = representativeHourForBucket(bucket);
    return (base - 2 + rng.nextInt(5)).clamp(0, 23);
  }
}

/// Per-day done/expected counts across all habits.
class _DayAgg {
  int expected = 0;
  int done = 0;
}

/// Memorable-moment lines for seeded day notes.
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

  /// Base quality — how likely the user is to do this habit.
  final double quality;
}
