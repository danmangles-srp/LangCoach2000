// ProgressDashboardCard — M11 T11.5 (AC 1/3). Presentation is coverage-excluded;
// this drives the real snapshot provider over an in-memory ledger so the card
// renders level + XP progress + streak + the freeze badge from faked data.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';
import 'package:rivendell/features/progress/presentation/progress_dashboard_card.dart';
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
    home: _Host(),
  ),
);

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: ListView(children: const [ProgressDashboardCard()]));
  }
}

void main() {
  testWidgets(
    'renders level, XP progress, streak, + freeze badge from ledger',
    (tester) async {
      final container = _container();
      final db = await container.read(appDatabaseProvider.future);
      final xp = XpRepository(db);

      // 600 XP -> level 1, 100 XP into the level.
      await xp.record(source: XpSource.review, points: 600);

      // A recording + a review stamped today so the streak is >= 1.
      final recId = await db
          .into(db.recordings)
          .insert(
            RecordingsCompanion.insert(
              filePath: '/svr/lec.m4a',
              name: 'lec.m4a',
              createdAt: DateTime(2026, 3, 15),
              sizeBytes: 1,
              format: 'm4a',
            ),
          );
      final now = DateTime.now();
      await db
          .into(db.reviewEvents)
          .insert(
            ReviewEventsCompanion.insert(
              recordingId: recId,
              milestoneIndex: const Value(0),
              completedAt: DateTime(now.year, now.month, now.day, 12),
            ),
          );

      await tester.pumpWidget(_host(container));
      await tester.pumpAndSettle();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('100 / 500 XP'), findsOneWidget);
      expect(find.textContaining('day streak'), findsOneWidget);
      // First-snapshot auto-grant banks one freeze -> badge shows.
      expect(find.text('Freeze available'), findsOneWidget);
    },
  );

  testWidgets('empty ledger renders level 0 + zero-XP without throwing', (
    tester,
  ) async {
    final container = _container();
    await container.read(appDatabaseProvider.future);

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    expect(find.text('Level 0'), findsOneWidget);
    expect(find.text('0 / 500 XP'), findsOneWidget);
    // xpPerLevel sanity: the constant is what the card divides by.
    expect(xpPerLevel, 500);
  });
}
