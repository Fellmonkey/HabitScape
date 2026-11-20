/// Russian copy for Keep a Changelog section headings. Lives in presentation:
/// the parser and repository stay language-agnostic and receive this mapper
/// from the provider layer.
const changelogSectionTitles = <String, String>{
  'added': 'Добавлено',
  'changed': 'Изменено',
  'fixed': 'Исправлено',
  'removed': 'Удалено',
  'deprecated': 'Устарело',
  'security': 'Безопасность',
  'improved': 'Улучшено',
  'documentation': 'Документация',
  'docs': 'Документация',
};

String localizedChangelogSection(String raw) =>
    changelogSectionTitles[raw.toLowerCase()] ?? raw;
