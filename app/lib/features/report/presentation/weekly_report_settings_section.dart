// Weekly-report settings section (T6.6, FR-1.5.3). Embedded in the Settings
// screen. Day/time pickers persist immediately (mirroring the theme toggle).
// Google sign-in commits on tap: a successful sign-in persists the account
// email for display + the recipient default; sign-out clears it. The recipient
// override commits on its own Save button so a half-typed address never
// reaches the encrypted store.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
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
  late final TextEditingController _recipient;
  bool _hydrated = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _recipient = TextEditingController();
  }

  @override
  void dispose() {
    _recipient.dispose();
    super.dispose();
  }

  Future<void> _hydrate(String? accountEmail) async {
    if (_hydrated) return;
    final repo = await ref.read(settingsRepositoryProvider.future);
    final recipient = await readReportRecipient(repo, fallback: accountEmail);
    _recipient.text = recipient ?? '';
    _hydrated = true;
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      final signIn = ref.read(googleSignInServiceProvider);
      final creds = await signIn.signIn();
      if (creds == null) {
        // User cancelled the account picker — no error surfacing.
        return;
      }
      final repo = await ref.read(settingsRepositoryProvider.future);
      await writeGmailAccount(repo, creds.emailAddress);
      ref.invalidate(gmailAccountProvider);
      // Signing in changes the credential the email handler resolves, but the
      // queue table is untouched, so no pending-change drain fires. Kick one
      // so a queued report retries immediately with the fresh token instead of
      // waiting for an ambient backoff / online edge (or never, if the app is
      // backgrounded and only the workmanager isolate — which can't run
      // google_sign_in — is awake).
      final worker = await ref.read(queueProcessorProvider.future);
      unawaited(worker.drain());
    } on Object catch (e, st) {
      // Surface the real PlatformException (e.g. ApiException code 10 =
      // DEVELOPER_ERROR = SHA-1 mismatch) so the cause isn't swallowed.
      debugPrint('google sign-in failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text('${strings.settingsReportSignInFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final signIn = ref.read(googleSignInServiceProvider);
    await signIn.signOut();
    final repo = await ref.read(settingsRepositoryProvider.future);
    await clearGmailAccount(repo);
    ref.invalidate(gmailAccountProvider);
  }

  Future<void> _saveRecipient() async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    final repo = await ref.read(settingsRepositoryProvider.future);
    final value = _recipient.text.trim();
    await writeReportRecipient(repo, value.isEmpty ? null : value);
    messenger.showSnackBar(
      SnackBar(content: Text(strings.settingsReportRecipientSaved)),
    );
  }

  Future<void> _sendTestEmail() async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      // Resolve a FRESH token — the cached one may be stale, and this is the
      // only path that proves the full UI -> OAuth -> Gmail REST chain works.
      final signIn = ref.read(googleSignInServiceProvider);
      final creds = await signIn.ensureFreshCredentials();
      if (creds == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.settingsReportSignInRequiredForTest)),
        );
        return;
      }
      final repo = await ref.read(settingsRepositoryProvider.future);
      // fallback = the signed-in address, so recipient is always populated.
      final storedRecipient = await readReportRecipient(
        repo,
        fallback: creds.emailAddress,
      );
      final recipient = storedRecipient ?? creds.emailAddress;
      final message = EmailMessage(
        recipient: recipient,
        subject: 'Rivendell test email',
        htmlBody:
            '<p>This is a test email from Rivendell. If you received this, '
            'weekly reports are configured correctly.</p>',
      );
      final service = ref.read(gmailApiEmailServiceProvider);
      await service.send(message, creds);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.settingsReportTestSent)),
      );
    } on Object catch (e, st) {
      debugPrint('test email failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: Text('${strings.settingsReportTestFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final schedule = ref.watch(reportScheduleProvider);
    final lastSent = ref.watch(reportLastSentProvider).value;
    final nextFire = ref.watch(reportNextFireProvider).value;
    final accountEmail = ref.watch(gmailAccountProvider).value;

    if (accountEmail != null && !_hydrated) {
      // Hydrate the recipient field once the account is known so the default
      // (the signed-in email) shows through.
      _hydrate(accountEmail);
    } else if (accountEmail == null && !_hydrated) {
      _hydrate(null);
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
        // Google account block — sign in / signed-in chip / sign out.
        if (accountEmail == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.settingsReportNotSignedIn,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _signIn,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(strings.settingsReportSignInWithGoogle),
                ),
              ],
            ),
          )
        else
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              '${strings.settingsReportSignedInAs} $accountEmail',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: _signOut,
              child: Text(strings.settingsReportSignOut),
            ),
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
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
            onPressed: _saveRecipient,
            icon: const Icon(Icons.save_rounded),
            label: Text(strings.settingsReportRecipientSaved),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: FilledButton.tonalIcon(
            onPressed: _busy ? null : _sendTestEmail,
            icon: const Icon(Icons.send_rounded),
            label: Text(strings.settingsReportSendTestEmail),
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
