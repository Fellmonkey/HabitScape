/// Russian grammatical number for [n].
///
/// 1, 21, 31 → [one]; 2–4, 22–24 → [few]; 0, 5–20, 25–30 → [many].
enum RussianPlural { one, few, many }

RussianPlural russianPlural(int n) {
  final mod10 = n.abs() % 10;
  final mod100 = n.abs() % 100;
  if (mod100 >= 11 && mod100 <= 14) return RussianPlural.many;
  return switch (mod10) {
    1 => RussianPlural.one,
    2 || 3 || 4 => RussianPlural.few,
    _ => RussianPlural.many,
  };
}

/// Picks one of the three Russian noun forms for [n].
String pluralRu(
  int n, {
  required String one,
  required String few,
  required String many,
}) => switch (russianPlural(n)) {
  RussianPlural.one => one,
  RussianPlural.few => few,
  RussianPlural.many => many,
};

/// 1 день, 2 дня, 5 дней, 21 день.
String pluralDays(int n) => pluralRu(n, one: 'день', few: 'дня', many: 'дней');

/// 1 момент, 2 момента, 5 моментов.
String pluralMoments(int n) =>
    pluralRu(n, one: 'момент', few: 'момента', many: 'моментов');

/// "Каждый день", "Каждые 2 дня", "Каждые 5 дней".
String everyXDaysLabel(int x) {
  if (x == 1) return 'Каждый день';
  final prefix = russianPlural(x) == RussianPlural.one ? 'Каждый' : 'Каждые';
  return '$prefix $x ${pluralDays(x)}';
}
