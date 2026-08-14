// Localized (Russian) date labels — single source of truth used across the app.

/// Month names in nominative case (e.g. «Январь»), indexed 1–12, [0] unused.
const monthNames = [
  '',
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

/// Month names in genitive case (e.g. «января»), indexed 1–12, [0] unused.
const monthNamesGenitive = [
  '',
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// Short weekday names indexed by [DateTime.weekday] (1 = Пн … 7 = Вс),
/// [0] unused so `shortWeekdayNames[date.weekday]` always works.
const shortWeekdayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Full weekday names in nominative case, indexed 1–7, [0] unused.
const weekdayNames = [
  '',
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

/// Formats a date as e.g. «Понедельник, 14 августа».
String formatFullDate(DateTime date) =>
    '${weekdayNames[date.weekday]}, ${date.day} ${monthNamesGenitive[date.month]}';
