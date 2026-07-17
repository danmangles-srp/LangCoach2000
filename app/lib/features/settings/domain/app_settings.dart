// App-wide user preferences (UX feedback item 3: a settings page). Plain
// immutable value type — persisted as strings via the key-value repository and
// surfaced synchronously through AppSettingsNotifier so the detail screen can
// read the auto-advance flag without awaiting, and the root widget can resolve
// the theme on the first frame.

import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

/// The persisted theme mode. Standalone (rather than Flutter's ThemeMode) so
/// the domain layer doesn't depend on the material library.
enum ThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.autoAdvanceNext = true,
    this.themePreference = ThemePreference.system,
    this.aiImagePromptTemplate = defaultAiImagePrompt,
  });

  /// On natural playback completion, cue + navigate to the next recording in
  /// the launch context (T8.2). Defaults on — the prior behavior. When off, the
  /// transport stops at the end and shows the replay affordance.
  final bool autoAdvanceNext;

  final ThemePreference themePreference;

  /// User-tunable AI image prompt template (T19.6). `{word}` is substituted at
  /// drain time. Defaults to [defaultAiImagePrompt]; a blank value is treated
  /// as the default by the notifier so the engine never sends an empty prompt.
  final String aiImagePromptTemplate;

  AppSettings copyWith({
    bool? autoAdvanceNext,
    ThemePreference? themePreference,
    String? aiImagePromptTemplate,
  }) {
    return AppSettings(
      autoAdvanceNext: autoAdvanceNext ?? this.autoAdvanceNext,
      themePreference: themePreference ?? this.themePreference,
      aiImagePromptTemplate:
          aiImagePromptTemplate ?? this.aiImagePromptTemplate,
    );
  }
}
