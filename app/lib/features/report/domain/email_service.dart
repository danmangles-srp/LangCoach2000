// EmailService seam (T6.5, FR-1.5.3). Abstract so the Gmail REST impl is the
// only network-bearing class; everything else (queue handler, scheduler, tests)
// runs against this interface. Throwing marks the queue item failed → retried
// on the next reconnect (NFR-2.1.3).

import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';

/// Sends an [EmailMessage] using the supplied [GmailCredentials]. Throws on any
/// failure (auth, network, Gmail refusal) — the caller (queue handler) treats
/// that as a failed attempt and leaves the item pending.
abstract class EmailService {
  Future<void> send(EmailMessage message, GmailCredentials credentials);
}

/// Raised when the queue handler is asked to drain but no Google account is
/// signed in yet. The item is left pending; signing in via Settings lets the
/// next drain send it.
class EmailNotConfiguredException implements Exception {
  const EmailNotConfiguredException();
  @override
  String toString() =>
      'EmailNotConfiguredException: no Google account signed in; '
      'sign in via Settings to dispatch queued reports.';
}
