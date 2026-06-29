// Folder onboarding gate + cancel branch (T1.1 B1/B2). Runs on a non-Android
// test host, so the production provider resolves to the placeholder (null),
// which exercises the cancel path. The real SAF picker is device-verified.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';

void main() {
  testWidgets(
    'redirects to onboarding with no folder; placeholder picker shows '
    'a no-folder snackbar',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async {
              ref.onDispose(db.close);
              return db;
            }),
          ],
          child: const RivendellApp(),
        ),
      );
      await tester.pumpAndSettle();

      // No folder persisted → router redirects '/' → '/onboarding'.
      expect(find.text('Point Rivendell at your recordings'), findsOneWidget);

      // Non-Android host → placeholder → null (cancel path).
      await tester.tap(find.text('Choose folder'));
      await tester.tap(find.text('Choose folder'));
      await tester.pumpAndSettle();
      expect(find.text('No folder selected.'), findsOneWidget);
    },
  );
}
