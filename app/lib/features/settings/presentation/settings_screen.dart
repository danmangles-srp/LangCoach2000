// Settings screen (UX feedback item 3). Reachable from the Today queue's app
// bar. Two preferences ship now: the auto-advance toggle (gates T8.2 playback
// advance on completion) and the theme mode. Both persist instantly via
// [AppSettingsNotifier].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/report/presentation/weekly_report_settings_section.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/features/settings/domain/app_settings.dart';
import 'package:rivendell/l10n/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.skip_next_rounded),
            title: Text(strings.settingsAutoAdvanceTitle),
            subtitle: Text(
              strings.settingsAutoAdvanceSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: settings.autoAdvanceNext,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setAutoAdvance(value: v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              strings.settingsThemeTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ThemeSegmented(
              value: settings.themePreference,
              onChanged: (v) =>
                  ref.read(appSettingsProvider.notifier).setThemePreference(v),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const WeeklyReportSettingsSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const _AiImagePromptSection(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const _AiImageQueueTile(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// User-tunable AI image prompt template (T19.6). Pre-filled with the current
/// persisted template (default on first run). Persists on every change so the
/// edit survives a process kill without depending on focus loss or dispose
/// (both unreliable on Android). Reset restores the canonical pictographic
/// body.
class _AiImagePromptSection extends ConsumerStatefulWidget {
  const _AiImagePromptSection();

  @override
  ConsumerState<_AiImagePromptSection> createState() =>
      _AiImagePromptSectionState();
}

class _AiImagePromptSectionState extends ConsumerState<_AiImagePromptSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(appSettingsProvider).aiImagePromptTemplate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _persist() {
    ref
        .read(appSettingsProvider.notifier)
        .setAiImagePromptTemplate(_controller.text);
  }

  void _resetToDefault() {
    _controller.text = defaultAiImagePrompt;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.settingsAiImagePromptTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.settingsAiImagePromptSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            // Persist per change: a focus-loss or dispose trigger is unreliable
            // on Android (tapping inert space doesn't unfocus; a process kill
            // may skip dispose). The notifier dedupes unchanged writes.
            onChanged: (_) => _persist(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(strings.settingsAiImagePromptReset),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiImageQueueTile extends ConsumerWidget {
  const _AiImageQueueTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(aiImageQueueSnapshotProvider).value;
    final pending = snap?.pending.length ?? 0;

    return ListTile(
      leading: const Icon(Icons.auto_awesome_motion_outlined),
      title: Text(strings.settingsAiImageQueueTitle),
      subtitle: Text(
        strings.settingsAiImageQueueSubtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: pending > 0 ? _PendingBadge(count: pending) : null,
      onTap: () => context.push('/settings/ai-image-queue'),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  const _ThemeSegmented({required this.value, required this.onChanged});

  final ThemePreference value;
  final ValueChanged<ThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final segments = <(ThemePreference, String)>[
      (ThemePreference.system, strings.settingsThemeSystem),
      (ThemePreference.light, strings.settingsThemeLight),
      (ThemePreference.dark, strings.settingsThemeDark),
    ];
    return SegmentedButton<ThemePreference>(
      segments: [
        for (final s in segments) ButtonSegment(value: s.$1, label: Text(s.$2)),
      ],
      selected: {value},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) onChanged(s.first);
      },
      showSelectedIcon: false,
    );
  }
}
