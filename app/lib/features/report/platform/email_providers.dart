// coverage:ignore-file — production Riverpod wiring (mailer + KV settings),
// excluded from the coverage floor. Tests build SmtpEmailService /
// makeEmailQueueHandler directly against in-memory deps.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/report/application/email_queue_handler.dart';
import 'package:rivendell/features/report/data/smtp_email_service.dart';
import 'package:rivendell/features/report/domain/email_message.dart';

// KV keys for SMTP credentials + recipient. Stored in the SQLCipher-encrypted
// KV store (NFR-2.4.2); never in the repo, never in --dart-define (user
// override of the project default — acceptable because the encrypted local DB
// is per-install and not checked in).
const _kSmtpUsername = 'smtp.username';
const _kSmtpPassword = 'smtp.password';
const _kSmtpRecipient = 'smtp.recipient';

/// Singleton [SmtpEmailService]. Stateless; safe to construct eagerly.
final smtpEmailServiceProvider = Provider<SmtpEmailService>(
  (ref) => SmtpEmailService(),
);

/// Read-only access to the encrypted KV store backing SMTP settings.
final smtpSettingsRepositoryProvider = FutureProvider<KvRepository>(
  (ref) async => KvRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Compose the current [SmtpConfig] from settings, or null if the user hasn't
/// configured credentials yet. Read fresh on every drain so a Settings change
/// takes effect without re-queueing pending items.
final smtpConfigProvider = FutureProvider<SmtpConfig?>((ref) async {
  final repo = await ref.watch(smtpSettingsRepositoryProvider.future);
  final username = await repo.read(_kSmtpUsername);
  final password = await repo.read(_kSmtpPassword);
  if (username == null || username.isEmpty) return null;
  if (password == null || password.isEmpty) return null;
  return SmtpConfig.gmail(username: username, password: password);
});

/// Write SMTP credentials (called from Settings UI in T6.6). Exposed here so
/// the key names live next to their reader.
Future<void> writeSmtpCredentials(
  KvRepository repo, {
  required String username,
  required String password,
}) async {
  await repo.write(_kSmtpUsername, username);
  await repo.write(_kSmtpPassword, password);
}

/// The configured recipient for weekly reports. Defaults to the SMTP login
/// address when not set (FR-1.5.3 product decision).
Future<String?> readReportRecipient(
  KvRepository repo, {
  String? fallback,
}) async {
  final stored = await repo.read(_kSmtpRecipient);
  if (stored != null && stored.isNotEmpty) return stored;
  return fallback;
}

/// Register the `email` queue handler on the shared worker. Call once from app
/// boot, BEFORE [bootOfflineQueue] starts the worker, so the initial online
/// drain already sees it. The handler reads [smtpConfigProvider] fresh per
/// drain so a Settings credential change (T6.6) takes effect without
/// re-queueing pending items.
Future<void> registerEmailHandler(ProviderContainer container) async {
  final service = container.read(smtpEmailServiceProvider);
  final logger = container.read(appLoggerProvider);
  final worker = await container.read(queueProcessorProvider.future);
  worker.registerHandler(
    emailQueueType,
    makeEmailQueueHandler(
      service: service,
      configProvider: () => container.read(smtpConfigProvider.future),
      logger: logger,
    ),
  );
}
