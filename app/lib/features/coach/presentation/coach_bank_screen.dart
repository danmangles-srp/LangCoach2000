// Coach Bank screen (T5.5, FR-1.4.3, NFR-2.4.1). The coaching surface: create
// / edit / delete notes that pin the recordings and vocab logs for a session.
// Reads [coachNotesProvider]; mutations invalidate it so the list refreshes
// atomically. Each tile is the note title + script preview + agenda chips (N
// recordings / N vocab); tap to edit, swipe to delete.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/coach/application/coach_providers.dart';
import 'package:rivendell/features/coach/domain/coach_note.dart';
import 'package:rivendell/features/coach/presentation/coach_note_dialog.dart';
import 'package:rivendell/l10n/app_strings.dart';

class CoachBankScreen extends ConsumerWidget {
  const CoachBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(coachNotesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.coachTitle), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        // HomeShell mounts this alongside the Tasks + Library FABs in an
        // IndexedStack; unique tag keeps Hero distinct.
        heroTag: 'coach-add',
        onPressed: () => _createOrEdit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.coachAdd),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(coachNotesProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return _StatusView(
              icon: Icons.menu_book_rounded,
              message: strings.coachEmptyTitle,
              body: strings.coachEmptyBody,
            );
          }
          return Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              itemBuilder: (context, i) => _CoachTile(note: notes[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createOrEdit(BuildContext context, WidgetRef ref) async {
    final draft = await showCoachNoteDialog(context);
    if (draft == null) return;
    final commands = await ref.read(coachNoteCommandsProvider.future);
    await commands.create(
      title: draft.title,
      body: draft.body,
      recordingIds: draft.recordingIds.toList(),
      wordLogIds: draft.wordLogIds.toList(),
    );
    ref.invalidate(coachNotesProvider);
  }
}

class _CoachTile extends ConsumerWidget {
  const _CoachTile({required this.note});

  final CoachNoteWithLinks note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Dismissible(
      key: ValueKey('coach-${note.note.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        final commands = await ref.read(coachNoteCommandsProvider.future);
        await commands.delete(note.note.id);
        ref.invalidate(coachNotesProvider);
        return true;
      },
      child: ListTile(
        onTap: () => _edit(context, ref),
        title: Text(
          note.note.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.note.body == null && note.recordingIds.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.note.body != null)
                    Text(
                      note.note.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (note.recordingIds.isNotEmpty ||
                      note.wordLogIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (note.recordingIds.isNotEmpty)
                            _Chip(
                              icon: Icons.graphic_eq_rounded,
                              label: strings.coachNRecordings(
                                note.recordingIds.length,
                              ),
                            ),
                          if (note.wordLogIds.isNotEmpty)
                            _Chip(
                              icon: Icons.translate_rounded,
                              label: strings.coachNVocab(
                                note.wordLogIds.length,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final draft = await showCoachNoteDialog(context, existing: note);
    if (draft == null) return;
    final commands = await ref.read(coachNoteCommandsProvider.future);
    await commands.update(
      note.note.id,
      title: draft.title,
      body: draft.body,
      recordingIds: draft.recordingIds.toList(),
      wordLogIds: draft.wordLogIds.toList(),
    );
    ref.invalidate(coachNotesProvider);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
    this.body,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
