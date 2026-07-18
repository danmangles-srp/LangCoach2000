// coverage:ignore-file
//
// Log-activity dialog (M11 T11.4, AC 2). The manual entry for the 5th XP
// source: pick reading/movie, type a title, optionally log minutes. The dialog
// returns an [ActivityDraft]; [logActivity] persists it via
// [ActivityLogRepository] (which fires the +15 XP hook in the same tx) and
// invalidates [activityLogsProvider] so the list re-reads.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/progress/application/progress_providers.dart';
import 'package:rivendell/features/progress/domain/activity_kind.dart';
import 'package:rivendell/l10n/app_strings.dart';

class ActivityDraft {
  const ActivityDraft({
    required this.kind,
    required this.title,
    this.durationMinutes,
  });

  final ActivityKind kind;
  final String title;
  final int? durationMinutes;
}

/// Open the form, persist on save, invalidate the list. No-op on dismiss.
Future<void> logActivity(BuildContext context, WidgetRef ref) async {
  final draft = await showDialog<ActivityDraft>(
    context: context,
    builder: (dialogContext) => const LogActivityDialog(),
  );
  if (draft == null) return;
  final repo = await ref.read(activityLogRepositoryProvider.future);
  await repo.add(
    kind: draft.kind,
    title: draft.title,
    durationMinutes: draft.durationMinutes,
  );
  ref.invalidate(activityLogsProvider);
}

class LogActivityDialog extends StatefulWidget {
  const LogActivityDialog({super.key});

  @override
  State<LogActivityDialog> createState() => _LogActivityDialogState();
}

class _LogActivityDialogState extends State<LogActivityDialog> {
  ActivityKind _kind = ActivityKind.reading;
  late final TextEditingController _title;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _duration = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final rawMinutes = _duration.text.trim();
    final parsed = rawMinutes.isEmpty ? null : int.tryParse(rawMinutes);
    Navigator.of(context).pop(
      ActivityDraft(
        kind: _kind,
        title: title,
        durationMinutes: parsed == null || parsed < 0 ? null : parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.activityLogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ActivityKind>(
              segments: [
                ButtonSegment(
                  value: ActivityKind.reading,
                  label: Text(strings.activityKindReading),
                  icon: const Icon(Icons.menu_book_outlined),
                ),
                ButtonSegment(
                  value: ActivityKind.movie,
                  label: Text(strings.activityKindMovie),
                  icon: const Icon(Icons.movie_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.single),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: strings.activityFieldTitle,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.activityFieldDurationMinutes,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.wordLogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.activitySave)),
      ],
    );
  }
}
