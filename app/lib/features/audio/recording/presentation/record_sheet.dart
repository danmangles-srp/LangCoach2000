// Record bottom sheet (FR-1.1.3, T2.7, T10.3). Renders the recorder state off
// [recorderControllerProvider]: a Record affordance, the live elapsed timer +
// editable name field while recording, a saving spinner, and an error view. On
// a successful save (saving → idle) it pops with the new filename so the host
// screen can show a confirmation snackbar.
//
// T10.3: the sheet owns a [TextEditingController] for the name field. When the
// controller transitions into recording it seeds the field with the stamped
// default base name; on stop the field's text is passed to [RecorderController]
// .stop, which sanitizes it into the saved filename + display name.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/audio/recording/application/recorder_controller.dart';
import 'package:rivendell/features/audio/recording/domain/recording_state.dart';
import 'package:rivendell/l10n/app_strings.dart';

class RecordSheet extends ConsumerStatefulWidget {
  const RecordSheet({super.key});

  @override
  ConsumerState<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<RecordSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _seedName(String? defaultName) {
    if (defaultName != null && defaultName.isNotEmpty) {
      // Only seed when empty — don't clobber an in-flight edit across rebuilds.
      if (_nameController.text.isEmpty) {
        _nameController.value = TextEditingValue(
          text: defaultName,
          selection: TextSelection.collapsed(offset: defaultName.length),
        );
      }
    } else {
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recorderControllerProvider);
    // Seed the name field when capture starts; clear it back on return to idle
    // so a subsequent record starts fresh.
    ref.listen<RecordingState>(recorderControllerProvider, (prev, next) {
      if (next.isIdle && (prev?.phase == RecordPhase.saving)) {
        final ctrl = ref.read(recorderControllerProvider.notifier);
        final saved = ctrl.lastSavedName;
        if (saved != null && context.mounted) Navigator.of(context).pop(saved);
        return;
      }
      if (prev?.phase != RecordPhase.recording &&
          next.phase == RecordPhase.recording) {
        _seedName(next.defaultName);
      } else if (next.isIdle && !(prev?.isIdle ?? true)) {
        _nameController.clear();
      }
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          32 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(phase: state.phase),
            const SizedBox(height: 28),
            _Body(state: state, nameController: _nameController),
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
  const _Body({required this.state, required this.nameController});
  final RecordingState state;
  final TextEditingController nameController;

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
      return _RecordingView(
        elapsed: state.elapsed,
        nameController: nameController,
      );
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
  const _RecordingView({required this.elapsed, required this.nameController});
  final Duration elapsed;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.graphic_eq_rounded,
          size: 56,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          _mmss(elapsed),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.label_outline_rounded),
            labelText: strings.recordNameLabel,
            hintText: strings.recordNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => ref
              .read(recorderControllerProvider.notifier)
              .stop(name: nameController.text),
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
