// coverage:ignore-file
//
// Platform-bound construction of the SQLCipher-encrypted [AppDatabase]
// (NFR-2.4.2). Excluded from line-coverage: requires drift's background
// isolate + the native SQLCipher lib — verified on-device, not unit tests.
//
// The key is resolved before [driftDatabase] is built: only the key String
// crosses the drift isolate boundary, not the [DatabaseKeyStore] handle.

import 'package:drift_flutter/drift_flutter.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/database_key.dart';

/// Open the production encrypted database at [dbPath].
Future<AppDatabase> openAppDatabase({
  required DatabaseKeyStore keyStore,
  required String Function() dbPath,
}) async {
  final key = await keyStore.readOrCreate();
  final escaped = key.replaceAll("'", "''");
  return AppDatabase(
    driftDatabase(
      name: 'rivendell',
      native: DriftNativeOptions(
        databasePath: () async => dbPath(),
        setup: (rawDb) {
          // SQLCipher: set the key before any read/write.
          rawDb.execute("PRAGMA key = '$escaped';");
        },
      ),
    ),
  );
}
