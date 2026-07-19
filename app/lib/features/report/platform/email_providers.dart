// coverage:ignore-file — production Riverpod wiring (google_sign_in + http +
// KV settings), excluded from the coverage floor. Tests build
// GmailApiEmailService / makeEmailQueueHandler directly against in-memory deps.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/report/application/email_queue_handler.dart';
import 'package:rivendell/features/report/data/gmail_api_email_service.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';
import 'package:rivendell/features/report/platform/google_sign_in_service.dart';

// KV keys for the signed-in account + recipient override. Stored in the
// SQLCipher-encrypted KV store (NFR-2.4.2). Only the account EMAIL is stored
// (for display + the recipient default); OAuth tokens are NEVER persisted —
// google_sign_in + Play Services own them.
const _kGmailAccount = 'gmail.account';
const _kEmailRecipient = 'email.recipient';

/// Singleton [GoogleSignInService]. Holds the GoogleSignIn instance; safe to
/// construct eagerly.
final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

/// Singleton [GmailApiEmailService]. Stateless; safe to construct eagerly.
final gmailApiEmailServiceProvider = Provider<GmailApiEmailService>(
  (ref) => GmailApiEmailService(),
);

/// Read-only access to the encrypted KV store backing email settings.
final emailSettingsRepositoryProvider = FutureProvider<KvRepository>(
  (ref) async => KvRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Resolve fresh Gmail credentials for the current drain, or null when no
/// account is signed in. Read fresh on every drain so a re-sign-in takes
/// effect without re-queueing pending items.
final gmailCredentialsProvider = FutureProvider<GmailCredentials?>((ref) async {
  final signIn = ref.watch(googleSignInServiceProvider);
  return signIn.ensureFreshCredentials();
});

/// The signed-in account email from the encrypted KV store, or null. For the
/// Settings UI's signed-in chip; invalidate after sign-in / sign-out so the
/// chip refreshes.
final gmailAccountProvider = FutureProvider<String?>((ref) async {
  final repo = await ref.watch(emailSettingsRepositoryProvider.future);
  return readGmailAccount(repo);
});

/// The signed-in account email, or null. For UI display + the recipient
/// default. Invalidate after sign-in / sign-out.
Future<String?> readGmailAccount(KvRepository repo) =>
    repo.read(_kGmailAccount);

/// Persist the signed-in account email (called after a successful sign-in).
Future<void> writeGmailAccount(KvRepository repo, String email) =>
    repo.write(_kGmailAccount, email);

/// Clear the signed-in account email (called on sign-out).
Future<void> clearGmailAccount(KvRepository repo) =>
    repo.delete(_kGmailAccount);

/// The configured recipient for weekly reports. Defaults to the signed-in
/// account email when not set (FR-1.5.3 product decision).
Future<String?> readReportRecipient(
  KvRepository repo, {
  String? fallback,
}) async {
  final stored = await repo.read(_kEmailRecipient);
  if (stored != null && stored.isNotEmpty) return stored;
  return fallback;
}

/// Persist (or clear) the weekly-report recipient override. An empty/null
/// value deletes the key so the signed-in-account fallback takes effect.
Future<void> writeReportRecipient(KvRepository repo, String? recipient) async {
  if (recipient == null || recipient.isEmpty) {
    await repo.delete(_kEmailRecipient);
  } else {
    await repo.write(_kEmailRecipient, recipient);
  }
}

/// Register the `email` queue handler on the shared worker. Call once from app
/// boot, BEFORE [bootOfflineQueue] starts the worker, so the initial online
/// drain already sees it. The handler reads [gmailCredentialsProvider] fresh
/// per drain so a re-sign-in takes effect without re-queueing pending items.
/// Runs on the main isolate only — the background workmanager isolate does not
/// register the email handler (google_sign_in needs the platform channel).
Future<void> registerEmailHandler(ProviderContainer container) async {
  final service = container.read(gmailApiEmailServiceProvider);
  final logger = container.read(appLoggerProvider);
  final worker = await container.read(queueProcessorProvider.future);
  worker.registerHandler(
    emailQueueType,
    makeEmailQueueHandler(
      service: service,
      credentialsProvider: () =>
          container.read(gmailCredentialsProvider.future),
      logger: logger,
    ),
  );
}
