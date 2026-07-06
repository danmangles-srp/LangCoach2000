// Weekly-report settings section (T6.6, FR-1.5.3). Embedded in the Settings
// screen. Day/time pickers persist immediately (mirroring the theme toggle);
// the SMTP credentials + recipient block commits on the Save button so a
// partially-typed password never reaches the encrypted store.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/features/report/domain/report_schedule.dart';
import 'package:rivendell/features/report/platform/email_providers.dart';
import 'package:rivendell/features/report/platform/report_providers.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class WeeklyReportSettingsSection extends ConsumerStatefulWidget {
  const WeeklyReportSettingsSection({super.key});

  @override
  ConsumerState<WeeklyReportSettingsSection> createState() =>
      _WeeklyReportSettingsSectionState();
}

class _WeeklyReportSettingsSectionState
    extends ConsumerState<WeeklyReportSettingsSection> {
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _recipient;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController();
    _password = TextEditingController();
    _recipient = TextEditingController();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _recipient.dispose();
    super.dispose();
  }

  Future<void> _hydrate(KvRepository repo) async {
    if (_hydrated) return;
    final username = await readSmtpUsername(repo);
    final recipient = await readReportRecipient(repo);
    _username.text = username ?? '';
    _recipient.text = recipient ?? '';
    _hydrated = true;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      await writeSmtpCredentials(
        repo,
        username: _username.text.trim(),
        password: _password.text,
      );
      await writeReportRecipient(
        repo,
        _recipient.text.trim().isEmpty ? null : _recipient.text.trim(),
      );
      _password.clear();
      if (mounted) setState(() => _saving = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(strings.settingsReportCredentialsSaved)),
      );
    } on Object {
      if (mounted) setState(() => _saving = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Save failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final schedule = ref.watch(reportScheduleProvider);
    final lastSent = ref.watch(reportLastSentProvider).value;
    final nextFire = ref.watch(reportNextFireProvider).value;
    final repoAsync = ref.watch(settingsRepositoryProvider);

    if (repoAsync.hasValue && !_hydrated) {
      _hydrate(repoAsync.requireValue);
    }

    final dayFormat = DateFormat.EEEE();
    final stampFormat = DateFormat('EEE, MMM d, y – HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(
            strings.settingsReportTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Day picker — persisted immediately on change.
        ListTile(
          leading: const Icon(Icons.event_repeat_rounded),
          title: Text(strings.settingsReportDayLabel),
          trailing: DropdownButton<int>(
            value: schedule.weekday,
            items: [
              for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
                DropdownMenuItem(
                  value: wd,
                  child: Text(_weekdayLabel(wd, dayFormat)),
                ),
            ],
            onChanged: (wd) {
              if (wd == null) return;
              unawaited(
                ref
                    .read(reportScheduleProvider.notifier)
                    .setSchedule(schedule.copyWith(weekday: wd)),
              );
            },
          ),
        ),
        // Time picker — persisted immediately.
        ListTile(
          leading: const Icon(Icons.access_time_rounded),
          title: Text(strings.settingsReportTimeLabel),
          trailing: TextButton(
            onPressed: () => _pickTime(schedule),
            child: Text(
              '${schedule.hour.toString().padLeft(2, '0')}:'
              '${schedule.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _username,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: strings.settingsReportSmtpUserLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.settingsReportSmtpPasswordLabel,
              helperText: strings.settingsReportSmtpPasswordHelp,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _recipient,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: strings.settingsReportRecipientLabel,
              hintText: strings.settingsReportRecipientHint,
              helperText: strings.settingsReportRecipientHelp,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(strings.settingsReportSaveCredentials),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _StatusGrid(
            lastSentLabel: strings.settingsReportLastSentLabel,
            lastSentValue: lastSent == null
                ? strings.settingsReportNeverSent
                : stampFormat.format(lastSent),
            nextSendLabel: strings.settingsReportNextSendLabel,
            nextSendValue: nextFire == null
                ? '—'
                : stampFormat.format(nextFire),
          ),
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday, DateFormat format) {
    // Intl needs a concrete date to format the weekday name; pick a known
    // Monday (2025-01-06) and step forward with calendar arithmetic so the
    // label matches the user's locale without crossing a DST boundary.
    final monday = DateTime(2025, 1, 6);
    final day = DateTime(
      monday.year,
      monday.month,
      monday.day + (weekday - DateTime.monday),
    );
    return format.format(day);
  }

  Future<void> _pickTime(ReportSchedule schedule) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute),
    );
    if (picked == null) return;
    unawaited(
      ref
          .read(reportScheduleProvider.notifier)
          .setSchedule(
            schedule.copyWith(hour: picked.hour, minute: picked.minute),
          ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.lastSentLabel,
    required this.lastSentValue,
    required this.nextSendLabel,
    required this.nextSendValue,
  });

  final String lastSentLabel;
  final String lastSentValue;
  final String nextSendLabel;
  final String nextSendValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lastSentLabel, style: labelStyle),
              const SizedBox(height: 2),
              Text(lastSentValue, style: valueStyle),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nextSendLabel, style: labelStyle),
              const SizedBox(width: 2),
              Text(nextSendValue, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
