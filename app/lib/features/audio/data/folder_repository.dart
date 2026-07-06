// Persists the user-chosen Samsung Voice Recorder folder (FR-1.1.1) in the
// local store. Pure logic over [KvRepository] — no platform deps — so the
// set/get/warn-once contract is unit-tested via the in-memory store. The
// folder identity (a content tree URI on Android) is opaque to this layer;
// the indexer (T1.2) and the SVR-path matcher (domain/) interpret it.

import 'package:rivendell/core/database/kv_repository.dart';

/// Single source of truth for the designated audio folder + the one-time
/// "this isn't the usual Voice Recorder folder" nudge (T1.1 UX decision:
/// allow any folder, warn once).
class FolderRepository {
  FolderRepository(this._kv);

  final KvRepository _kv;

  static const _folderKey = 'audio.folder_uri';
  static const _warnShownKey = 'audio.non_svr_warning_shown';

  /// The persisted folder identity, or null if the user hasn't picked one.
  Future<String?> currentFolder() => _kv.read(_folderKey);

  /// True once a folder has been chosen — drives the first-run redirect.
  Future<bool> hasFolder() async => (await currentFolder()) != null;

  /// Persist the chosen folder identity (overwrites any prior pick).
  Future<void> setFolder(String folderUri) => _kv.write(_folderKey, folderUri);

  /// Forget the current folder — used by the re-pick flow (settings, later).
  Future<void> clear() => _kv.delete(_folderKey);

  /// True until the non-SVR warning has been shown once. "Warn once" is once
  /// ever — the user has been told non-SVR folders are allowed, so we don't
  /// nag on later re-picks.
  Future<bool> shouldShowNonSvrWarning() async =>
      (await _kv.read(_warnShownKey)) != '1';

  /// Record that the non-SVR warning has been shown.
  Future<void> markNonSvrWarningShown() => _kv.write(_warnShownKey, '1');
}
