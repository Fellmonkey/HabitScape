// Russian date labels — single source of truth used across the app.

/// Month names in nominative case, indexed 1–12, [0] unused.
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

/// Month names in genitive case, indexed 1–12, [0] unused.
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

/// Short weekday names indexed by [DateTime.weekday], [0] unused.
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

/// Formats a full Russian date, e.g. "Monday, 14 August".
String formatFullDate(DateTime date) =>
    '${weekdayNames[date.weekday]}, ${date.day} ${monthNamesGenitive[date.month]}';
