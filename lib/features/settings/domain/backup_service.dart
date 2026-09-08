import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/data/day_notes_dao.dart';
import '../../habits/data/habit_logs_dao.dart';
import '../../habits/data/habits_dao.dart';
import '../../habits/data/monthly_goals_dao.dart';
import '../../capsule/data/letters_dao.dart';

// Backup format version for forward compatibility.
// v2 adds the `letters` collection (time capsules).
const _backupVersion = 2;

class BackupService {
  BackupService({
    required this.habitsDao,
    required this.habitLogsDao,
    required this.dayNotesDao,
    required this.monthlyGoalsDao,
    required this.lettersDao,
  });

  final HabitsDao habitsDao;
  final HabitLogsDao habitLogsDao;
  final DayNotesDao dayNotesDao;
  final MonthlyGoalsDao monthlyGoalsDao;
  final LettersDao lettersDao;

  /// Exports the entire database to a JSON string.
  Future<String> exportToJson() async {
    final habits = await habitsDao.getAllHabits();
    final logs = await habitLogsDao.getAllLogs();
    final notes = await dayNotesDao.getAllNotes();
    final goals = await monthlyGoalsDao.getAllGoals();
    final letters = await lettersDao.getAllLetters();

    final data = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits.map(_habitToMap).toList(),
      'habitLogs': logs.map(_logToMap).toList(),
      'dayNotes': notes.map(_noteToMap).toList(),
      'monthlyGoals': goals.map(_goalToMap).toList(),
      'letters': letters.map(_letterToMap).toList(),
    };

    return jsonEncode(data);
  }

  /// Imports a full backup from JSON, replacing all existing data.
  /// Returns the number of habits imported.
  Future<int> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;
    if (version > _backupVersion) {
      throw FormatException(
        'Unsupported backup version: $version (max supported: $_backupVersion)',
      );
    }

    final habitsList = data['habits'] as List<dynamic>? ?? [];
    final logsList = data['habitLogs'] as List<dynamic>? ?? [];
    final notesList = data['dayNotes'] as List<dynamic>? ?? [];
    final goalsList = data['monthlyGoals'] as List<dynamic>? ?? [];
    final lettersList = data['letters'] as List<dynamic>? ?? [];

    // Clear existing data (order matters for FK constraints).
    await habitLogsDao.deleteAllLogs();
    await dayNotesDao.deleteAllNotes();
    await monthlyGoalsDao.deleteAllGoals();
    await lettersDao.deleteAllLetters();
    await habitsDao.deleteAllHabits();

    for (final h in habitsList) {
      final map = h as Map<String, dynamic>;
      await habitsDao.insertHabit(
        HabitsCompanion(
          name: Value(map['name'] as String),
          category: Value(map['category'] as String? ?? 'general'),
          icon: Value(
            map['icon'] as String? ??
                map['seedArchetype'] as String? ??
                'check',
          ),
          frequencyType: Value(map['frequencyType'] as String? ?? 'daily'),
          frequencyValue: Value(map['frequencyValue'] as String? ?? '{}'),
          timeOfDay: Value(map['timeOfDay'] as String? ?? 'anytime'),
          isFocus: Value(map['isFocus'] as bool? ?? false),
          isArchived: Value(map['isArchived'] as bool? ?? false),
          createdAt: Value(map['createdAt'] as int),
        ),
      );
    }

    for (final l in logsList) {
      final map = l as Map<String, dynamic>;
      await habitLogsDao.upsertLog(
        HabitLogsCompanion(
          habitId: Value(map['habitId'] as int),
          date: Value(map['date'] as int),
          status: Value(
            LogStatus.fromString(map['status'] as String? ?? 'pending'),
          ),
          loggedHour: Value(map['loggedHour'] as int?),
        ),
      );
    }

    for (final n in notesList) {
      final map = n as Map<String, dynamic>;
      await dayNotesDao.upsertNote(
        map['date'] as int,
        moment: map['moment'] as String?,
        mood: map['mood'] == null
            ? null
            : DayMood.fromString(map['mood'] as String),
        timeQuality: map['timeQuality'] as int?,
      );
    }

    // Import monthly goals; the fresh id lets us set done on the same row.
    for (final g in goalsList) {
      final map = g as Map<String, dynamic>;
      final id = await monthlyGoalsDao.addGoal(
        map['month'] as int,
        map['title'] as String,
      );
      if (map['isDone'] == true) {
        await monthlyGoalsDao.setGoalDone(id, isDone: true);
      }
    }

    // Import capsules, preserving their open state and dates.
    for (final l in lettersList) {
      final map = l as Map<String, dynamic>;
      final id = await lettersDao.addLetter(
        deliverAt: map['deliverAt'] as int,
        body: map['body'] as String,
        createdAt: map['createdAt'] as int?,
      );
      if (map['isOpened'] == true) {
        await lettersDao.markOpened(
          id,
          map['openedAt'] as int? ?? DateTime.now().toMidnight.unixSeconds,
        );
      }
    }

    return habitsList.length;
  }

  // ── Serialization helpers ────────────────────────────────────

  static Map<String, dynamic> _habitToMap(Habit h) => {
    'id': h.id,
    'name': h.name,
    'category': h.category,
    'icon': h.icon,
    'frequencyType': h.frequencyType,
    'frequencyValue': h.frequencyValue,
    'timeOfDay': h.timeOfDay,
    'isFocus': h.isFocus,
    'isArchived': h.isArchived,
    'createdAt': h.createdAt,
  };

  static Map<String, dynamic> _logToMap(HabitLog l) => {
    'id': l.id,
    'habitId': l.habitId,
    'date': l.date,
    'status': l.status.name,
    'loggedHour': l.loggedHour,
  };

  static Map<String, dynamic> _noteToMap(DayNote n) => {
    'date': n.date,
    'moment': n.moment,
    'mood': n.mood?.name,
    'timeQuality': n.timeQuality,
  };

  static Map<String, dynamic> _goalToMap(MonthlyGoal g) => {
    'month': g.month,
    'title': g.title,
    'isDone': g.isDone,
  };

  static Map<String, dynamic> _letterToMap(Letter l) => {
    'id': l.id,
    'createdAt': l.createdAt,
    'deliverAt': l.deliverAt,
    'body': l.body,
    'isOpened': l.isOpened,
    'openedAt': l.openedAt,
  };
}
