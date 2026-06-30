// Record bottom sheet (FR-1.1.3, T2.7). Renders the recorder state off
// [recorderControllerProvider]: a Record affordance, the live elapsed timer
// while recording, a saving spinner, and an error view. On a successful save
// (saving → idle) it pops with the new filename so the host screen can show a
// confirmation snackbar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/audio/recording/application/recorder_controller.dart';
import 'package:rivendell/features/audio/recording/domain/recording_state.dart';
import 'package:rivendell/l10n/app_strings.dart';

class RecordSheet extends ConsumerWidget {
  const RecordSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recorderControllerProvider);
    // Pop with the saved filename the moment a save completes (saving → idle).
    ref.listen<RecordingState>(recorderControllerProvider, (prev, next) {
      if (next.isIdle && (prev?.phase == RecordPhase.saving)) {
        final ctrl = ref.read(recorderControllerProvider.notifier);
        final saved = ctrl.lastSavedName;
        if (saved != null && context.mounted) Navigator.of(context).pop(saved);
      }
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(phase: state.phase),
            const SizedBox(height: 28),
            _Body(state: state),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.phase});
  final RecordPhase phase;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final title = phase == RecordPhase.recording
        ? strings.recordSheetTitle
        : strings.recordTooltip;
    return Row(
      children: [
        Icon(Icons.mic_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final RecordingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    if (state.isError) {
      return _MessageView(
        icon: Icons.error_outline_rounded,
        message: _errorText(strings, state.error),
        action: FilledButton.tonal(
          onPressed: () =>
              ref.read(recorderControllerProvider.notifier).dismissError(),
          child: Text(strings.retry),
        ),
      );
    }

    if (state.isBusy) {
      return _MessageView(spinner: true, message: strings.recordSaving);
    }

    if (state.isRecording) {
      return _RecordingView(elapsed: state.elapsed);
    }

    return FilledButton.icon(
      onPressed: () => ref.read(recorderControllerProvider.notifier).start(),
      icon: const Icon(Icons.fiber_manual_record_rounded),
      label: Text(strings.recordStart),
    );
  }

  String _errorText(AppStrings strings, String? code) {
    switch (code) {
      case 'permission':
        return strings.recordPermissionDenied;
      case 'no-folder':
        return strings.recordNoFolder;
      default:
        return strings.recordFailed;
    }
  }
}

class _RecordingView extends ConsumerWidget {
  const _RecordingView({required this.elapsed});
  final Duration elapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Column(
      children: [
        Icon(
          Icons.graphic_eq_rounded,
          size: 56,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          _mmss(elapsed),
          style: theme.textTheme.displaySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => ref.read(recorderControllerProvider.notifier).stop(),
          icon: const Icon(Icons.stop_rounded),
          label: Text(strings.recordStop),
        ),
      ],
    );
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    this.icon,
    this.spinner = false,
    this.action,
  });
  final IconData? icon;
  final bool spinner;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = action;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spinner)
          const CircularProgressIndicator()
        else
          Icon(icon, size: 48),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (a != null) ...[const SizedBox(height: 20), a],
      ],
    );
  }
}

/// Opens the record sheet; returns the saved filename (or null).
Future<String?> showRecordSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const RecordSheet(),
  );
}
