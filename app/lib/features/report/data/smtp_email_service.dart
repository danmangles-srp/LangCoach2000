// SMTP-backed EmailService (T6.5, FR-1.5.3). The only report class that touches
// the network. [buildMessage] + [buildServer] are extracted + tested; [send] is
// a thin wrapper over the `mailer` package — not unit-tested here.

import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/email_service.dart';

class SmtpEmailService implements EmailService {
  SmtpEmailService();

  /// Build the mailer [mailer.Message] from our value type. Pure — tested
  /// directly so the envelope construction doesn't need a network round-trip.
  static mailer.Message buildMessage(EmailMessage message, SmtpConfig config) {
    return mailer.Message()
      ..from = mailer.Address(config.username)
      ..recipients = [mailer.Address(message.recipient)]
      ..subject = message.subject
      ..html = message.htmlBody
      // Plaintext fallback for clients that don't render HTML.
      ..text = _stripHtml(message.htmlBody);
  }

  /// Build the mailer [SmtpServer] from our config. `ssl: true` for the
  /// implicit-TLS port (465); otherwise STARTTLS is negotiated on connect.
  static SmtpServer buildServer(SmtpConfig config) {
    return SmtpServer(
      config.host,
      port: config.port,
      username: config.username,
      password: config.password,
      ssl: config.useSsl,
    );
  }

  @override
  Future<void> send(EmailMessage message, SmtpConfig config) async {
    // mailer.send throws on any auth/network/SMTP failure — which is exactly
    // the contract the queue handler wants (throw = leave pending, retry on
    // next reconnect). A returned SendReport means success.
    await mailer.send(buildMessage(message, config), buildServer(config));
  }

  /// Crude HTML → plaintext pass for the text fallback. Strips tags + collapses
  /// whitespace; good enough for a fallback, not a renderer.
  static String _stripHtml(String html) {
    final noTags = html.replaceAll(RegExp('<[^>]*>'), '');
    return noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
