// Native SAF folder picker (FR-1.1.1, T1.1 B2). Lives under platform/ so the
// coverage gate excludes it — the contract is verified on-device, not in a
// host widget test. Calls the Kotlin MethodChannel registered in MainActivity
// (ACTION_OPEN_DOCUMENT_TREE + takePersistableUriPermission) and returns the
// chosen content-tree URI string, or null on cancel / unavailable channel.

import 'package:flutter/services.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/folder_selection_service.dart';

class SafFolderSelectionService implements FolderSelectionService {
  SafFolderSelectionService(this._logger);

  final AppLogger _logger;

  static const MethodChannel _channel = MethodChannel('rivendell/folder');

  @override
  Future<String?> pickFolder() async {
    try {
      return await _channel.invokeMethod<String>('pickFolder');
    } on PlatformException catch (e) {
      // Kotlin side errored (e.g. permission not granted). Surface the code,
      // degrade to "no folder" so onboarding stays usable.
      _logger.w(
        LogTag.audio,
        'SAF folder picker failed: ${e.code} ${e.message ?? ''}',
      );
      return null;
    } on MissingPluginException {
      // Channel not registered (non-Android host, or engine pre-init). No
      // crash — onboarding treats it as a cancel.
      _logger.w(LogTag.audio, 'SAF folder picker channel not registered');
      return null;
    }
  }
}
