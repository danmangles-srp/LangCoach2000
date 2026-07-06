// Email queue handler (T6.5, NFR-2.1.3). Drives the EmailService via the shared
// QueueHandler contract. Fake service + a controllable config provider — no
// network, no DB.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/report/application/email_queue_handler.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/email_service.dart';

class _RecordingEmailService implements EmailService {
  _RecordingEmailService({this._failure});

  final Exception? _failure;
  final List<({EmailMessage message, SmtpConfig config})> calls = [];

  @override
  Future<void> send(EmailMessage message, SmtpConfig config) async {
    calls.add((message: message, config: config));
    if (_failure case final Exception f) throw f;
  }
}

class _Sink implements LogSink {
  const _Sink();
  @override
  void write(LogLevel level, String line) {}
}

void main() {
  late AppLogger logger;
  setUp(() {
    logger = AppLogger(sink: const _Sink());
  });

  const message = EmailMessage(
    recipient: 'user@example.com',
    subject: 'Weekly',
    htmlBody: '<p>hi</p>',
  );

  test('parses payload + sends with the current config', () async {
    final service = _RecordingEmailService();
    final handler = makeEmailQueueHandler(
      service: service,
      configProvider: () async => SmtpConfig.gmail(
        username: 'me@gmail.com',
        password: 'abcdefghijklmnop',
      ),
      logger: logger,
    );

    await handler(message.toJsonString());

    expect(service.calls.length, 1);
    expect(service.calls.single.message.recipient, 'user@example.com');
    expect(service.calls.single.config.username, 'me@gmail.com');
  });

  test('throws when creds unset + does NOT call send', () async {
    final service = _RecordingEmailService();
    final handler = makeEmailQueueHandler(
      service: service,
      configProvider: () async => null,
      logger: logger,
    );

    await expectLater(
      handler(message.toJsonString()),
      throwsA(isA<SmtpNotConfiguredException>()),
    );
    expect(service.calls, isEmpty);
  });

  test('propagates send failures (throw = retry)', () async {
    final service = _RecordingEmailService(
      failure: Exception('SMTP 535 auth failed'),
    );
    final handler = makeEmailQueueHandler(
      service: service,
      configProvider: () async =>
          SmtpConfig.gmail(username: 'me@gmail.com', password: 'bad'),
      logger: logger,
    );

    await expectLater(
      handler(message.toJsonString()),
      throwsA(isA<Exception>()),
    );
    expect(service.calls.length, 1); // attempt was made
  });

  test('handler is registered under the email queue type constant', () {
    // Guards against a silent rename of the queue type that would orphan
    // enqueued items (worker would log "no handler").
    expect(emailQueueType, 'email');
  });
}
