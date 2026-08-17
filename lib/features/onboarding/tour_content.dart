/// One onboarding tour step: a title + one-line description.
class TourStep {
  const TourStep(this.title, this.description);

  final String title;
  final String description;
}

/// Copy for all onboarding tours, kept in one place so tests can assert on it.
abstract final class TourContent {
  // ── Greenhouse ────────────────────────────────────────────
  static const greenhouseMoment = TourStep(
    'Момент дня',
    'Сердце приложения: одна строка о том, что запомнилось, и цвет дня. '
        'Нажми, чтобы записать.',
  );
  static const greenhouseSpread = TourStep(
    'Разворот месяца',
    'Здесь вся история: календарь по месяцам и лента «одна строка о дне».',
  );
  static const greenhouseHabit = TourStep(
    'Отметки привычек',
    'Проведи по карточке вбок — пропустить или удалить. '
        'Удерживай палец, чтобы выполнить.',
  );

  // ── Month spread ──────────────────────────────────────────
  static const spreadSwipe = TourStep(
    'Листай месяцы',
    'Листай влево-вправо или стрелки вверху — прошлые месяцы тоже открыты.',
  );
  static const spreadDay = TourStep(
    'День — по нажатию',
    'Тапни по дню: настроение, момент и как прошёл день.',
  );

  // ── Settings ──────────────────────────────────────────────
  static const settingsHere = TourStep(
    'Настройки',
    'Здесь резервное копирование, архив привычек, тема и вибрация. '
        'Советуем сразу сделать экспорт данных.',
  );
}
