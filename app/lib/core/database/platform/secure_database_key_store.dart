// Platform-backed SQLCipher key store (NFR-2.4.2). Under platform/ so the
// coverage gate excludes it: FlutterSecureStorage has no Dart test double and
// routes through the OS keystore — verified on-device.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rivendell/core/database/database_key.dart';

/// Production DatabaseKeyStore backed by FlutterSecureStorage.
///
/// Uses the plugin's current defaults (Android Keystore-backed). The older
/// `encryptedSharedPreferences` option is deprecated and ignored as of v10.
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
    // Write-then-reread converges a same-isolate race (two callers observe null
    // before either write lands): both end up returning the persisted value.
    // Cross-isolate (UI + workmanager) needs a single-key-owner design — see
    // the TODO bound to T0.3 in database_connection.dart.
    final persisted = await _storage.read(key: _key);
    return persisted ?? fresh;
  }
}
