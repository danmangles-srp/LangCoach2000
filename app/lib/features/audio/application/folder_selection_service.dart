// Picks the Samsung Voice Recorder directory (FR-1.1.1, T1.1). Behind an
// abstract seam so the native SAF channel (B2) can be swapped in without
// touching the onboarding flow, and so widget tests inject a fake.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';

/// Launches the native folder picker and returns the chosen folder's
/// identity (an Android SAF content tree URI in production), or null if the
/// user cancelled. Implementations MUST be safe to call repeatedly (re-pick).
abstract class FolderSelectionService {
  Future<String?> pickFolder();
}

/// Default impl until the native SAF channel (T1.1 B2) lands: logs a warning
/// and returns null so the app builds and the onboarding flow is reachable,
/// but no folder can be selected yet. B2 overrides
/// [folderSelectionServiceProvider] with the real channel-backed impl.
/// Device-verified there; not unit-tested.
class PlaceholderFolderSelectionService implements FolderSelectionService {
  PlaceholderFolderSelectionService(this._logger);

  final AppLogger _logger;

  @override
  Future<String?> pickFolder() async {
    _logger.w(LogTag.audio, 'folder picker not wired (T1.1 B2 pending)');
    return null;
  }
}

/// Default = placeholder. B2 (native SAF channel) overrides this provider.
final folderSelectionServiceProvider = Provider<FolderSelectionService>((ref) {
  return PlaceholderFolderSelectionService(ref.watch(appLoggerProvider));
});
