// SmtpEmailService builder (T6.5). The send() call hits the network and isn't
// unit-tested; buildMessage + buildServer are pure and cover the envelope
// construction. Verify against the mailer package's own types.

import 'package:flutter_test/flutter_test.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' show SmtpServer;

import 'package:rivendell/features/report/data/smtp_email_service.dart';
import 'package:rivendell/features/report/domain/email_message.dart';

void main() {
  const message = EmailMessage(
    recipient: 'recipient@example.com',
    subject: 'Rivendell Weekly Report',
    htmlBody: '<!DOCTYPE html><html><body><h1>Hi</h1></body></html>',
  );
  final config = SmtpConfig.gmail(
    username: 'sender@gmail.com',
    password: 'abcdefghijklmnop',
  );

  group('buildMessage', () {
    test('sets from = the SMTP login address', () {
      final m = SmtpEmailService.buildMessage(message, config);
      expect(m.fromAsAddress.mailAddress, 'sender@gmail.com');
    });

    test('addresses the recipient envelope', () {
      final m = SmtpEmailService.buildMessage(message, config);
      final recipientAddresses = m.recipients.whereType<mailer.Address>().map(
        (a) => a.mailAddress,
      );
      expect(recipientAddresses, contains('recipient@example.com'));
    });

    test('carries subject + html + a non-empty plaintext fallback', () {
      final m = SmtpEmailService.buildMessage(message, config);
      expect(m.subject, 'Rivendell Weekly Report');
      expect(m.html, message.htmlBody);
      expect(m.text, isNotEmpty);
      // Fallback strips tags so no '<' survives.
      expect(m.text, isNot(contains('<')));
    });

    test('plaintext fallback collapses whitespace + trims', () {
      const htmlMsg = EmailMessage(
        recipient: 'r@e.x',
        subject: 's',
        htmlBody: '<p>Hello\n  world</p>',
      );
      final m = SmtpEmailService.buildMessage(htmlMsg, config);
      expect(m.text, 'Hello world');
    });
  });

  group('buildServer', () {
    test('matches host, port, username, password', () {
      final s = SmtpEmailService.buildServer(config);
      expect(s.host, 'smtp.gmail.com');
      expect(s.port, 587);
      expect(s.username, 'sender@gmail.com');
      expect(s.password, 'abcdefghijklmnop');
      expect(s.ssl, isFalse);
    });

    test('honors useSsl for implicit-TLS configs', () {
      const sslConfig = SmtpConfig(
        host: 'smtp.example.com',
        port: 465,
        username: 'u',
        password: 'p',
        useSsl: true,
      );
      expect(SmtpEmailService.buildServer(sslConfig).ssl, isTrue);
    });

    test('returns a SmtpServer instance (mailer type)', () {
      expect(SmtpEmailService.buildServer(config), isA<SmtpServer>());
    });
  });
}
