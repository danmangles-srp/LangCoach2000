// coverage:ignore-file
//
// Task create/edit dialog (T5.2, lifted for T9.4). Shared by the tasks list
// (FAB add) and the task detail screen (Edit action) so the form lives in one
// place. The dialog returns a [TaskDraft]; [createOrEditTask] persists it via
// [TaskCommands] and invalidates the list + per-id providers so every surface
// that reads the task re-reads.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/application/task_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class TaskDraft {
  const TaskDraft({required this.title, this.description, this.dueDate});

  final String title;
  final String? description;
  final DateTime? dueDate;
}

/// Open the form. [existing] == null creates a new task; otherwise edits the
/// passed row. No-op when the user dismisses the dialog.
Future<void> createOrEditTask(
  BuildContext context,
  WidgetRef ref, {
  required Task? existing,
}) async {
  final draft = await showDialog<TaskDraft>(
    context: context,
    builder: (dialogContext) => TaskEditDialog(existing: existing),
  );
  if (draft == null) return;
  final commands = await ref.read(taskCommandsProvider.future);
  if (existing == null) {
    await commands.create(
      title: draft.title,
      description: draft.description,
      dueDate: draft.dueDate,
    );
  } else {
    await commands.update(
      existing.id,
      title: draft.title,
      description: draft.description,
      dueDate: draft.dueDate,
    );
    ref.invalidate(taskByIdProvider(existing.id));
  }
  ref.invalidate(tasksProvider);
}

class TaskEditDialog extends StatefulWidget {
  const TaskEditDialog({required this.existing, super.key});

  final Task? existing;

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _today(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    // A dismissed picker leaves the existing date untouched; the explicit Clear
    // button is the only way to remove a due date.
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  void _clearDate() => setState(() => _dueDate = null);

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final dueDate = _dueDate;
    return AlertDialog(
      title: Text(
        widget.existing == null ? strings.tasksAdd : strings.taskFieldTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: strings.taskFieldTitle,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: strings.taskFieldDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDate == null
                        ? strings.taskNoDate
                        : strings.taskDueOn(dateFormat.format(dueDate)),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(strings.taskFieldDueDate),
                ),
                if (dueDate != null)
                  TextButton(
                    onPressed: _clearDate,
                    child: Text(strings.taskClearDate),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.wordLogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.taskSave)),
      ],
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
