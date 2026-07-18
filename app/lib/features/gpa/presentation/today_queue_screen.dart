// Today's review queue screen (T2.5, FR-1.2.5 / M2 AC 3 / NFR-2.4.1). The home
// surface: reads [warmedQueueProvider] and maps the AsyncValue to a sectioned
// Today + Tomorrow list. Today is a forgiving 2-week backlog (T14.1, amending
// M10 AC4): any recording whose active milestone became due in the last 14
// days, most-overdue first, capped at 4 — so a missed day doesn't drop
// recordings out of sight. Tomorrow stays strict-only (due tomorrow exactly).
// Tomorrow rows render de-emphasized so Today stands out (T10.2). Each row is
// one-tap play (M2 AC 3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/progress/presentation/log_activity_dialog.dart';
import 'package:rivendell/l10n/app_strings.dart';

class TodayQueueScreen extends ConsumerWidget {
  const TodayQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(warmedQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.queueTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: strings.activityLogTooltip,
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: () => logActivity(context, ref),
          ),
          IconButton(
            tooltip: strings.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: async.when(
        loading: () => _StatusView(
          icon: Icons.event_repeat_rounded,
          message: strings.loading,
        ),
        error: (Object e, StackTrace st) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(warmedQueueProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (queue) {
          if (queue.today.isEmpty && queue.tomorrow.isEmpty) {
            return _StatusView(
              icon: Icons.check_circle_outline_rounded,
              message: strings.queueEmptyTitle,
              body: strings.queueEmptyBody,
            );
          }
          // T8.2: peer order for auto-advance is today then tomorrow, matching
          // the visual list. Shared by every tile.
          final nav = RecordingNavContext(
            peerIds: [
              for (final item in queue.today) item.recording.id,
              for (final item in queue.tomorrow) item.recording.id,
            ],
            source: RecordingLaunchSource.queue,
          );
          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader(label: strings.queueNavToday),
                for (final item in queue.today)
                  _WarmedTile(
                    item: item,
                    window: _WarmWindow.today,
                    navContext: nav,
                  ),
                if (queue.tomorrow.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(label: strings.queueSectionTomorrow),
                  for (final item in queue.tomorrow)
                    _WarmedTile(
                      item: item,
                      window: _WarmWindow.tomorrow,
                      navContext: nav,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _WarmWindow { today, tomorrow }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WarmedTile extends ConsumerWidget {
  const _WarmedTile({
    required this.item,
    required this.window,
    required this.navContext,
  });

  final WarmedItem item;
  final _WarmWindow window;
  final RecordingNavContext navContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    // Select only the bits this tile uses, not the whole snapshot — a position
    // tick emits a new PlaybackSnapshot ~every 150ms and would otherwise
    // rebuild every tile in the queue (T15.7). The record compares by value,
    // so a tick that only moves position doesn't trigger a rebuild.
    final (recordingId, isPlaying, isError) = ref.watch(
      audioPlayerControllerProvider.select(
        (s) => (s.recordingId, s.isPlaying, s.isError),
      ),
    );
    final milestone = item.status.activeMilestone;

    final isCurrent = recordingId == item.recording.id;
    final isTilePlaying = isCurrent && isPlaying;
    // T10.2: Tomorrow rows render de-emphasized (muted title, compact leading
    // badge, lower-contrast subtitle) so Today — the actionable window —
    // stands out. Today rows keep full emphasis.
    final isTomorrow = window == _WarmWindow.tomorrow;
    // T8.1: tap opens the detail page (auto-plays on open); popping returns to
    // the queue. The now-playing badge still reflects transport state on
    // return.
    void onTap() =>
        context.push('/recordings/${item.recording.id}', extra: navContext);

    final dueLabel = isTomorrow
        ? strings.queueDueTomorrow
        : strings.queueDueToday;
    final milestoneLabel = milestone != null
        ? 'D+${milestone.intervalDays}'
        : '';

    Widget? trailing;
    if (isCurrent) {
      trailing = Text(
        strings.queueNowPlaying,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }

    final titleColor = isTomorrow
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final subtitleColor = isTomorrow
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      leading: _Leading(
        isPlaying: isTilePlaying,
        isError: isError,
        compact: isTomorrow,
      ),
      title: Text(
        item.recording.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(color: titleColor),
      ),
      subtitle: Text(
        [milestoneLabel, dueLabel].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
      ),
      trailing: trailing,
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.isPlaying,
    required this.isError,
    this.compact = false,
  });

  final bool isPlaying;
  final bool isError;
  // T10.2: Tomorrow rows use a smaller, lower-contrast badge.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = compact ? 32.0 : 40.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: compact ? 0.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Icon(
        isPlaying
            ? Icons.graphic_eq_rounded
            : (isError
                  ? Icons.error_outline_rounded
                  : Icons.play_arrow_rounded),
        color: colorScheme.onPrimaryContainer,
        size: compact ? 18 : 22,
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
