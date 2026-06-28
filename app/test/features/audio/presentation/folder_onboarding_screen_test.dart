// Folder onboarding gate + placeholder-picker cancel branch (T1.1 B1).
// The real SAF picker (B2) is device-verified; this proves the router gate,
// the screen render, and the null-result path through the placeholder.

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

      // Placeholder picker returns null (B2 wires the real SAF channel).
      await tester.tap(find.text('Choose folder'));
      await tester.pumpAndSettle();
      expect(find.text('No folder selected.'), findsOneWidget);
    },
  );
}
