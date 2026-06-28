// coverage:ignore-file
//
// Riverpod wiring for [AppDatabase]. Excluded from line-coverage: production
// wiring depends on path_provider + the keystore; tests build repos directly
// against an in-memory [AppDatabase.forTesting].

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/database_connection.dart';
import 'package:rivendell/core/database/database_key.dart';
import 'package:rivendell/core/database/secure_database_key_store.dart';

final databaseKeyStoreProvider = Provider<DatabaseKeyStore>((ref) {
  return SecureDatabaseKeyStore();
});

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final keyStore = ref.watch(databaseKeyStoreProvider);
  final dir = await getApplicationDocumentsDirectory();
  final db = await openAppDatabase(
    keyStore: keyStore,
    dbPath: () => p.join(dir.path, 'rivendell.sqlite'),
  );
  ref.onDispose(db.close);
  return db;
});
