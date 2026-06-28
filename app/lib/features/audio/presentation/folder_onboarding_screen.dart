// First-run folder onboarding (FR-1.1.1, T1.1). Shown until the user picks a
// Samsung Voice Recorder folder. UX (confirmed): guess + confirm — guide the
// user toward the standard Voice Recorder folder, but allow any pick and warn
// once if it isn't the usual one. The picker itself is behind
// [folderSelectionServiceProvider] (placeholder until B2's native SAF channel).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/application/folder_selection_service.dart';
import 'package:rivendell/features/audio/domain/voice_recorder_paths.dart';

class FolderOnboardingScreen extends ConsumerWidget {
  const FolderOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Point Rivendell at your recordings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose your Samsung Voice Recorder folder so Rivendell can '
                  "index your .m4a, .mp3, and .wav files. It's usually "
                  'called "$voiceRecorderFolderName".',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _pick(context, ref),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Choose folder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ref
          .read(folderSelectionServiceProvider)
          .pickFolder();
      if (!context.mounted) return;
      if (picked == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No folder selected.')),
        );
        return;
      }
      final repo = await ref.read(folderRepositoryProvider.future);
      await repo.setFolder(picked);

      final nonSvr = !looksLikeVoiceRecorderFolder(picked);
      if (nonSvr && await repo.shouldShowNonSvrWarning()) {
        await repo.markNonSvrWarningShown();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "That isn't the usual Voice Recorder folder — "
              'indexing it anyway.',
            ),
          ),
        );
      }

      // Invalidate the gate so the redirect re-evaluates against the new
      // folder.
      ref.invalidate(hasFolderProvider);
      if (context.mounted) context.go('/');
    } on Object {
      // Picker or persistence failure: surface a plain-language retry. A
      // typed Failure + Result<T> lands with the repo-seam work (T0.x).
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save that folder. Try again.")),
      );
    }
  }
}
