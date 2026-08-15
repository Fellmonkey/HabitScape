/// One step of an onboarding tour: a short title + one-line description
/// shown in the spotlight tooltip.
class TourStep {
  const TourStep(this.title, this.description);

  final String title;
  final String description;
}

/// Copy for all onboarding tours. Kept in one place so the integration
/// tests can assert on the exact texts.
abstract final class TourContent {
  // ── Greenhouse (Теплица) ─────────────────────────────────
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

  // ── Month spread (Разворот месяца) ───────────────────────
  static const spreadSwipe = TourStep(
    'Листай месяцы',
    'Листай влево-вправо или стрелки вверху — прошлые месяцы тоже открыты.',
  );
  static const spreadDay = TourStep(
    'День — по нажатию',
    'Тапни по дню: настроение, момент и как прошёл день.',
  );

  // ── Settings («Ещё») ─────────────────────────────────────
  static const settingsHere = TourStep(
    'Здесь настройки',
    'Вкладка называется «Ещё», но это раздел настроек: '
        'резервное копирование, архив, вибрация.',
  );
}
