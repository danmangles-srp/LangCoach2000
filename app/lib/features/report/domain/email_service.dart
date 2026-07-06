// EmailService seam (T6.5, FR-1.5.3). Abstract so the SMTP impl is the only
// network-bearing class; everything else (queue handler, scheduler, tests) runs
// against this interface. Throwing marks the queue item failed → retried on the
// next reconnect (NFR-2.1.3).

import 'package:rivendell/features/report/domain/email_message.dart';

/// Sends an [EmailMessage] using the supplied [SmtpConfig]. Throws on any
/// failure (auth, network, SMTP refusal) — the caller (queue handler) treats
/// that as a failed attempt and leaves the item pending.
abstract class EmailService {
  Future<void> send(EmailMessage message, SmtpConfig config);
}

/// Raised when the queue handler is asked to drain but no SMTP credentials are
/// configured yet. The item is left pending; configuring creds (T6.6 settings)
/// lets the next drain send it.
class SmtpNotConfiguredException implements Exception {
  const SmtpNotConfiguredException();
  @override
  String toString() =>
      'SmtpNotConfiguredException: SMTP credentials not set; '
      'configure them in Settings to dispatch queued reports.';
}
