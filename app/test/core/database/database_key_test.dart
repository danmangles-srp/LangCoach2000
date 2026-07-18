// DatabaseKeyStore — per-install key (NFR-2.4.2).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/database_key.dart';

void main() {
  group('generateDatabaseKey', () {
    test('is 64 hex chars (256-bit)', () {
      expect(generateDatabaseKey(), matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('is unique across calls', () {
      final a = generateDatabaseKey();
      final b = generateDatabaseKey();
      expect(a, isNot(b));
    });
  });

  group('InMemoryDatabaseKeyStore', () {
    test('returns the seeded key', () async {
      expect(
        await InMemoryDatabaseKeyStore('deadbeef').readOrCreate(),
        'deadbeef',
      );
    });

    test('echoes a full-shape key', () async {
      final k = await InMemoryDatabaseKeyStore(
        generateDatabaseKey(),
      ).readOrCreate();
      expect(k, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('read (T18.2 background key path)', () {
    test('InMemory echoes the seeded key', () async {
      expect(await InMemoryDatabaseKeyStore('deadbeef').read(), 'deadbeef');
    });

    test('an absent key resolves to null (background no-op path)', () async {
      // The workmanager isolate reads; if the key isn't there yet it must get
      // null (not create) so it cannot race the main isolate's create.
      expect(await _AbsentKeyStore().read(), isNull);
    });
  });
}

class _AbsentKeyStore implements DatabaseKeyStore {
  @override
  Future<String> readOrCreate() => throw UnimplementedError();

  @override
  Future<String?> read() async => null;
}
