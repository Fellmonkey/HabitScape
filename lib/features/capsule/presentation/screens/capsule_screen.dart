import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/capsule.dart';
import '../../providers/letter_providers.dart';

/// «Капсулы времени»: write a letter to your future self, see locked ones,
/// and open the ones whose day has come.
class CapsuleScreen extends ConsumerStatefulWidget {
  const CapsuleScreen({super.key, this.autofocus = false});

  /// Focus the composer field on open (used by «Ответить себе»).
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
    final deliverAt = deliveryDate(DateTime.now(), _preset).unixSeconds;
    await ref
        .read(letterActionsProvider.notifier)
        .create(deliverAt: deliverAt, body: body);

    if (!mounted) return;
    Haptics.tap(ref.read(hapticsEnabledProvider));
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() => _saving = false);

    final open = dateFromUnix(deliverAt);
    final dayMonth = '${open.day} ${monthNamesGenitive[open.month]}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Письмо откроется $dayMonth')));
  }

  @override
  Widget build(BuildContext context) {
    final letters = ref.watch(allCapsulesProvider).value ?? const <Letter>[];
    final today = DateTime.now();

    final upcoming = letters
        .where((l) => capsuleStatus(l, today) == CapsuleStatus.upcoming)
        .toList();
    final due = letters
        .where((l) => capsuleStatus(l, today) == CapsuleStatus.due)
        .toList();
    final opened = letters
        .where((l) => capsuleStatus(l, today) == CapsuleStatus.opened)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Капсулы времени')),
      body: ListView(
        key: K.capsuleScreen,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildComposer(context),
          if (due.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Готово к прочтению'),
            const SizedBox(height: 8),
            for (final letter in due) ...[
              _CapsuleTile(capsule: letter, due: true),
              const SizedBox(height: 8),
            ],
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Закрыто'),
            const SizedBox(height: 8),
            for (final letter in upcoming) ...[
              _CapsuleTile(capsule: letter),
              const SizedBox(height: 8),
            ],
          ],
          if (opened.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Прочитанные'),
            const SizedBox(height: 8),
            for (final letter in opened) ...[
              _CapsuleTile(capsule: letter, opened: true),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
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
            TextField(
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
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
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
            FilledButton.icon(
              key: K.capsuleSave,
              onPressed: _canSave ? _save : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _CapsuleTile extends StatelessWidget {
  const _CapsuleTile({
    required this.capsule,
    this.due = false,
    this.opened = false,
  });

  final Letter capsule;
  final bool due;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
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
      subtitle =
          'Откроется ${_shortDate(capsule)} · осталось $left ${pluralDays(left)}';
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

String _shortDate(Letter letter) {
  final date = dateFromUnix(letter.deliverAt);
  final dayMonth = '${date.day} ${monthNamesGenitive[date.month]}';
  return date.year == DateTime.now().year ? dayMonth : '$dayMonth ${date.year}';
}
