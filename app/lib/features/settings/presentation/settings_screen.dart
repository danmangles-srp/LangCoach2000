// Settings screen (UX feedback item 3). Reachable from the Today queue's app
// bar. Two preferences ship now: the auto-advance toggle (gates T8.2 playback
// advance on completion) and the theme mode. Both persist instantly via
// [AppSettingsNotifier].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/ai_image/presentation/fal_api_key_settings_section.dart';
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
          const FalApiKeySettingsSection(),
          const SizedBox(height: 24),
        ],
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
