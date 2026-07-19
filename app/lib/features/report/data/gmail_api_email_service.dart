// Gmail REST API-backed EmailService (FR-1.5.3). The only report class that
// touches the network. Sends via `POST gmail.googleapis.com/.../messages/send`
// with an OAuth Bearer token resolved by the GoogleSignIn service.
// [buildRfc822] + [encodeRaw] + [buildRequestBody] are pure + extracted so they
// are unit-tested directly; [send] is a thin wrapper over `package:http` and
// isn't unit-tested (it hits the network).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/email_service.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';

class GmailApiEmailService implements EmailService {
  GmailApiEmailService({this.client});

  final http.Client? client;

  /// Gmail REST endpoint for sending a message. `users/me` resolves to the
  /// authorized account behind the access token.
  static const sendUrl =
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/send';

  /// The `gmail.send` OAuth scope the GoogleSignIn client requests.
  static const scope = 'https://www.googleapis.com/auth/gmail.send';

  /// Build the raw RFC822 message Gmail sends. Pure.
  static String buildRfc822(EmailMessage message, String senderEmail) {
    // CRLF line terminators are mandatory per RFC5322; Gmail rejects bare \n.
    const crlf = '\r\n';
    final lines = <String>[
      'From: $senderEmail',
      'To: ${message.recipient}',
      'Subject: ${message.subject}',
      'MIME-Version: 1.0',
      'Content-Type: text/html; charset=utf-8',
      '',
      message.htmlBody,
    ];
    return lines.join(crlf);
  }

  /// base64url-encode the UTF-8 RFC822 bytes, stripping padding (Gmail's `raw`
  /// field accepts unpadded base64url; padding is optional but stripped here to
  /// avoid URL transport quirks). Pure.
  static String encodeRaw(String rfc822) {
    final bytes = utf8.encode(rfc822);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Build the JSON request body for `messages/send`. Pure.
  static String buildRequestBody(EmailMessage message, String senderEmail) {
    final raw = encodeRaw(buildRfc822(message, senderEmail));
    return jsonEncode({'raw': raw});
  }

  @override
  Future<void> send(EmailMessage message, GmailCredentials credentials) async {
    final body = buildRequestBody(message, credentials.emailAddress);
    // The client is only constructed on first send so a headless/test context
    // that never sends pays nothing. The queue handler is the sole caller in
    // production and always runs on the main isolate, where GoogleSignIn's
    // platform channel is available to have resolved the token.
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse(sendUrl),
        headers: {
          'Authorization': 'Bearer ${credentials.accessToken}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: body,
      );
      // Gmail returns 200 on success. Any other status (401 expired token, 403
      // missing scope, 429 quota, 5xx) is a failure → throw → queue retries on
      // the next connectivity edge / re-sign-in.
      if (response.statusCode != 200) {
        throw GmailSendException(
          'Gmail API rejected send: ${response.statusCode} ${response.body}',
        );
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

/// Raised when the Gmail REST API returns a non-200. Carries the status + body
/// so the queue worker log shows the real cause.
class GmailSendException implements Exception {
  GmailSendException(this.message);
  final String message;
  @override
  String toString() => 'GmailSendException: $message';
}
