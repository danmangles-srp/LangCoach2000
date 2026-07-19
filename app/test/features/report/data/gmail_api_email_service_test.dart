// GmailApiEmailService pure builders (FR-1.5.3). buildRfc822 / encodeRaw /
// buildRequestBody cover the envelope + base64url encoding; send() is exercised
// against a MockClient so no real network call is made.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rivendell/features/report/data/gmail_api_email_service.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/gmail_credentials.dart';

const _message = EmailMessage(
  recipient: 'recipient@example.com',
  subject: 'Rivendell Weekly Report',
  htmlBody: '<!DOCTYPE html><html><body><h1>Hi</h1></body></html>',
);
const _creds = GmailCredentials(
  emailAddress: 'coach@rivendell.app',
  accessToken: 'ya29.test-token',
);

void main() {
  group('scope', () {
    test('requests the narrow gmail.send scope', () {
      expect(
        GmailApiEmailService.scope,
        'https://www.googleapis.com/auth/gmail.send',
      );
    });
  });

  group('buildRfc822', () {
    test('sets From = signed-in account + To = recipient + Subject', () {
      final raw = GmailApiEmailService.buildRfc822(
        _message,
        _creds.emailAddress,
      );
      expect(raw, contains('From: coach@rivendell.app'));
      expect(raw, contains('To: recipient@example.com'));
      expect(raw, contains('Subject: Rivendell Weekly Report'));
    });

    test('declares HTML content type + MIME version', () {
      final raw = GmailApiEmailService.buildRfc822(
        _message,
        _creds.emailAddress,
      );
      expect(raw, contains('Content-Type: text/html; charset=utf-8'));
      expect(raw, contains('MIME-Version: 1.0'));
    });

    test('terminates header lines with CRLF (RFC5322)', () {
      final raw = GmailApiEmailService.buildRfc822(
        _message,
        _creds.emailAddress,
      );
      // Every header line is followed by CRLF. A bare \n not preceded by \r
      // would mean an invalid terminator.
      expect(raw, contains('From: coach@rivendell.app\r\n'));
      expect(raw, isNot(contains('\r\r\n')));
    });

    test('body follows a blank separating line', () {
      final raw = GmailApiEmailService.buildRfc822(
        _message,
        _creds.emailAddress,
      );
      expect(raw, contains('\r\n\r\n<!DOCTYPE html>'));
    });
  });

  group('encodeRaw', () {
    test('produces unpadded base64url', () {
      final raw = GmailApiEmailService.buildRfc822(
        _message,
        _creds.emailAddress,
      );
      final encoded = GmailApiEmailService.encodeRaw(raw);
      // No padding chars.
      expect(encoded, isNot(contains('=')));
      // Round-trips through base64url decoding (re-padding ignored).
      final padded = encoded + '=' * ((4 - encoded.length % 4) % 4);
      expect(utf8.decode(base64Url.decode(padded)), raw);
    });
  });

  group('buildRequestBody', () {
    test('is a JSON object with a single raw field', () {
      final body = GmailApiEmailService.buildRequestBody(
        _message,
        _creds.emailAddress,
      );
      final decoded = jsonDecode(body) as Map<String, Object?>;
      expect(decoded.keys, ['raw']);
      expect(decoded['raw'], isA<String>());
    });
  });

  group('send', () {
    test('POSTs to the gmail.send endpoint with a Bearer token', () async {
      Uri? capturedUrl;
      Map<String, String>? capturedHeaders;
      String? capturedBody;
      final client = MockClient((request) async {
        capturedUrl = request.url;
        capturedHeaders = request.headers;
        capturedBody = request.body;
        return http.Response('{}', 200);
      });
      final service = GmailApiEmailService(client: client);

      await service.send(_message, _creds);

      expect(capturedUrl!.toString(), GmailApiEmailService.sendUrl);
      expect(capturedHeaders!['Authorization'], 'Bearer ya29.test-token');
      // Body carries the base64url RFC822 under `raw`.
      final decoded = jsonDecode(capturedBody!) as Map<String, Object?>;
      expect(decoded['raw'], isA<String>());
    });

    test('throws GmailSendException on a non-200 response', () async {
      final client = MockClient(
        (request) async => http.Response('{"error": "invalid_grant"}', 401),
      );
      final service = GmailApiEmailService(client: client);

      await expectLater(
        service.send(_message, _creds),
        throwsA(isA<GmailSendException>()),
      );
    });
  });
}
