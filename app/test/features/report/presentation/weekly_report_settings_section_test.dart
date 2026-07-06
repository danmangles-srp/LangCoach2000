// WeeklyReportSettingsSection widget test (T14.2). Regression: the three SMTP
// TextEditingControllers were declared `late final` and never constructed, so
// the first build threw a LateInitializationError the moment it read
// `_username`. This mounts the real SettingsScreen over an in-memory Drift KV
// store (no device, no channel) and asserts the section builds and hydrates
// the saved username + recipient into the fields. Presentation is coverage-
// excluded, so this guards the state-shape regression only.

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

  testWidgets(
    'mounts without throwing (regression: LateInitializationError on SMTP '
    'TextEditingControllers)',
    (tester) async {
      await tester.pumpWidget(_host(db));
      // The section renders asynchronously once the KV store resolves; pump
      // the frame + the microtask queue without flush-and-settle (no periodic
      // timers expected here, but pumpAndSettle would also catch the throw).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Weekly email report'), findsOneWidget);
      expect(find.text('Gmail address'), findsOneWidget);
      expect(find.text('Recipient email'), findsOneWidget);
    },
  );

  testWidgets('hydrates saved SMTP username + recipient into the fields', (
    tester,
  ) async {
    final kv = KvRepository(db);
    await kv.write('smtp.username', 'coach@rivendell.app');
    await kv.write('smtp.recipient', 'reviewer@rivendell.app');

    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(_fieldText(tester, 'Gmail address'), 'coach@rivendell.app');
    expect(_fieldText(tester, 'Recipient email'), 'reviewer@rivendell.app');
    // Password is never re-hydrated into the field (we never read it back).
    expect(_fieldText(tester, 'App password'), isEmpty);
  });
}
