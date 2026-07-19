// WeeklyReportSettingsSection widget test (T14.2 / OAuth swap). Mounts the real
// SettingsScreen over an in-memory Drift KV store (no device, no platform
// channel) and asserts the section renders the Google sign-in affordance when
// signed out, plus hydrates a saved recipient override into the field. Build
// never touches the google_sign_in plugin (only the KV-backed
// gmailAccountProvider), so this stays a pure widget test.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/settings/presentation/settings_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

Widget _host(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: SettingsScreen(),
    ),
  );
}

/// The text currently held by the TextField whose label matches [label].
String _fieldText(WidgetTester tester, String label) {
  final field = tester.widget<TextField>(
    find.ancestor(of: find.text(label), matching: find.byType(TextField)),
  );
  return field.controller?.text ?? '';
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('mounts without throwing (regression: state-shape on rebuild)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Weekly email report'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Recipient email'), findsOneWidget);
  });

  testWidgets('hydrates a saved recipient override into the field', (
    tester,
  ) async {
    final kv = KvRepository(db);
    await kv.write('email.recipient', 'reviewer@rivendell.app');

    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(_fieldText(tester, 'Recipient email'), 'reviewer@rivendell.app');
  });

  testWidgets('renders the send-test-email affordance', (tester) async {
    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Send test email'), findsOneWidget);
  });
}
