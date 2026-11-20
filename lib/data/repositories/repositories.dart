import '../../core/database/app_database.dart';
import 'day_note_repository.dart';
import 'goal_repository.dart';
import 'habit_repository.dart';
import 'letter_repository.dart';

/// Bundles every repository behind one injected object.
class Repositories {
  Repositories(AppDatabase db)
    : habits = HabitRepository(db),
      dayNotes = DayNoteRepository(db.dayNotesDao),
      letters = LetterRepository(db.lettersDao),
      goals = GoalRepository(db.monthlyGoalsDao, db.weeklyIntentionsDao);

  final HabitRepository habits;
  final DayNoteRepository dayNotes;
  final LetterRepository letters;
  final GoalRepository goals;
}
