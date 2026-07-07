// Coach note create/edit dialog (T5.5, FR-1.4.3). A title + multiline script,
// plus two attach pickers that open multi-select bottom sheets over the
// recordings and text vocab logs. Returns a [CoachNoteDraft] on save, or null
// on cancel. Selected ids are seeded from the existing note when editing and
// replaced wholesale on submit (the repository diffs nothing).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/coach/application/coach_providers.dart';
import 'package:rivendell/features/coach/domain/coach_note.dart';
import 'package:rivendell/l10n/app_strings.dart';

class CoachNoteDraft {
  const CoachNoteDraft({
    required this.title,
    required this.body,
    required this.recordingIds,
    required this.wordLogIds,
  });

  final String title;
  final String? body;
  final Set<int> recordingIds;
  final Set<int> wordLogIds;
}

/// Create ([existing] == null) or edit a coach note. Returns the draft, or null
/// if the user cancelled. The caller writes it through the repository.
Future<CoachNoteDraft?> showCoachNoteDialog(
  BuildContext context, {
  CoachNoteWithLinks? existing,
}) {
  return showDialog<CoachNoteDraft>(
    context: context,
    builder: (_) => _CoachNoteDialog(existing: existing),
  );
}

class _CoachNoteDialog extends ConsumerStatefulWidget {
  const _CoachNoteDialog({this.existing});

  final CoachNoteWithLinks? existing;

  @override
  ConsumerState<_CoachNoteDialog> createState() => _CoachNoteDialogState();
}

class _CoachNoteDialogState extends ConsumerState<_CoachNoteDialog> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final Set<int> _recordingIds;
  late final Set<int> _wordLogIds;

  @override
  void initState() {
    super.initState();
    final note = widget.existing?.note;
    _title = TextEditingController(text: note?.title ?? '');
    _body = TextEditingController(text: note?.body ?? '');
    _recordingIds = {...?widget.existing?.recordingIds};
    _wordLogIds = {...?widget.existing?.wordLogIds};
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final bodyText = _body.text.trim();
    Navigator.of(context).pop(
      CoachNoteDraft(
        title: title,
        body: bodyText.isEmpty ? null : bodyText,
        recordingIds: _recordingIds,
        wordLogIds: _wordLogIds,
      ),
    );
  }

  Future<void> _pickRecordings() async {
    final async = ref.read(recordingsProvider);
    final recordings = async.value ?? const <Recording>[];
    final chosen = await _showMultiSelect(
      title: AppStrings.of(context).coachPickRecordings,
      options: [for (final r in recordings) (id: r.id, label: r.name)],
      selected: _recordingIds,
    );
    if (chosen != null) {
      setState(() {
        _recordingIds
          ..clear()
          ..addAll(chosen);
      });
    }
  }

  Future<void> _pickVocab() async {
    final async = ref.read(allTextWordLogsProvider);
    final logs = async.value ?? const <WordLog>[];
    final chosen = await _showMultiSelect(
      title: AppStrings.of(context).coachPickVocab,
      options: [for (final l in logs) (id: l.id, label: l.body)],
      selected: _wordLogIds,
    );
    if (chosen != null) {
      setState(() {
        _wordLogIds
          ..clear()
          ..addAll(chosen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null ? strings.coachAdd : strings.taskFieldTitle,
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
              controller: _body,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: strings.coachFieldBody,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _AttachRow(
              icon: Icons.graphic_eq_rounded,
              label: strings.coachRecordings,
              summary: _recordingIds.isEmpty
                  ? strings.coachNone
                  : strings.coachNRecordings(_recordingIds.length),
              onTap: _pickRecordings,
            ),
            _AttachRow(
              icon: Icons.translate_rounded,
              label: strings.coachVocab,
              summary: _wordLogIds.isEmpty
                  ? strings.coachNone
                  : strings.coachNVocab(_wordLogIds.length),
              onTap: _pickVocab,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.wordLogCancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(strings.taskSave),
        ),
      ],
    );
  }

  /// A titled multi-select sheet. Returns the chosen id set, or null if the
  /// user dismissed the sheet (no change). Empty option lists still open so the
  /// user sees the empty state rather than a silent no-op.
  Future<Set<int>?> _showMultiSelect({
    required String title,
    required List<({int id, String label})> options,
    required Set<int> selected,
  }) {
    return showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final working = {...selected};
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final strings = AppStrings.of(context);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(working),
                          child: Text(strings.taskSave),
                        ),
                      ],
                    ),
                  ),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        strings.coachNone,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final o in options)
                            CheckboxListTile(
                              value: working.contains(o.id),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked ?? false) {
                                    working.add(o.id);
                                  } else {
                                    working.remove(o.id);
                                  }
                                });
                              },
                              title: Text(
                                o.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AttachRow extends StatelessWidget {
  const _AttachRow({
    required this.icon,
    required this.label,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  Text(
                    summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
