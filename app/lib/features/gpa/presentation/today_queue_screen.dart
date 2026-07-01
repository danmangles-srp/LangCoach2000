// Today's review queue screen (T2.5, FR-1.2.5 / M2 AC 3 / NFR-2.4.1). The home
// surface: reads [warmedQueueProvider] (T7.1) and maps the AsyncValue to a
// sectioned Today + Tomorrow list. Today holds the strict due-set (incl.
// 1-day-stale), topped up to a floor of 3 with soonest-next-due "up next" rows
// so a freshly indexed library isn't empty on day one; Tomorrow is the same
// shape as a preview. Each row is one-tap play (M2 AC 3). The canonical GPA
// intervals are never altered by the warm-up — up-next rows are reviewable-
// early, not rescheduled.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/gpa/domain/queue_warmup.dart';
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
    final snap = ref.watch(audioPlayerControllerProvider);
    final milestone = item.status.activeMilestone;

    final isCurrent = snap.recordingId == item.recording.id;
    final isPlaying = isCurrent && snap.isPlaying;
    // T8.1: tap opens the detail page (auto-plays on open); popping returns to
    // the queue. The now-playing badge still reflects transport state on
    // return.
    void onTap() =>
        context.push('/recordings/${item.recording.id}', extra: navContext);

    final isStale = item.isStale;
    final isUpNext = item.placement == WarmPlacement.upNext;
    final dueLabel = isStale
        ? strings.queueOverdue(1)
        : (isUpNext
              ? strings.queueUpNextBadge
              : (window == _WarmWindow.tomorrow
                    ? strings.queueDueTomorrow
                    : strings.queueDueToday));
    final milestoneLabel = milestone != null
        ? 'D+${milestone.intervalDays}'
        : '';

    Widget? trailing;
    if (isStale) {
      trailing = _PillBadge(
        label: strings.queueStaleBadge,
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      );
    } else if (isUpNext) {
      trailing = _PillBadge(
        label: strings.queueUpNextBadge,
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      );
    } else if (isCurrent) {
      trailing = Text(
        strings.queueNowPlaying,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }

    return ListTile(
      onTap: onTap,
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
          color: isStale
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
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

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
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
