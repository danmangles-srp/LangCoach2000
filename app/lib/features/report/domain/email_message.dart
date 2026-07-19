// Email message value (T6.5, FR-1.5.3). Pure Dart — no platform deps, fully
// unit-tested. The queue payload is an [EmailMessage] serialized to JSON;
// the [GmailCredentials] is resolved fresh at drain time so a re-sign-in
// picks up without re-enqueueing.

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
