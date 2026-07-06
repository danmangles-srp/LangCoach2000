// Picks the Samsung Voice Recorder directory (FR-1.1.1, T1.1). Behind an
// abstract seam so the native SAF channel (B2) is swapped in without touching
// the onboarding flow, and so widget tests inject a fake. The production
// provider (Android → SAF, else → placeholder) lives in platform/.

import 'package:rivendell/core/logging/app_logger.dart';

/// Launches the native folder picker and returns the chosen folder's
/// identity (an Android SAF content tree URI in production), or null if the
/// user cancelled. Implementations MUST be safe to call repeatedly (re-pick).
abstract class FolderSelectionService {
  Future<String?> pickFolder();
}

/// Non-Android fallback (desktop/test builds): logs a warning and returns
/// null so the onboarding flow stays reachable without a real picker. The
/// Android path uses the SAF channel service via the platform provider.
class PlaceholderFolderSelectionService implements FolderSelectionService {
  PlaceholderFolderSelectionService(this._logger);

  final AppLogger _logger;

  @override
  Future<String?> pickFolder() async {
    _logger.w(LogTag.audio, 'folder picker not wired (non-Android build)');
    return null;
  }
}
