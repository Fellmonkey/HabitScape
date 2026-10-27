import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../domain/capsule.dart';
import '../../providers/letter_providers.dart';

/// «Капсулы времени»: write a letter to your future self, see locked ones,
/// and open the ones whose day has come.
class CapsuleScreen extends ConsumerStatefulWidget {
  const CapsuleScreen({super.key, this.autofocus = false});

  /// Focus the composer field on open (used from the letter screen).
  final bool autofocus;

  @override
  ConsumerState<CapsuleScreen> createState() => _CapsuleScreenState();
}

class _CapsuleScreenState extends ConsumerState<CapsuleScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _fieldFocusNode = FocusNode();
  CapsulePreset _preset = CapsulePreset.month;
  bool _expanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fieldFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave => _controller.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    final body = _controller.text.trim();
    final today = ref.read(todayDateProvider);
    final deliverAt = deliveryDate(today, _preset).unixSeconds;
    await ref
        .read(letterActionsProvider.notifier)
        .create(deliverAt: deliverAt, body: body);

    if (!mounted) return;
    Haptics.tap(ref.read(hapticsEnabledProvider));
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() => _saving = false);

    final open = dateFromUnix(deliverAt);
    final opensAt = formatShortDate(open, today: today);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Письмо откроется $opensAt')));
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(capsuleFeedProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Капсулы времени')),
      body: ListView(
        key: K.capsuleScreen,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildComposer(context),
          if (feed != null) ..._buildSections(feed),
        ],
      ),
    );
  }

  List<Widget> _buildSections(CapsuleFeed feed) {
    return [
      if (feed.due.isNotEmpty) ...[
        const SizedBox(height: 24),
        const AppSectionHeader(title: 'Готово к прочтению'),
        const SizedBox(height: 8),
        for (final letter in feed.due) ...[
          _CapsuleTile(capsule: letter, today: feed.today, due: true),
          const SizedBox(height: 8),
        ],
      ],
      if (feed.upcoming.isNotEmpty) ...[
        const SizedBox(height: 24),
        const AppSectionHeader(title: 'Закрыто'),
        const SizedBox(height: 8),
        for (final letter in feed.upcoming) ...[
          _CapsuleTile(capsule: letter, today: feed.today),
          const SizedBox(height: 8),
        ],
      ],
      if (feed.opened.isNotEmpty) ...[
        const SizedBox(height: 24),
        const AppSectionHeader(title: 'Прочитанные'),
        const SizedBox(height: 8),
        for (final letter in feed.opened) ...[
          _CapsuleTile(capsule: letter, today: feed.today, opened: true),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: AppRadius.borderS,
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
      ),
    );

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Новое письмо себе',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Одна фраза — 15–20 секунд. Откроется потом.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.easeInOutStrong,
              alignment: Alignment.topCenter,
              child: TextField(
                key: K.capsuleField,
                controller: _controller,
                focusNode: _fieldFocusNode,
                minLines: _expanded ? 4 : 1,
                maxLines: _expanded ? 8 : 1,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Что скажешь себе через месяц?',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.04,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: K.capsuleExpand,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? 'Свернуть' : 'Развернуть'),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in CapsulePreset.values)
                  ChoiceChip(
                    key: K.capsulePreset(preset.name),
                    label: Text(preset.label),
                    selected: _preset == preset,
                    onSelected: (_) => setState(() => _preset = preset),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            PressableScale(
              child: FilledButton.icon(
                key: K.capsuleSave,
                onPressed: _canSave ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_saving ? 'Отправляем…' : 'Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleTile extends StatelessWidget {
  const _CapsuleTile({
    required this.capsule,
    required this.today,
    this.due = false,
    this.opened = false,
  });

  final Letter capsule;
  final DateTime today;
  final bool due;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = daysUntil(capsule, today);

    final String subtitle;
    final IconData icon;
    final Color? color;
    if (due) {
      subtitle = 'Готово · это написал ты ${wroteAgoLabel(capsule)}';
      icon = Icons.markunread_mailbox_rounded;
      color = AppColors.warmAmber;
    } else if (opened) {
      subtitle = 'Открыто · ${wroteAgoLabel(capsule)}';
      icon = Icons.mark_email_read_outlined;
      color = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    } else {
      final opensAt = formatShortDate(
        dateFromUnix(capsule.deliverAt),
        today: today,
      );
      subtitle = 'Откроется $opensAt · осталось $left ${pluralDays(left)}';
      icon = Icons.inventory_2_outlined;
      color = AppColors.softLavender;
    }

    return Material(
      key: K.capsuleItem(capsule.id),
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderM,
      child: InkWell(
        borderRadius: AppRadius.borderM,
        onTap: () {
          if (opened || due) {
            context.push('/letter', extra: capsule);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Письмо ещё закрыто')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Opacity(
                opacity: opened ? 0.5 : 1,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: opened
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
