import 'dart:convert';

import 'package:drift/drift.dart';

import '../settings/today.dart';
import '../utils/date_helpers.dart';
import 'app_database.dart';
import 'database_reset.dart';
import 'daos/day_notes_dao.dart';
import 'daos/habit_logs_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/letters_dao.dart';
import 'daos/monthly_goals_dao.dart';
import 'daos/weekly_intentions_dao.dart';
import 'enums.dart';

// Backup format version for forward compatibility.
// v2 adds the `letters` collection (time capsules).
const _backupVersion = 2;

/// Exports and imports the whole database as one UTF-8 JSON backup.
///
/// Sits at the persistence seam: it owns encoding, the collection list, the
/// old→new habit-id map, and the all-or-nothing import transaction. Callers
/// only choose a file and report the result.
class BackupService {
  BackupService(this._db, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final AppDatabase _db;

  /// The clock seam — used for export/import timestamps so tests can pin
  /// them instead of silently using the wall clock.
  final Clock _clock;

  HabitsDao get _habitsDao => _db.habitsDao;
  HabitLogsDao get _habitLogsDao => _db.habitLogsDao;
  DayNotesDao get _dayNotesDao => _db.dayNotesDao;
  MonthlyGoalsDao get _monthlyGoalsDao => _db.monthlyGoalsDao;
  LettersDao get _lettersDao => _db.lettersDao;
  WeeklyIntentionsDao get _weeklyIntentionsDao => _db.weeklyIntentionsDao;

  /// Exports the entire database as UTF-8 encoded JSON bytes.
  Future<Uint8List> exportBackup() async {
    final habits = await _habitsDao.getAllHabits();
    final logs = await _habitLogsDao.getAllLogs();
    final notes = await _dayNotesDao.getAllNotes();
    final goals = await _monthlyGoalsDao.getAllGoals();
    final letters = await _lettersDao.getAllLetters();
    final intentions = await _weeklyIntentionsDao.getAllIntentions();

    final data = {
      'version': _backupVersion,
      'exportedAt': _clock.now().toIso8601String(),
      'habits': habits.map(_habitToMap).toList(),
      'habitLogs': logs.map(_logToMap).toList(),
      'dayNotes': notes.map(_noteToMap).toList(),
      'monthlyGoals': goals.map(_goalToMap).toList(),
      'letters': letters.map(_letterToMap).toList(),
      'weeklyIntentions': intentions.map(_intentionToMap).toList(),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  /// Imports a full backup from UTF-8 bytes, replacing all existing data in a
  /// single transaction. Returns the number of habits imported.
  Future<int> importBackup(Uint8List bytes) async {
    final data = _decode(bytes);
    final habitsList = data['habits'] as List<dynamic>? ?? [];
    final logsList = data['habitLogs'] as List<dynamic>? ?? [];
    final notesList = data['dayNotes'] as List<dynamic>? ?? [];
    final goalsList = data['monthlyGoals'] as List<dynamic>? ?? [];
    final lettersList = data['letters'] as List<dynamic>? ?? [];
    final intentionsList = data['weeklyIntentions'] as List<dynamic>? ?? [];

    return DatabaseReset(_db).replaceWith(() async {
      final habitIdMap = <int, int>{};
      for (var i = 0; i < habitsList.length; i++) {
        final map = habitsList[i] as Map<String, dynamic>;
        final oldId = map['id'] as int? ?? i + 1;
        final newId = await _habitsDao.insertHabit(
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
        habitIdMap[oldId] = newId;
      }

      for (final l in logsList) {
        final map = l as Map<String, dynamic>;
        final oldHabitId = map['habitId'] as int;
        final newHabitId = habitIdMap[oldHabitId];
        if (newHabitId == null) {
          throw FormatException(
            'Backup log references unknown habit $oldHabitId',
          );
        }
        await _habitLogsDao.upsertLog(
          HabitLogsCompanion(
            habitId: Value(newHabitId),
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
        await _dayNotesDao.upsertNote(
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
        final id = await _monthlyGoalsDao.addGoal(
          map['month'] as int,
          map['title'] as String,
        );
        if (map['isDone'] == true) {
          await _monthlyGoalsDao.setGoalDone(id, isDone: true);
        }
      }

      // Import capsules, preserving their open state and dates.
      for (final l in lettersList) {
        final map = l as Map<String, dynamic>;
        final id = await _lettersDao.addLetter(
          deliverAt: map['deliverAt'] as int,
          body: map['body'] as String,
          createdAt:
              map['createdAt'] as int? ?? _clock.now().toMidnight.unixSeconds,
        );
        if (map['isOpened'] == true) {
          await _lettersDao.markOpened(
            id,
            map['openedAt'] as int? ?? _clock.now().toMidnight.unixSeconds,
          );
        }
        final reaction = map['reaction'] as String?;
        if (reaction != null) {
          await _lettersDao.setReaction(id, reaction);
        }
        final reply = map['reply'] as String?;
        if (reply != null) {
          await _lettersDao.setReply(id, reply);
        }
      }

      // Import weekly intentions.
      for (final i in intentionsList) {
        final map = i as Map<String, dynamic>;
        final intention = map['intention'] as String?;
        if (intention != null && intention.isNotEmpty) {
          await _weeklyIntentionsDao.setIntention(
            map['weekStart'] as int,
            intention,
          );
        }
      }

      return habitsList.length;
    });
  }

  Map<String, dynamic> _decode(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object');
    }
    final version = decoded['version'] as int? ?? 1;
    if (version > _backupVersion) {
      throw FormatException(
        'Unsupported backup version: $version (max supported: $_backupVersion)',
      );
    }
    return decoded;
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

  static Map<String, dynamic> _intentionToMap(WeeklyIntention i) => {
    'weekStart': i.weekStart,
    'intention': i.intention,
  };

  static Map<String, dynamic> _letterToMap(Letter l) => {
    'id': l.id,
    'createdAt': l.createdAt,
    'deliverAt': l.deliverAt,
    'body': l.body,
    'isOpened': l.isOpened,
    'openedAt': l.openedAt,
    'reaction': l.reaction,
    'reply': l.reply,
  };
}
