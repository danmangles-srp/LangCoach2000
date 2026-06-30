// Word-log panel on the recording detail screen (M3, FR-1.3.1, T3.4). A
// segmented Text / Images toggle over the recording's word log. Text tab shows
// the parsed English↔Uzbek pairs (or an attach affordance); Images tab shows
// notebook-photo thumbnails (or an attach affordance). Text is pasted into a
// dialog; images come from the Android photo picker and are copied into app
// storage via the T3.3 pipeline. Both refresh the panel by invalidating the
// per-recording provider.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';
import 'package:rivendell/features/wordlog/domain/supported_image_format.dart';
import 'package:rivendell/features/wordlog/domain/vocab_parser.dart';
import 'package:rivendell/l10n/app_strings.dart';

class WordLogSection extends ConsumerStatefulWidget {
  const WordLogSection({required this.recordingId, super.key});

  final int recordingId;

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
                recordingId: widget.recordingId,
                images: images,
                docsDir: ref.watch(appDocsDirProvider),
              )
            else
              _TextBody(
                recordingId: widget.recordingId,
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
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
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
            // Disable the Images segment when nothing is attached yet so the
            // empty state lives under the active tab instead of a dead toggle.
            emptySelectionAllowed: true,
          ),
        ),
      ],
    );
  }
}

class _TextBody extends ConsumerWidget {
  const _TextBody({required this.recordingId, required this.body});

  final int recordingId;
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
                Expanded(child: Text(p.english)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '↔',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Expanded(child: Text(p.uzbek)),
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
      ],
    );
  }
}

class _ImagesBody extends ConsumerWidget {
  const _ImagesBody({
    required this.recordingId,
    required this.images,
    required this.docsDir,
  });

  final int recordingId;
  final List<WordLog> images;
  final AsyncValue<String> docsDir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    if (images.isEmpty) {
      return _EmptyAction(
        message: strings.wordLogImagesEmpty,
        action: Text(strings.wordLogAddImage),
        onTap: () => _attachImage(context, ref, recordingId),
      );
    }
    final dir = docsDir.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
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
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _attachImage(context, ref, recordingId),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(strings.wordLogAddImage),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
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
          errorBuilder: (_, Object __, StackTrace? ___) => Container(
            width: 96,
            height: 96,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

/// Full-screen pinch-zoom viewer for an attached word-log image (T7.3).
/// `InteractiveViewer` handles pinch-zoom + pan; tap or the app-bar close
/// button dismisses.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
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
              errorBuilder: (_, Object __, StackTrace? ___) => const Padding(
                padding: EdgeInsets.all(32),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
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

Future<void> _attachImage(
  BuildContext context,
  WidgetRef ref,
  int recordingId,
) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picker = ref.read(imageLogPickerServiceProvider);
  final service = await ref.read(imageLogServiceProvider.future);
  final picked = await picker.pickImage();
  if (picked == null) return; // user cancelled
  if (!isSupportedImageExt(picked.extension)) {
    messenger.showSnackBar(
      SnackBar(content: Text(strings.wordLogAttachFailed)),
    );
    return;
  }
  try {
    await service.attach(
      recordingId: recordingId,
      sourceUri: picked.uri,
      extension: picked.extension,
    );
    ref.invalidate(wordLogsForRecordingProvider(recordingId));
  } on Object catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(strings.wordLogAttachFailed)),
    );
  }
}
