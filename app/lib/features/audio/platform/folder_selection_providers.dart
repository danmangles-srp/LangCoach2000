// Riverpod wiring for the folder picker. Under platform/ so the coverage gate
// excludes it: production wiring depends on dart:io Platform + the native SAF
// channel, neither exercisable on a test host.
//
// On Android the real [SafFolderSelectionService] drives
// ACTION_OPEN_DOCUMENT_TREE (FR-1.1.1); everywhere else we fall back to the
// placeholder so desktop/test builds stay runnable. Widget tests override this
// provider or hit the placeholder default.

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/application/folder_selection_service.dart';
import 'package:rivendell/features/audio/platform/saf_folder_selection_service.dart';

final folderSelectionServiceProvider = Provider<FolderSelectionService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return Platform.isAndroid
      ? SafFolderSelectionService(logger)
      : PlaceholderFolderSelectionService(logger);
});
