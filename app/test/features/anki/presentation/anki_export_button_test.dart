// AnkiExportButton widget test (T4.5). Presentation is coverage-excluded, so
// this guards the state machine — installed → status chips, not-installed →
// dialog, export throw → "send failed" + retry — against the real export
// service over the in-memory gateway + AI fake. No device, no channel.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/ai_image/application/fake_ai_image_service.dart';
import 'package:rivendell/features/anki/application/anki_export_providers.dart';
import 'package:rivendell/features/anki/application/anki_export_service.dart';
import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/application/anki_providers.dart';
import 'package:rivendell/features/anki/application/fake_anki_gateway.dart';
import 'package:rivendell/features/anki/presentation/anki_export_button.dart';
import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';
import 'package:rivendell/l10n/app_strings.dart';

class _NotInstalledGateway extends FakeAnkiGateway {
  @override
  Future<bool> isInstalled() async => false;
}

List<VocabPair> _pairs() => const [
  VocabPair(english: 'hello', uzbek: 'salom'),
  VocabPair(english: 'goodbye', uzbek: 'xayr'),
];

Widget _host({
  required AnkiGateway gateway,
  AnkiExportService? service,
  bool throwOnService = false,
}) {
  return ProviderScope(
    overrides: [
      ankiGatewayProvider.overrideWithValue(gateway),
      ankiExportServiceProvider.overrideWith((ref) async {
        if (throwOnService) throw StateError('boom');
        final s = service;
        if (s == null) throw StateError('no service wired');
        return s;
      }),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnkiExportButton(
            recordingName: 'Lecture 1.m4a',
            pairs: _pairs(),
          ),
        ),
      ),
    ),
  );
}

AnkiExportService _realService(FakeAnkiGateway gateway) => AnkiExportService(
  gateway: gateway,
  aiImageService: FakeAiImageService(),
  logger: AppLogger(sink: RecordingSink()),
);

void main() {
  testWidgets(
    'tap with AnkiDroid installed runs the export and shows the result chips',
    (tester) async {
      final gateway = FakeAnkiGateway();
      await tester.pumpWidget(
        _host(gateway: gateway, service: _realService(gateway)),
      );

      expect(find.text('Send to Anki'), findsOneWidget);
      await tester.tap(find.text('Send to Anki'));
      await tester.pumpAndSettle();

      // 2 pairs: Type 1 adds 2; Type 2 has no cached image yet so both enqueue
      // (pending 2). Skipped/failed stay 0 and are hidden.
      expect(find.text('Added: 2'), findsOneWidget);
      expect(find.text('Queued images: 2'), findsOneWidget);
      expect(find.textContaining('generate on reconnect'), findsOneWidget);
    },
  );

  testWidgets('when AnkiDroid is not installed, tap shows the install dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_host(gateway: _NotInstalledGateway()));

    await tester.tap(find.text('Send to Anki'));
    await tester.pumpAndSettle();

    // Dialog-only widgets: the body (package id) + the Got it button.
    expect(find.textContaining('com.ichi2.anki'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('an export throw shows "send failed" + a Retry that re-runs', (
    tester,
  ) async {
    final gateway = FakeAnkiGateway();
    await tester.pumpWidget(_host(gateway: gateway, throwOnService: true));

    await tester.tap(find.text('Send to Anki'));
    await tester.pumpAndSettle();

    expect(find.text('Send failed. Try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // The underlying cause is surfaced (selectable), not swallowed.
    expect(find.textContaining('Bad state: boom'), findsOneWidget);
  });
}
