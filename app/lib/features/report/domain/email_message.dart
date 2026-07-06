// Email message + SMTP config values (T6.5, FR-1.5.3). Pure Dart — no platform
// deps, fully unit-tested. The queue payload is the JSON serialization of an
// [EmailMessage]; the [SmtpConfig] is read fresh at drain time from settings so
// a credential change picks up without re-enqueueing.

import 'dart:convert';

/// Queue `type` under which email work items are stored in the offline queue.
const emailQueueType = 'email';

/// An outbound email: one recipient, one subject, an HTML body. Serialized to
/// JSON for the offline-queue payload.
class EmailMessage {
  const EmailMessage({
    required this.recipient,
    required this.subject,
    required this.htmlBody,
  });

  factory EmailMessage.fromJsonString(String json) {
    final map = jsonDecode(json) as Map<String, Object?>;
    final recipient = map['recipient'];
    final subject = map['subject'];
    final htmlBody = map['html_body'];
    if (recipient is String && subject is String && htmlBody is String) {
      return EmailMessage(
        recipient: recipient,
        subject: subject,
        htmlBody: htmlBody,
      );
    }
    throw FormatException('EmailMessage payload missing a field: $map');
  }

  final String recipient;
  final String subject;
  final String htmlBody;

  Map<String, Object?> toJson() => {
    'recipient': recipient,
    'subject': subject,
    'html_body': htmlBody,
  };

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() =>
      'EmailMessage(recipient: $recipient, subject: $subject, '
      '${htmlBody.length} html chars)';
}

/// Credentials + host config for an SMTP relay. The default Gmail preset
/// matches the product decision (user-supplied Gmail app-password, FR-1.5.3).
/// The encrypted local store holds the secret; it never lives in the repo.
class SmtpConfig {
  const SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.useSsl = false,
  });

  factory SmtpConfig.gmail({
    required String username,
    required String password,
  }) => SmtpConfig(
    host: gmailHost,
    port: gmailPort,
    username: username,
    password: password,
  );

  /// Gmail's relay on 587 with STARTTLS. Username = full Gmail address;
  /// password = a 16-char app password (2FA required).
  static const gmailHost = 'smtp.gmail.com';
  static const int gmailPort = 587;

  final String host;
  final int port;
  final String username;
  final String password;
  final bool useSsl;

  @override
  String toString() => 'SmtpConfig($username@$host:$port)';
}
