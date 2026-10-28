class FeatureHint {
  const FeatureHint({
    required this.key,
    required this.message,
    required this.minDays,
  });
  final String key;
  final String message;
  final int minDays;
}

const featureHints = <FeatureHint>[
  FeatureHint(
    key: 'echo',
    message:
        'Открылось Эхо: прошлые моменты теперь показываются под Моментом дня.',
    minDays: 3,
  ),
  FeatureHint(
    key: 'week_summary',
    message: 'Открылся Итог недели: по воскресеньям появляется мягкое резюме.',
    minDays: 7,
  ),
  FeatureHint(
    key: 'month_goals',
    message: 'Открылись Цели месяца: их можно вести в Развороте месяца.',
    minDays: 14,
  ),
  FeatureHint(
    key: 'capsules',
    message: 'Открылись Капсулы времени: письмо себе в будущее.',
    minDays: 30,
  ),
];
