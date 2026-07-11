// Riverpod wiring for user settings (UX feedback item 3). Reads/writes the
// key-value store behind [KvRepository] and exposes a synchronous [AppSettings]
// via [AppSettingsNotifier] — defaults are returned on the first frame and
// hydrated from the store as soon as the DB resolves, so callers never await.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';
import 'package:rivendell/features/settings/domain/app_settings.dart';

const _kAutoAdvanceNext = 'settings.auto_advance_next';
const _kThemePreference = 'settings.theme_preference';
const _kAiImagePromptTemplate = 'settings.ai_image_prompt_template';

/// The [KvRepository] singleton backing user preferences.
final settingsRepositoryProvider = FutureProvider<KvRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return KvRepository(db);
});

/// The current user settings. Defaults are emitted synchronously in build();
/// the persisted values hydrate once the store resolves. Each setter updates
/// state immediately and persists asynchronously (UI never waits on a write).
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _hydrate();
    return const AppSettings();
  }

  Future<void> _hydrate() async {
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      final autoRaw = await repo.read(_kAutoAdvanceNext);
      final themeRaw = await repo.read(_kThemePreference);
      final promptRaw = await repo.read(_kAiImagePromptTemplate);
      // Only an explicit "false" disables auto-advance; a missing key keeps the
      // default-on behavior so upgrades don't surprise existing users.
      final autoAdvance = autoRaw != 'false';
      final theme = ThemePreference.values.firstWhere(
        (t) => t.name == themeRaw,
        orElse: () => ThemePreference.system,
      );
      // A missing or cleared template keeps the default so a fresh install or
      // a user who wiped the field never sends an empty prompt.
      final prompt = (promptRaw == null || promptRaw.trim().isEmpty)
          ? defaultAiImagePrompt
          : promptRaw;
      state = AppSettings(
        autoAdvanceNext: autoAdvance,
        themePreference: theme,
        aiImagePromptTemplate: prompt,
      );
    } on Object {
      // Hydration is best-effort: a missing or corrupt store keeps the defaults
      // so the detail screen's synchronous read never blocks or throws.
    }
  }

  Future<void> setAutoAdvance({required bool value}) async {
    state = state.copyWith(autoAdvanceNext: value);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.write(_kAutoAdvanceNext, value.toString());
  }

  Future<void> setThemePreference(ThemePreference value) async {
    state = state.copyWith(themePreference: value);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.write(_kThemePreference, value.name);
  }

  Future<void> setAiImagePromptTemplate(String value) async {
    // A cleared field snaps back to the default rather than persisting an empty
    // string the engine would have to defend against at drain time.
    final resolved = value.trim().isEmpty ? defaultAiImagePrompt : value;
    if (resolved == state.aiImagePromptTemplate) return;
    state = state.copyWith(aiImagePromptTemplate: resolved);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.write(_kAiImagePromptTemplate, resolved);
  }
}
