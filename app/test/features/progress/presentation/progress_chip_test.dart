// ProgressChip — M11 T11.5 (AC 4). Presentation is coverage-excluded; this
// drives the real snapshot + settings providers so the toggle contract holds:
// chip renders by default, and hides entirely when showProgressIndicator flips
// off (the dashboard card is unaffected — only the glance chip is gated).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/progress/presentation/progress_chip.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
  );
  addTearDown(container.dispose);
  addTearDown(db.close);
  return container;
}

Widget _host(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(
    locale: Locale('en'),
    localizationsDelegates: [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: ProgressChip())),
  ),
);

void main() {
  testWidgets('shown by default — renders the level glance', (tester) async {
    final container = _container();
    await container.read(appDatabaseProvider.future);

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    expect(find.text('Level 0'), findsOneWidget);
  });

  testWidgets('toggling showProgressIndicator off hides the chip', (
    tester,
  ) async {
    final container = _container();
    await container.read(appDatabaseProvider.future);

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();
    expect(find.text('Level 0'), findsOneWidget);

    await container
        .read(appSettingsProvider.notifier)
        .setShowProgressIndicator(value: false);
    await tester.pumpAndSettle();

    // The chip returns SizedBox.shrink — no level text in the tree.
    expect(find.text('Level 0'), findsNothing);
  });
}
