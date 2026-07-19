// Recordings list screen (T1.4, M1 story 2). The home route once a folder is
// chosen. Reads [recordingsProvider] and maps the AsyncValue to premium list /
// empty / loading / error states. Tapping a tile pushes the detail + player
// route (T1.6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/recording_formatting.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';
import 'package:rivendell/features/audio/recording/presentation/record_sheet.dart';
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

    Future<void> record() async {
      final messenger = ScaffoldMessenger.of(context);
      final saved = await showRecordSheet(context);
      if (saved == null || !context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(strings.recordSaved(saved))),
      );
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
      floatingActionButton: FloatingActionButton(
        // HomeShell mounts this FAB alongside the Tasks tab's add FAB in an
        // IndexedStack; both default-tagged FABs would collide on Hero. Unique
        // tag keeps them distinct.
        heroTag: 'recordings-record',
        tooltip: strings.recordTooltip,
        onPressed: record,
        child: const Icon(Icons.mic_rounded),
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
          // T8.2: peer list for library launches — auto-advance goes to the
          // preceding row per the user's rule.
          final nav = RecordingNavContext(
            peerIds: [for (final r in recordings) r.id],
            source: RecordingLaunchSource.library,
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
                navContext: nav,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecordingTile extends ConsumerWidget {
  const _RecordingTile({
    required this.recording,
    required this.dateFormat,
    required this.navContext,
  });

  final Recording recording;
  final DateFormat dateFormat;
  final RecordingNavContext navContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    // Select only the bits the indicator depends on so a transport tick that
    // only advances `position` (every ~250ms while playing) doesn't rebuild
    // every visible library row.
    final snap = ref.watch(
      audioPlayerControllerProvider.select(
        (s) => (recordingId: s.recordingId, isPlaying: s.isPlaying),
      ),
    );
    final format = formatOf(recording);
    final duration = formatDurationMs(recording.durationMs);
    final date = dateFormat.format(recording.createdAt);
    final size = formatBytes(recording.sizeBytes);

    // T9.3: highlight the row the player is on. Mirrors the review queue's
    // leading glyph swap + trailing label so both lists agree on what
    // "now playing" looks like.
    final isCurrent = snap.recordingId == recording.id;
    final isPlaying = isCurrent && snap.isPlaying;

    Widget? trailing;
    if (isCurrent) {
      trailing = Text(
        strings.queueNowPlaying,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    } else if (format == null) {
      trailing = Text(
        strings.unknownFormat,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ListTile(
      leading: _FormatBadge(isPlaying: isPlaying),
      onTap: () =>
          context.push('/recordings/${recording.id}', extra: navContext),
      title: Text(recording.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [date, if (duration != null) duration, size].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({this.isPlaying = false});

  final bool isPlaying;

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
        isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
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
    final body = this.body;
    final hint = this.hint;
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
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
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
