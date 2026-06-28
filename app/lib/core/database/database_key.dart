// Per-install SQLCipher key (NFR-2.4.2).
//
// Pure logic here: the abstract store, the key generator, and an in-memory
// test double. The platform-backed [SecureDatabaseKeyStore] lives in
// `secure_database_key_store.dart` (needs the keystore plugin — on-device).

import 'dart:math';

import 'package:flutter/foundation.dart';

/// Stores / creates the SQLCipher key for the local Drift store.
abstract class DatabaseKeyStore {
  /// Returns the existing key, or creates + persists a fresh random key.
  Future<String> readOrCreate();
}

/// Generate a fresh 256-bit SQLCipher key as 64 hex chars.
///
/// Pure (no platform deps) so the contract is unit-testable: 256-bit, hex,
/// unique per call. [Random.secure] is cryptographic.
String generateDatabaseKey() {
  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// In-memory key store for tests. Requires an explicit key — no default, so a
/// weak secret can never be imported into production wiring.
@visibleForTesting
class InMemoryDatabaseKeyStore implements DatabaseKeyStore {
  InMemoryDatabaseKeyStore(this._key);
  final String _key;

  @override
  Future<String> readOrCreate() async => _key;
}
