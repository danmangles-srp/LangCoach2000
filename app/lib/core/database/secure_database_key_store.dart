// coverage:ignore-file
//
// Platform-backed SQLCipher key store (NFR-2.4.2). Excluded from line-coverage:
// [FlutterSecureStorage] has no Dart test double and routes through the OS
// keystore — verified on-device.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rivendell/core/database/database_key.dart';

/// Production [DatabaseKeyStore] backed by [FlutterSecureStorage].
class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'rivendell_db_key';
  final FlutterSecureStorage _storage;

  @override
  Future<String> readOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = generateDatabaseKey();
    await _storage.write(key: _key, value: fresh);
    return fresh;
  }
}
