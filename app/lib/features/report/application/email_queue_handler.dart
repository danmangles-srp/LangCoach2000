// Email queue handler (T6.5, NFR-2.1.3). Adapts [EmailService] to the shared
// [QueueHandler] contract so the offline queue drains email work on reconnect.
// Pure logic over injected deps — testable with a fake service + credential
// provider, no network.
//
// Credentials are resolved at drain time (not enqueue) so a re-sign-in in
// Settings takes effect without re-queueing pending reports. If no Google
// account is signed in the handler throws [EmailNotConfiguredException]; the
// worker marks the item failed and retries on the next connectivity edge.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_worker.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/email_service.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';

typedef GmailCredentialsProvider = Future<GmailCredentials?> Function();

/// Build a [QueueHandler] for `email`-type queue items.
///
/// [credentialsProvider] returns the current signed-in Gmail creds (or null if
/// signed out).
QueueHandler makeEmailQueueHandler({
  required EmailService service,
  required GmailCredentialsProvider credentialsProvider,
  required AppLogger logger,
}) {
  return (payload) async {
    final message = EmailMessage.fromJsonString(payload);
    final credentials = await credentialsProvider();
    if (credentials == null) {
      logger.w(
        LogTag.mail,
        'email queue item skipped: no Google account signed in '
        '(subject="${message.subject}")',
      );
      throw const EmailNotConfiguredException();
    }
    logger.i(
      LogTag.mail,
      'sending queued email to ${message.recipient} '
      'from ${credentials.emailAddress} ("${message.subject}")',
    );
    await service.send(message, credentials);
    logger.i(LogTag.mail, 'email sent: "${message.subject}"');
  };
}
