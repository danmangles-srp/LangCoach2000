// Native SAF audio indexer (FR-1.1.2, T1.2). Under platform/ so the coverage
// gate excludes it — the channel contract is verified via a host-channel test
// and the cursor walk is verified on-device. Lists the chosen folder's audio
// files through the Kotlin MethodChannel and parses the result on a background
// isolate (NFR-2.2.1).

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/audio_indexer_service.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/scanned_file_mapper.dart';

class SafAudioIndexerService implements AudioIndexerService {
  SafAudioIndexerService(this._logger);

  final AppLogger _logger;

  static const MethodChannel _channel = MethodChannel('rivendell/scan');

  /// Scan [treeUri] for supported audio files. Returns parsed [ScannedFile]s
  /// (empty on cancel / failure — failures are logged, never thrown, so a scan
  /// can't crash the library screen).
  @override
  Future<List<ScannedFile>> scan(String treeUri) async {
    final List<dynamic> raw;
    try {
      raw =
          await _channel.invokeMethod<List<dynamic>>(
            'listAudioFiles',
            <String, Object?>{'treeUri': treeUri},
          ) ??
          const [];
    } on PlatformException catch (e) {
      _logger.w(
        LogTag.audio,
        'audio scan failed: ${e.code} ${e.message ?? ''}',
      );
      return const [];
    } on MissingPluginException {
      _logger.w(LogTag.audio, 'audio scan channel not registered');
      return const [];
    }

    // Parse off the main isolate: a 1000-entry map + DateTime construction is
    // exactly the work NFR-2.2.1 says must not drop frames. compute() returns
    // through the message loop, so callers still await a typed list.
    return compute(parseScannedEntries, raw);
  }
}
