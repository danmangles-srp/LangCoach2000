// Recording detail screen (T1.6, M1 story 3). Opens on tap from the library
// list, fetches the recording by id, shows its metadata, and binds the
// transport (play/pause + seek) to [audioPlayerControllerProvider].
//
// The OS media session (T1.5) keeps audio running in the background after the
// user navigates away, so this screen never stops playback on dispose —
// stopping here would defeat the lock-screen / notification controls.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/domain/recording_formatting.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';
import 'package:rivendell/features/gpa/domain/review_status.dart';
import 'package:rivendell/features/wordlog/presentation/word_log_section.dart';
import 'package:rivendell/l10n/app_strings.dart';

class RecordingDetailScreen extends ConsumerStatefulWidget {
  const RecordingDetailScreen({required this.recordingId, super.key});

  final int recordingId;

  @override
  ConsumerState<RecordingDetailScreen> createState() =>
      _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends ConsumerState<RecordingDetailScreen> {
  /// True once we've asked the controller to cue this recording. Guards the
  /// auto-play-on-open behavior so a rebuild doesn't restart playback.
  bool _loadStarted = false;

  /// Slider position while the user is dragging, in ms. `null` = follow the
  /// live transport position. Buffering the drag stops the slider fighting the
  /// engine's position stream mid-seek.
  int? _dragMs;

  void _maybeAutoPlay(Recording recording) {
    if (_loadStarted) return;
    _loadStarted = true;
    // If this recording is already cued (detail re-opened, hot restart), leave
    // the transport alone — restarting mid-listen is jarring.
    if (ref.read(audioPlayerControllerProvider).recordingId == recording.id) {
      return;
    }
    ref.read(audioPlayerControllerProvider.notifier).loadAndPlay(recording);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final async = ref.watch(recordingByIdProvider(widget.recordingId));
    // Title resolves to the file name once the row lands; a generic label
    // covers loading / error / not-found so the app bar never goes blank.
    final title = async.maybeWhen(
      data: (r) => r?.name ?? strings.recordingsDetailTitle,
      orElse: () => strings.recordingsDetailTitle,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: async.when(
        loading: () => _StatusView(
          icon: Icons.graphic_eq_rounded,
          message: strings.loading,
        ),
        error: (Object e, StackTrace st) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
        ),
        data: (recording) {
          if (recording == null) {
            return _StatusView(
              icon: Icons.help_outline_rounded,
              message: strings.recordingsNotFound,
            );
          }
          _maybeAutoPlay(recording);
          return _DetailContent(
            recording: recording,
            dragMs: _dragMs,
            onDrag: (ms) => setState(() => _dragMs = ms),
            onDragEnd: (ms) {
              setState(() => _dragMs = null);
              ref
                  .read(audioPlayerControllerProvider.notifier)
                  .seek(Duration(milliseconds: ms));
            },
          );
        },
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.recording,
    required this.dragMs,
    required this.onDrag,
    required this.onDragEnd,
  });

  final Recording recording;
  final int? dragMs;
  final ValueChanged<int> onDrag;
  final ValueChanged<int> onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final snap = ref.watch(audioPlayerControllerProvider);
    final theme = Theme.of(context);

    final totalMs = snap.duration.inMilliseconds;
    final showSlider = totalMs > 0;
    final posMs = (dragMs ?? snap.position.inMilliseconds).clamp(
      0,
      showSlider ? totalMs : 1,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetadataCard(recording: recording),
          const SizedBox(height: 28),
          _PositionRow(
            position: formatDurationMs(posMs) ?? strings.unknownDuration,
            duration: formatDurationMs(totalMs) ?? strings.unknownDuration,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          if (showSlider)
            Slider(
              value: posMs.toDouble(),
              max: totalMs.toDouble(),
              // Disable during load/buffer so a not-yet-ready source isn't
              // seeked; onChangeEnd still fires for a completed drag.
              onChanged: snap.isLoading ? null : (v) => onDrag(v.round()),
              onChangeEnd: (v) => onDragEnd(v.round()),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              // `null` = indeterminate (spins) while the source is still
              // loading; once ready but with no reported duration, a static
              // empty bar avoids a perpetual animation.
              child: LinearProgressIndicator(value: snap.isLoading ? null : 0),
            ),
          const SizedBox(height: 12),
          _TransportButton(
            snapshot: snap,
            onTap: () => ref
                .read(audioPlayerControllerProvider.notifier)
                .togglePlayPause(),
          ),
          const SizedBox(height: 28),
          WordLogSection(recordingId: recording.id),
          const SizedBox(height: 28),
          _ReviewHistorySection(recording: recording),
        ],
      ),
    );
  }
}

class _ReviewHistorySection extends ConsumerWidget {
  const _ReviewHistorySection({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(recordingReviewStatusProvider(recording.id));
    // skipLoadingOnReload: a mark/undo bumps reviewGenerationProvider, which
    // re-runs this family future. Without this flag the `.when` would flash the
    // loading branch, collapsing the section height mid-scroll and clamping the
    // outer SingleChildScrollView offset — the "jumps to top" bug. Keeping the
    // prior data rendered holds the layout steady across the refresh.
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object _, StackTrace __) => _StatusView(
        icon: Icons.error_outline_rounded,
        message: strings.errorTitle,
      ),
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewSummaryCard(status: status, recording: recording),
            const SizedBox(height: 16),
            _MilestoneTimeline(recording: recording, status: status),
          ],
        );
      },
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.status, required this.recording});

  final RecordingReviewStatus status;
  final Recording recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final timeline = gpaTimelineFor(createdAt: recording.createdAt);

    final reachedLabel = status.milestoneReached >= 0
        ? 'D+${timeline[status.milestoneReached].intervalDays}'
        : strings.reviewNoneYet;
    final lastLabel = status.lastReviewed != null
        ? dateFormat.format(status.lastReviewed!)
        : strings.reviewNever;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: Icon(
                Icons.history_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              title: Text(lastLabel),
              subtitle: Text(
                strings.reviewLastReviewed,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.flag_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              title: Text(reachedLabel),
              subtitle: Text(
                strings.reviewMilestoneReached,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.repeat_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              title: Text(strings.reviewCount(status.reviewCount)),
              subtitle: Text(
                strings.reviewHistoryTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneTimeline extends ConsumerWidget {
  const _MilestoneTimeline({required this.recording, required this.status});

  final Recording recording;
  final RecordingReviewStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final milestones = gpaTimelineFor(createdAt: recording.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final m in milestones)
              _MilestoneRow(
                milestone: m,
                reached: m.index <= status.milestoneReached,
                isActive: m.index == status.activeMilestone?.index,
                dueLabel:
                    '${strings.reviewDueLabel} ${dateFormat.format(m.dueOn)}',
                onMark: () => _mark(ref, m.index),
                onUndo: () => _undo(ref, m.index),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mark(WidgetRef ref, int milestoneIndex) async {
    final repo = await ref.read(reviewEventRepositoryProvider.future);
    await repo.markReviewed(
      recording.id,
      milestoneIndex: milestoneIndex,
      completedAt: DateTime.now(),
    );
    ref.read(reviewGenerationProvider.notifier).bump();
  }

  Future<void> _undo(WidgetRef ref, int milestoneIndex) async {
    final repo = await ref.read(reviewEventRepositoryProvider.future);
    await repo.unreviewMilestone(recording.id, milestoneIndex: milestoneIndex);
    ref.read(reviewGenerationProvider.notifier).bump();
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.reached,
    required this.isActive,
    required this.dueLabel,
    required this.onMark,
    required this.onUndo,
  });

  final GpaMilestone milestone;
  final bool reached;
  final bool isActive;
  final String dueLabel;
  final VoidCallback onMark;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final colorScheme = theme.colorScheme;
    final icon = reached
        ? Icons.check_circle_rounded
        : (isActive ? Icons.radio_button_checked : Icons.circle_outlined);
    final iconColor = reached
        ? colorScheme.primary
        : (isActive ? colorScheme.primary : colorScheme.outline);

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: iconColor),
      title: Text(
        'D+${milestone.intervalDays}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isActive || reached ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(
        dueLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: reached
          ? TextButton(onPressed: onUndo, child: Text(strings.reviewUndo))
          : TextButton(
              onPressed: onMark,
              child: Text(strings.reviewMarkReviewed),
            ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          dense: true,
          leading: Icon(
            Icons.calendar_today_rounded,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          title: Text(dateFormat.format(recording.createdAt)),
          subtitle: Text(
            strings.metaDate,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.position,
    required this.duration,
    required this.style,
  });

  final String position;
  final String duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(position, style: style),
        Text(duration, style: style),
      ],
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({required this.snapshot, required this.onTap});

  final PlaybackSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final disabled = snapshot.isError;
    final tooltip = snapshot.isCompleted
        ? strings.replayTooltip
        : (snapshot.isPlaying ? strings.pauseTooltip : strings.playTooltip);
    final icon = snapshot.isPlaying
        ? Icons.pause_rounded
        : (snapshot.isCompleted
              ? Icons.replay_rounded
              : Icons.play_arrow_rounded);

    return Center(
      child: SizedBox(
        width: 72,
        height: 72,
        child: Tooltip(
          message: tooltip,
          child: FilledButton(
            onPressed: disabled ? null : onTap,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: snapshot.isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(icon, size: 36),
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
          ],
        ),
      ),
    );
  }
}
