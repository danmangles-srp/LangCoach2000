// Email queue handler (T6.5, NFR-2.1.3). Adapts [EmailService] to the shared
// [QueueHandler] contract so the offline queue drains email work on reconnect.
// Pure logic over injected deps — testable with a fake service + config
// provider, no network.
//
// Config is read at drain time (not enqueue) so a credential change in Settings
// (T6.6) takes effect without re-queueing pending reports. If creds are unset
// the handler throws [SmtpNotConfiguredException]; the worker marks the item
// failed and retries on the next connectivity edge.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_worker.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/email_service.dart';

typedef SmtpConfigProvider = Future<SmtpConfig?> Function();

/// Build a [QueueHandler] for `email`-type queue items.
///
/// [configProvider] returns the current SMTP creds (or null if unset).
QueueHandler makeEmailQueueHandler({
  required EmailService service,
  required SmtpConfigProvider configProvider,
  required AppLogger logger,
}) {
  return (payload) async {
    final message = EmailMessage.fromJsonString(payload);
    final config = await configProvider();
    if (config == null) {
      logger.w(
        LogTag.mail,
        'email queue item skipped: SMTP not configured '
        '(subject="${message.subject}")',
      );
      throw const SmtpNotConfiguredException();
    }
    logger.i(
      LogTag.mail,
      'sending queued email to ${message.recipient} '
      '("${message.subject}")',
    );
    await service.send(message, config);
    logger.i(LogTag.mail, 'email sent: "${message.subject}"');
  };
}
