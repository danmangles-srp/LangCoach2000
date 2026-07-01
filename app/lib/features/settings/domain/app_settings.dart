// App-wide user preferences (UX feedback item 3: a settings page). Plain
// immutable value type — persisted as strings via the key-value repository and
// surfaced synchronously through AppSettingsNotifier so the detail screen can
// read the auto-advance flag without awaiting, and the root widget can resolve
// the theme on the first frame.

/// The persisted theme mode. Standalone (rather than Flutter's ThemeMode) so
/// the domain layer doesn't depend on the material library.
enum ThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.autoAdvanceNext = true,
    this.themePreference = ThemePreference.system,
  });

  /// On natural playback completion, cue + navigate to the next recording in
  /// the launch context (T8.2). Defaults on — the prior behavior. When off, the
  /// transport stops at the end and shows the replay affordance.
  final bool autoAdvanceNext;

  final ThemePreference themePreference;

  AppSettings copyWith({
    bool? autoAdvanceNext,
    ThemePreference? themePreference,
  }) {
    return AppSettings(
      autoAdvanceNext: autoAdvanceNext ?? this.autoAdvanceNext,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
