class TourStep {
  const TourStep(this.title, this.description);
  final String title;
  final String description;
}

abstract final class TourContent {
  static const greenhouseMoment = TourStep(
    'Момент дня',
    'Сердце приложения: одна строка о том, что запомнилось, и цвет дня. Нажми, чтобы записать.',
  );
  static const spreadSwipe = TourStep(
    'Листай месяцы',
    'Листай влево-вправо или стрелки вверху — прошлые месяцы тоже открыты.',
  );
  static const spreadDay = TourStep(
    'День — по нажатию',
    'Нажми на день: настроение, момент и как прошёл день.',
  );
  static const settingsHere = TourStep(
    'Настройки',
    'Здесь резервное копирование, архив привычек, тема и вибрация.',
  );
}
