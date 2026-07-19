// EmailMessage (T6.5) — JSON round-trip.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/report/domain/email_message.dart';

void main() {
  group('EmailMessage JSON', () {
    test('round-trips through toJsonString / fromJsonString', () {
      const original = EmailMessage(
        recipient: 'user@example.com',
        subject: 'Weekly Report',
        htmlBody: '<!DOCTYPE html><html><body><h1>Hi</h1></body></html>',
      );
      final restored = EmailMessage.fromJsonString(original.toJsonString());
      expect(restored.recipient, original.recipient);
      expect(restored.subject, original.subject);
      expect(restored.htmlBody, original.htmlBody);
    });

    test('toJsonString is deterministic + stable across instances', () {
      const a = EmailMessage(
        recipient: 'a@b.c',
        subject: 'S',
        htmlBody: '<p>x</p>',
      );
      const b = EmailMessage(
        recipient: 'a@b.c',
        subject: 'S',
        htmlBody: '<p>x</p>',
      );
      expect(a.toJsonString(), b.toJsonString());
    });

    test('toJsonString contains the three fields under their JSON keys', () {
      const m = EmailMessage(
        recipient: 'r@e.x',
        subject: 'subj',
        htmlBody: '<b>body</b>',
      );
      final json = m.toJsonString();
      expect(json, contains('"recipient":"r@e.x"'));
      expect(json, contains('"subject":"subj"'));
      expect(json, contains('"html_body":"<b>body</b>"'));
    });
  });
}
