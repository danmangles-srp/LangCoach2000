// Word-log panel on the recording detail screen (M3, FR-1.3.1, T3.4). A
// segmented Text / Images toggle over the recording's word log. Text tab shows
// the parsed Uzbek↔English pairs (or an add-text affordance); Images tab is a
// read-only thumbnail grid of previously attached notebook photos (T18.6 hid
// the attach affordance — the picker is no longer surfaced here). Text is
// pasted into a dialog; both tabs refresh by invalidating the per-recording
// provider.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/anki/presentation/anki_export_button.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';
import 'package:rivendell/features/wordlog/domain/vocab_parser.dart';
import 'package:rivendell/l10n/app_strings.dart';

class WordLogSection extends ConsumerStatefulWidget {
  const WordLogSection({
    required this.recordingId,
    required this.recordingName,
    super.key,
  });

  final int recordingId;

  /// File name used as the Type 1 Anki tag (FR-1.3.3). Required so the export
  /// button labels its notes without re-fetching the recording.
  final String recordingName;

  @override
  ConsumerState<WordLogSection> createState() => _WordLogSectionState();
}

class _WordLogSectionState extends ConsumerState<WordLogSection> {
  bool _showImages = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final async = ref.watch(wordLogsForRecordingProvider(widget.recordingId));
    return async.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object _, StackTrace __) => Text(strings.wordLogAttachFailed),
      data: (rows) {
        final textLog = _textLog(rows);
        final images = _images(rows);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: strings.wordLogTitle,
              showImages: _showImages,
              onChanged: (v) => setState(() => _showImages = v),
              imagesAvailable: images.isNotEmpty,
            ),
            const SizedBox(height: 12),
            if (_showImages)
              _ImagesBody(
                images: images,
                docsDir: ref.watch(appDocsDirProvider),
              )
            else
              _TextBody(
                recordingId: widget.recordingId,
                recordingName: widget.recordingName,
                body: textLog?.body ?? '',
              ),
          ],
        );
      },
    );
  }

  WordLog? _textLog(List<WordLog> rows) {
    for (final r in rows) {
      if (r.kind == 'text') return r;
    }
    return null;
  }

  List<WordLog> _images(List<WordLog> rows) =>
      rows.where((r) => r.kind == 'image').toList(growable: false);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.showImages,
    required this.onChanged,
    required this.imagesAvailable,
  });

  final String title;
  final bool showImages;
  final ValueChanged<bool> onChanged;
  final bool imagesAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // T18.6: image attach is hidden, so the Images segment is only meaningful
    // when images already exist to view. With nothing attached, a lone title
    // keeps the header clean instead of a dead toggle.
    if (!imagesAvailable) {
      return Text(title, style: theme.textTheme.titleMedium);
    }
    final strings = AppStrings.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(strings.wordLogTabText)),
              ButtonSegment(value: true, label: Text(strings.wordLogTabImages)),
            ],
            selected: {showImages},
            onSelectionChanged: (s) => onChanged(s.first),
            emptySelectionAllowed: true,
          ),
        ),
      ],
    );
  }
}

class _TextBody extends ConsumerWidget {
  const _TextBody({
    required this.recordingId,
    required this.recordingName,
    required this.body,
  });

  final int recordingId;
  final String recordingName;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final pairs = parseVocabPairs(body);
    if (pairs.isEmpty) {
      return _EmptyAction(
        message: strings.wordLogTextEmpty,
        action: Text(strings.wordLogAddText),
        onTap: () => _editText(context, ref, recordingId, body),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in pairs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(p.uzbek)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '↔',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Expanded(child: Text(p.english)),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _editText(context, ref, recordingId, body),
            icon: const Icon(Icons.edit_outlined),
            label: Text(strings.wordLogEditText),
          ),
        ),
        const SizedBox(height: 4),
        AnkiExportButton(recordingName: recordingName, pairs: pairs),
        const SizedBox(height: 8),
        const _AiImageQueueLink(),
      ],
    );
  }
}

/// "N images queued →" affordance under the export button (T18.4). Watches the
/// LIVE queue snapshot (T18.3), so it appears the moment an image is enqueued
/// and disappears when the queue drains. Tapping opens the queue-review screen.
/// Hidden when nothing is pending so the word-log surface stays clean.
class _AiImageQueueLink extends ConsumerWidget {
  const _AiImageQueueLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final pending =
        ref.watch(aiImageQueueSnapshotProvider).value?.pending.length ?? 0;
    if (pending == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/settings/ai-image-queue'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_motion_outlined,
                size: 16,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                strings.aiQueuePendingLink(pending),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagesBody extends StatelessWidget {
  const _ImagesBody({required this.images, required this.docsDir});

  final List<WordLog> images;
  final AsyncValue<String> docsDir;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    if (images.isEmpty) {
      // T18.6: attach is hidden; with no images there is nothing to show but a
      // plain empty message (this branch is unreachable from the toggle now,
      // kept as a defensive fallback).
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          strings.wordLogImagesEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final dir = docsDir.value;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final img in images)
          if (dir != null)
            _Thumb(file: File('$dir/${img.body}'))
          else
            const SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(),
            ),
      ],
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.file});
  final File file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _FullScreenImage(file: file),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, Object error, StackTrace? ___) {
            // T8.3: the stored path resolves under the same base dir the DB +
            // AI cache use (those work), so a decode failure here is a real
            // on-device copy/byte issue — log the resolved path + existence so
            // it's diagnosable, and show a clearer tile than a bare icon.
            _logRenderFailure(ref, file, error);
            return _BrokenThumb(error: error);
          },
        ),
      ),
    );
  }
}

/// Full-screen pinch-zoom viewer for an attached word-log image (T7.3).
/// `InteractiveViewer` handles pinch-zoom + pan; tap or the app-bar close
/// button dismisses.
class _FullScreenImage extends ConsumerWidget {
  const _FullScreenImage({required this.file});
  final File file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.file(
              file,
              errorBuilder: (_, Object error, StackTrace? ___) {
                _logRenderFailure(ref, file, error);
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

void _logRenderFailure(WidgetRef ref, File file, Object error) {
  ref
      .read(appLoggerProvider)
      .e(
        LogTag.wordlog,
        'image render failed: path=${file.path} '
        'exists=${file.existsSync()} error=$error',
      );
}

class _BrokenThumb extends StatelessWidget {
  const _BrokenThumb({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 96,
      height: 96,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 26,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            "couldn't load",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({
    required this.message,
    required this.action,
    required this.onTap,
  });

  final String message;
  final Widget action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(onPressed: onTap, child: action),
        ),
      ],
    );
  }
}

Future<void> _editText(
  BuildContext context,
  WidgetRef ref,
  int recordingId,
  String current,
) async {
  final strings = AppStrings.of(context);
  final controller = TextEditingController(text: current);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.wordLogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: controller,
          maxLines: 8,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.wordLogTextDialogHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.wordLogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(strings.wordLogSave),
        ),
      ],
    ),
  );
  if (saved != true) return;
  final repo = await ref.read(wordLogRepositoryProvider.future);
  await repo.setTextLog(recordingId, body: controller.text);
  ref.invalidate(wordLogsForRecordingProvider(recordingId));
}
