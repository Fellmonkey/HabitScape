import 'package:flutter/material.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Brand, version, release notes and source link — the quiet closing card of
/// Settings. Built from the same glass, sage and amber language as the rest of
/// the app, but with a softer editorial hierarchy than a stack of list tiles.
class AboutCard extends StatelessWidget {
  const AboutCard({
    required this.onOpenSource,
    required this.onOpenChangelog,
    super.key,
  });

  final VoidCallback onOpenSource;
  final VoidCallback onOpenChangelog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = context.palette;
    final onSurface = theme.colorScheme.onSurface;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // A pair of almost-invisible light pools gives the card depth without
          // introducing a second visual language next to the glass tiles.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.sage.withValues(alpha: isDark ? 0.12 : 0.055),
                      Colors.transparent,
                      palette.amber.withValues(alpha: isDark ? 0.09 : 0.045),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -58,
            right: -38,
            child: _AmbientOrb(
              size: 168,
              color: palette.sage.withValues(alpha: isDark ? 0.18 : 0.12),
            ),
          ),
          Positioned(
            bottom: -78,
            left: -56,
            child: _AmbientOrb(
              size: 196,
              color: palette.amber.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _BrandMark(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HabitScape',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Бережный трекер привычек',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                          const SizedBox(height: 9),
                          _VersionPill(isDark: isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Одна строка о дне — память на годы.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _AboutAction(
                  key: K.settingsChangelog,
                  icon: Icons.auto_awesome_rounded,
                  accent: palette.amber,
                  title: 'Что нового',
                  subtitle: 'История изменений',
                  onTap: onOpenChangelog,
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: onSurface.withValues(alpha: 0.07),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _AuthorAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fellmonkey',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Автор и разработчик',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: K.settingsAboutAuthor,
                    borderRadius: AppRadius.borderS,
                    onTap: onOpenSource,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Исходный код на GitHub',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: onSurface.withValues(alpha: 0.32),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = context.palette;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.sage, palette.emerald],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.sage.withValues(alpha: isDark ? 0.16 : 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.eco_rounded, color: theme.colorScheme.onPrimary, size: 30),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: palette.amber,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isDark ? 0.10 : 0.55,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: context.palette.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Версия ${AppConstants.appVersion}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutAction extends StatelessWidget {
  const _AboutAction({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderM,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.colorScheme.surface.withValues(alpha: isDark ? 0.12 : 0.72),
              accent.withValues(alpha: isDark ? 0.10 : 0.075),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.borderM,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.16 : 0.14),
                    borderRadius: AppRadius.borderS,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = context.palette;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.lavender.withValues(alpha: isDark ? 0.28 : 0.30),
            palette.sage.withValues(alpha: isDark ? 0.20 : 0.22),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.55),
        ),
      ),
      child: Text(
        'F',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
