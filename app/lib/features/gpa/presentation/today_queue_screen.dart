// Today's review queue screen (T2.5, FR-1.2.5 / M2 AC 3 / NFR-2.4.1). The home
// surface: reads [todayQueueProvider] and maps the AsyncValue to premium list /
// empty / loading / error states. Each row is one-tap play (M2 AC 3); a 1-day-
// stale row carries a badge and sorts to the top (T2.4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/l10n/app_strings.dart';

class TodayQueueScreen extends ConsumerWidget {
  const TodayQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(todayQueueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.queueTitle), centerTitle: false),
      body: async.when(
        loading: () => _StatusView(
          icon: Icons.event_repeat_rounded,
          message: strings.loading,
        ),
        error: (Object e, StackTrace st) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(todayQueueProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (queue) {
          if (queue.isEmpty) {
            return _StatusView(
              icon: Icons.check_circle_outline_rounded,
              message: strings.queueEmptyTitle,
              body: strings.queueEmptyBody,
            );
          }
          return Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: queue.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) => _QueueTile(item: queue[index]),
            ),
          );
        },
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.item});

  final QueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final snap = ref.watch(audioPlayerControllerProvider);
    final milestone = item.status.activeMilestone;

    final isCurrent = snap.recordingId == item.recording.id;
    final isPlaying = isCurrent && snap.isPlaying;
    // One tap (M2 AC 3): toggle if already cued, otherwise cue + play.
    void onTap() {
      final notifier = ref.read(audioPlayerControllerProvider.notifier);
      if (isCurrent) {
        notifier.togglePlayPause();
      } else {
        notifier.loadAndPlay(item.recording);
      }
    }

    final dueLabel = item.isStale
        ? strings.queueOverdue(1)
        : strings.queueDueToday;
    final milestoneLabel = milestone != null
        ? 'D+${milestone.intervalDays}'
        : '';

    return ListTile(
      onTap: onTap,
      onLongPress: () => context.push('/recordings/${item.recording.id}'),
      leading: _Leading(isPlaying: isPlaying, isError: snap.isError),
      title: Text(
        item.recording.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [milestoneLabel, dueLabel].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: item.isStale
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: item.isStale
          ? _StaleBadge(label: strings.queueStaleBadge)
          : (isCurrent
                ? Text(
                    strings.queueNowPlaying,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.isPlaying, required this.isError});

  final bool isPlaying;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = this.isError;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPlaying
            ? Icons.graphic_eq_rounded
            : (isError
                  ? Icons.error_outline_rounded
                  : Icons.play_arrow_rounded),
        color: colorScheme.onPrimaryContainer,
        size: 22,
      ),
    );
  }
}

class _StaleBadge extends StatelessWidget {
  const _StaleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
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
