// Recordings list screen (T1.4, M1 story 2). The home route once a folder is
// chosen. Reads [recordingsProvider] and maps the AsyncValue to premium list /
// empty / loading / error states. Tap-to-detail lands with T1.6 (player); the
// tile is intentionally non-interactive here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/recording_formatting.dart';
import 'package:rivendell/l10n/app_strings.dart';

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(recordingsProvider);

    Future<void> scan() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final indexer = await ref.read(recordingIndexerProvider.future);
        final count = await indexer.scanAndStore();
        ref.invalidate(recordingsProvider);
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(strings.scannedCount(count))),
        );
      } on Object {
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(strings.scanFailed)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.recordingsTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: strings.scanTooltip,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: scan,
          ),
        ],
      ),
      body: async.when(
        loading: () => _StatusView(
          icon: Icons.graphic_eq_rounded,
          message: strings.loading,
        ),
        error: (Object e, StackTrace st) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(recordingsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (recordings) {
          if (recordings.isEmpty) {
            return _StatusView(
              icon: Icons.graphic_eq_rounded,
              message: strings.emptyTitle,
              body: strings.emptyBody,
              hint: strings.emptyHint,
            );
          }
          // One DateFormat for the whole list — constructing it per-tile
          // reallocates the locale's date symbols on every rebuild (1000-file
          // list × every invalidation). Locale symbols are loaded once in
          // main (initializeDateFormatting) so this never throws.
          final dateFormat = DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          );
          return Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: recordings.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) => _RecordingTile(
                recording: recordings[index],
                dateFormat: dateFormat,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.recording, required this.dateFormat});

  final Recording recording;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final format = formatOf(recording);
    final duration = formatDurationMs(recording.durationMs);
    final date = dateFormat.format(recording.createdAt);
    final size = formatBytes(recording.sizeBytes);

    return ListTile(
      leading: const _FormatBadge(),
      title: Text(recording.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [date, if (duration != null) duration, size].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: format == null
          ? Text(
              strings.unknownFormat,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: colorScheme.onPrimaryContainer,
        size: 20,
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
    this.body,
    this.hint,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? body;
  final String? hint;
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
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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
