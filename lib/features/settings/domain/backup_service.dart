import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../habits/data/day_notes_dao.dart';
import '../../habits/data/habit_logs_dao.dart';
import '../../habits/data/habits_dao.dart';

// Backup format version for forward compatibility.
const _backupVersion = 1;

class BackupService {
  BackupService({
    required this.habitsDao,
    required this.habitLogsDao,
    required this.dayNotesDao,
  });

  final HabitsDao habitsDao;
  final HabitLogsDao habitLogsDao;
  final DayNotesDao dayNotesDao;

  /// Export the entire database to a JSON string.
  Future<String> exportToJson() async {
    final habits = await habitsDao.getAllHabits();
    final logs = await habitLogsDao.getAllLogs();
    final notes = await dayNotesDao.getAllNotes();

    final data = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits.map(_habitToMap).toList(),
      'habitLogs': logs.map(_logToMap).toList(),
      'dayNotes': notes.map(_noteToMap).toList(),
    };

    return jsonEncode(data);
  }

  /// Import a full backup from JSON, replacing all existing data.
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

    // Clear existing data (order matters for FK constraints).
    await habitLogsDao.deleteAllLogs();
    await dayNotesDao.deleteAllNotes();
    await habitsDao.deleteAllHabits();

    // Import habits.
    for (final h in habitsList) {
      final map = h as Map<String, dynamic>;
      await habitsDao.insertHabit(
        HabitsCompanion(
          name: Value(map['name'] as String),
          category: Value(map['category'] as String? ?? 'general'),
          seedArchetype: Value(map['seedArchetype'] as String? ?? 'oak'),
          frequencyType: Value(map['frequencyType'] as String? ?? 'daily'),
          frequencyValue: Value(map['frequencyValue'] as String? ?? '{}'),
          timeOfDay: Value(map['timeOfDay'] as String? ?? 'anytime'),
          isFocus: Value(map['isFocus'] as bool? ?? false),
          isArchived: Value(map['isArchived'] as bool? ?? false),
          createdAt: Value(map['createdAt'] as int),
        ),
      );
    }

    // Import logs.
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

    // Import day notes.
    for (final n in notesList) {
      final map = n as Map<String, dynamic>;
      await dayNotesDao.upsertNote(
        map['date'] as int,
        moment: map['moment'] as String?,
        mood: map['mood'] == null
            ? null
            : DayMood.fromString(map['mood'] as String),
      );
    }

    return habitsList.length;
  }

  // ── Serialization helpers ────────────────────────────────────

  static Map<String, dynamic> _habitToMap(Habit h) => {
    'id': h.id,
    'name': h.name,
    'category': h.category,
    'seedArchetype': h.seedArchetype,
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
  };
}
