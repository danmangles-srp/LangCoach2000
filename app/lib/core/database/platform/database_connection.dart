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

/// Open the production encrypted database at [dbPath].
///
/// Cross-isolate key race (TODO T0.3): when the workmanager isolate opens its
/// own DB connection, both it and the UI isolate may resolve the key on first
/// launch. flutter_secure_storage has no atomic CAS, so two keys could be
/// generated and the DB orphaned. T0.3 must designate a single key owner
/// (resolve in main isolate, pass to the worker) before a second opener exists.
Future<AppDatabase> openAppDatabase({
  required DatabaseKeyStore keyStore,
  required String Function() dbPath,
}) async {
  final key = await keyStore.readOrCreate();
  // generateDatabaseKey() emits hex only — no quoting/escaping needed. Do NOT
  // log this statement: the PRAGMA carries the plaintext SQLCipher key.
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
