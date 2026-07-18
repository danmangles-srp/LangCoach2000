// Platform-bound construction of the SQLCipher-encrypted [AppDatabase]
// (NFR-2.4.2). Lives under platform/ so the coverage gate excludes it
// (requires drift's background isolate + the native SQLCipher lib — verified
// on-device, not unit tests).
//
// The key is resolved before [driftDatabase] is built: only the key String
// crosses the drift isolate boundary, not the [DatabaseKeyStore] handle.

import 'package:drift_flutter/drift_flutter.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/database_key.dart';

/// Open the production encrypted database at [dbPath]. Main-isolate path: it
/// creates the key on first launch via [DatabaseKeyStore.readOrCreate].
///
/// Cross-isolate key ownership (T0.3): the main isolate is the sole key owner.
/// The workmanager background isolate opens its own connection via
/// [openAppDatabaseWithKey] with a key it READ (never created) through
/// [DatabaseKeyStore.read] — so there is no dual-create race to orphan the DB.
/// Task registration is ordered after main-isolate boot creates the key, so the
/// background read always finds one present.
Future<AppDatabase> openAppDatabase({
  required DatabaseKeyStore keyStore,
  required String Function() dbPath,
}) async {
  final key = await keyStore.readOrCreate();
  return _openEncrypted(key: key, dbPath: dbPath);
}

/// Open the encrypted DB with a key already resolved by the main isolate.
///
/// Used by the workmanager background drain (T18.2). The background isolate
/// resolves the key via the read-only [DatabaseKeyStore.read] (no create) and
/// passes it here, so this opener has no keyStore + no create path — it cannot
/// race the main isolate.
Future<AppDatabase> openAppDatabaseWithKey({
  required String key,
  required String Function() dbPath,
}) async {
  return _openEncrypted(key: key, dbPath: dbPath);
}

// generateDatabaseKey() emits hex only — no quoting/escaping needed. Do NOT
// log this statement: the PRAGMA carries the plaintext SQLCipher key.
AppDatabase _openEncrypted({
  required String key,
  required String Function() dbPath,
}) {
  return AppDatabase(
    driftDatabase(
      name: 'rivendell',
      native: DriftNativeOptions(
        databasePath: () async => dbPath(),
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '$key';");
        },
      ),
    ),
  );
}
