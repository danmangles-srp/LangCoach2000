// AI image queue-review screen (FR-1.3.4). Lists pending image generations
// with their failure history ("upload logs": attempts + last error + enqueue
// time) and the recently generated words. Retry zeroes the attempt counter +
// forces a drain; Cancel hard-deletes the pending item. Reached from a Settings
// tile.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class AiImageQueueScreen extends ConsumerWidget {
  const AiImageQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(aiImageQueueSnapshotProvider);
    final stampFormat = DateFormat('EEE, MMM d, y – HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsAiImageQueueTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (snap) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(label: strings.aiQueuePendingHeader),
              if (snap.pending.isEmpty)
                _EmptyLine(text: strings.aiQueuePendingEmpty)
              else
                for (final item in snap.pending)
                  _PendingItemCard(item: item, stampFormat: stampFormat),
              const Divider(height: 32, indent: 16, endIndent: 16),
              _SectionHeader(label: strings.aiQueueGeneratedHeader),
              if (snap.generated.isEmpty)
                _EmptyLine(text: strings.aiQueueGeneratedEmpty)
              else
                for (final entry in snap.generated)
                  _GeneratedTile(
                    entry: entry,
                    docsDir: ref.watch(aiImageDocsDirProvider),
                    stampFormat: stampFormat,
                  ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A generated-image row: an `Image.file` thumbnail resolved against the app
/// documents dir (where the cache writes), with the word + timestamp. Falls
/// back to the placeholder icon while docsDir loads or if the file is missing
/// so a stale cache row never blanks the row.
class _GeneratedTile extends StatelessWidget {
  const _GeneratedTile({
    required this.entry,
    required this.docsDir,
    required this.stampFormat,
  });

  final AiImageCacheEntry entry;
  final AsyncValue<String> docsDir;
  final DateFormat stampFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: docsDir.when(
        data: (dir) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File('$dir/${entry.relativePath}'),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ThumbFallback(),
          ),
        ),
        loading: () => const _ThumbFallback(),
        error: (_, _) => const _ThumbFallback(),
      ),
      title: Text(entry.uzbekWord),
      trailing: Text(
        stampFormat.format(entry.createdAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: Icon(
        Icons.image_outlined,
        size: 24,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PendingItemCard extends ConsumerWidget {
  const _PendingItemCard({required this.item, required this.stampFormat});
  final QueueItem item;
  final DateFormat stampFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final word = wordFromAiImagePayload(item.payload);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${strings.aiQueueEnqueuedLabel}: '
              '${stampFormat.format(item.createdAt)}',
              style: labelStyle,
            ),
            Text(strings.aiQueueAttempts(item.attempts), style: labelStyle),
            if (item.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                strings.aiQueueLastErrorLabel,
                style: labelStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              // Selectable so a real failure message can be copied out.
              SelectableText(item.lastError!, style: theme.textTheme.bodySmall),
            ],
            OverflowBar(
              spacing: 8,
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _cancel(context, ref, item),
                  child: Text(strings.wordLogCancel),
                ),
                FilledButton.tonal(
                  onPressed: () => _retry(context, ref, item),
                  child: Text(strings.ankiRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry(
    BuildContext context,
    WidgetRef ref,
    QueueItem item,
  ) async {
    // Capture the async deps up front (ref is only safe to touch while the
    // element is mounted); a user who navigates back mid-drain would otherwise
    // trip "Using ref when a widget has been unmounted".
    final queueFuture = ref.read(queueRepositoryProvider.future);
    final workerFuture = ref.read(queueProcessorProvider.future);
    final queue = await queueFuture;
    await queue.resetAttempts(item.id);
    final worker = await workerFuture;
    await worker.drain();
    if (!context.mounted) return;
    ref.invalidate(aiImageQueueSnapshotProvider);
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    QueueItem item,
  ) async {
    final queue = await ref.read(queueRepositoryProvider.future);
    await queue.delete(item.id);
    if (!context.mounted) return;
    ref.invalidate(aiImageQueueSnapshotProvider);
  }
}
