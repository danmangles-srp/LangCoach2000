// AppDatabase + KvRepository round-trip (T0.2 gate).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';

void main() {
  late AppDatabase db;
  late KvRepository kv;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    kv = KvRepository(db);
  });

  tearDown(() => db.close());

  test('round-trips a value through KeyValues', () async {
    await kv.write('samsung_folder', 'content://fake/uri');
    expect(await kv.read('samsung_folder'), 'content://fake/uri');
  });

  test('overwrites on conflict (upsert)', () async {
    await kv.write('lang', 'uz');
    await kv.write('lang', 'uz-Cyrl');
    expect(await kv.read('lang'), 'uz-Cyrl');
  });

  test('read returns null for missing key', () async {
    expect(await kv.read('nope'), isNull);
  });

  test('delete removes the row', () async {
    await kv.write('temp', 'x');
    await kv.delete('temp');
    expect(await kv.read('temp'), isNull);
  });

  test('FK constraints enforced on open', () async {
    // If beforeOpen ran, PRAGMA foreign_keys = ON — a violating insert fails.
    await db.customStatement('CREATE TABLE parent(id INTEGER PRIMARY KEY)');
    await db.customStatement(
      'CREATE TABLE child(pid INTEGER REFERENCES parent(id))',
    );
    await expectLater(
      db.customStatement('INSERT INTO child(pid) VALUES (999)'),
      throwsA(isA<Object>()),
    );
  });

  test('schema version is set', () {
    expect(db.schemaVersion, greaterThanOrEqualTo(1));
  });
}
