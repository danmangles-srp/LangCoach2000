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

    test('defaults to a non-empty key', () async {
      final k = await InMemoryDatabaseKeyStore().readOrCreate();
      expect(k, isNotEmpty);
    });
  });
}
