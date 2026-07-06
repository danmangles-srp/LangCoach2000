// Tiny repository over [KeyValues] proving the seam end-to-end (T0.2 gate).
// Real repositories land with their milestones.

import 'package:rivendell/core/database/app_database.dart';

class KvRepository {
  KvRepository(this._db);
  final AppDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.keyValues,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) async {
    await _db
        .into(_db.keyValues)
        .insertOnConflictUpdate(
          KeyValuesCompanion.insert(key: key, value: value),
        );
  }

  Future<void> delete(String key) async {
    await (_db.delete(_db.keyValues)..where((t) => t.key.equals(key))).go();
  }
}
