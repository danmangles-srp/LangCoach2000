// AppSettingsNotifier — defaults, async hydration from the KV store, and
// persistence across a fresh container (UX feedback item 3). The notifier is
// fire-and-forget on hydration, so a wait-unil helper observes the resolved
// state deterministically rather than racing the microtask queue.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/features/settings/domain/app_settings.dart';

ProviderContainer _container(AppDatabase db) {
  final c = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _until(
  ProviderContainer c,
  bool Function(AppSettings) test,
) async {
  if (test(c.read(appSettingsProvider))) return;
  final completer = Completer<void>();
  final sub = c.listen<AppSettings>(appSettingsProvider, (_, next) {
    if (test(next) && !completer.isCompleted) completer.complete();
  });
  await completer.future.timeout(const Duration(seconds: 1));
  sub.close();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('defaults to auto-advance on + system theme', () {
    final c = _container(db);
    final s = c.read(appSettingsProvider);
    expect(s.autoAdvanceNext, isTrue);
    expect(s.themePreference, ThemePreference.system);
  });

  test(
    'setAutoAdvance(false) updates state and persists across a new container',
    () async {
      final c1 = _container(db);
      await c1.read(settingsRepositoryProvider.future);
      await c1.read(appSettingsProvider.notifier).setAutoAdvance(value: false);
      expect(c1.read(appSettingsProvider).autoAdvanceNext, isFalse);

      final c2 = _container(db);
      await c2.read(settingsRepositoryProvider.future);
      await _until(c2, (s) => s.autoAdvanceNext == false);
      expect(c2.read(appSettingsProvider).autoAdvanceNext, isFalse);
    },
  );

  test('setThemePreference round-trips through the store', () async {
    final c1 = _container(db);
    await c1.read(settingsRepositoryProvider.future);
    await c1
        .read(appSettingsProvider.notifier)
        .setThemePreference(ThemePreference.dark);
    expect(c1.read(appSettingsProvider).themePreference, ThemePreference.dark);

    final c2 = _container(db);
    await c2.read(settingsRepositoryProvider.future);
    await _until(c2, (s) => s.themePreference == ThemePreference.dark);
    expect(c2.read(appSettingsProvider).themePreference, ThemePreference.dark);
  });

  test('a missing key keeps the default-on behavior on hydration', () async {
    final c = _container(db);
    await c.read(settingsRepositoryProvider.future);
    await _until(c, (s) => s.autoAdvanceNext);
    expect(c.read(appSettingsProvider).autoAdvanceNext, isTrue);
  });

  test('a corrupt theme value falls back to system on hydration', () async {
    final repo = KvRepository(db);
    await repo.write('settings.theme_preference', 'hot-pink');
    final c = _container(db);
    await c.read(settingsRepositoryProvider.future);
    await _until(c, (s) => s.themePreference == ThemePreference.system);
    expect(c.read(appSettingsProvider).themePreference, ThemePreference.system);
  });
}
