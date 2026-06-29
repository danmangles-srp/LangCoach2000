// Rivendell — minimal, dependency-free localizations (NFR-2.5.x).
//
// Flutter's gen_l10n would pull flutter_localizations, which forces an intl
// bump that clashes with the project's pinned matrix (intl ^0.19). Until that
// pin moves, we hand-roll a Localizations<AppStrings>: externalized, locale-
// aware strings with Uzbek (uz) as a first-class locale — Rivendell is for
// learners of Uzbek — and English (en) as the fallback/seed. Migrating to
// gen_l10n later is a mechanical ARB port; the call sites (AppStrings.of) stay.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// The locales Rivendell ships translations for, in priority order. Drives
  /// `MaterialApp.supportedLocales`. Keep the seed locale last so the device
  /// locale resolves to a translation when one exists.
  static const List<Locale> supportedLocales = [Locale('uz'), Locale('en')];

  static const _en = _Bundle(
    recordingsTitle: 'Recordings',
    emptyTitle: 'No recordings yet',
    emptyBody:
        'Point Rivendell at your Samsung Voice Recorder folder and your '
        'recordings will appear here.',
    loading: 'Loading recordings…',
    errorTitle: "Couldn't load recordings",
    retry: 'Try again',
    unknownDuration: '—:—',
    unknownFormat: 'audio',
  );

  static const _uz = _Bundle(
    recordingsTitle: 'Yozuvlar',
    emptyTitle: "Hozircha yozuvlar yo'q",
    emptyBody:
        "Rivendell'ni Samsung Voice Recorder jildiga yo'naltiring — "
        'yozuvlaringiz shu yerda paydo bo‘ladi.',
    loading: 'Yozuvlar yuklanmoqda…',
    errorTitle: "Yozuvlarni yuklab bo'lmadi",
    retry: 'Qayta urinib ko‘ring',
    unknownDuration: '—:—',
    unknownFormat: 'audio',
  );

  // Resolve the bundle for the active locale, falling back to English.
  _Bundle get _bundle => locale.languageCode == 'uz' ? _uz : _en;

  String get recordingsTitle => _bundle.recordingsTitle;
  String get emptyTitle => _bundle.emptyTitle;
  String get emptyBody => _bundle.emptyBody;
  String get loading => _bundle.loading;
  String get errorTitle => _bundle.errorTitle;
  String get retry => _bundle.retry;
  String get unknownDuration => _bundle.unknownDuration;
  String get unknownFormat => _bundle.unknownFormat;

  // The standard Flutter Localizations accessor convention (`AppStrings.of`);
  // VGA's "static method → constructor" lint doesn't fit the lookup pattern.
  // ignore: prefer_constructors_over_static_methods
  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    return strings ?? const AppStrings(Locale('en'));
  }
}

@immutable
class _Bundle {
  const _Bundle({
    required this.recordingsTitle,
    required this.emptyTitle,
    required this.emptyBody,
    required this.loading,
    required this.errorTitle,
    required this.retry,
    required this.unknownDuration,
    required this.unknownFormat,
  });

  final String recordingsTitle;
  final String emptyTitle;
  final String emptyBody;
  final String loading;
  final String errorTitle;
  final String retry;
  final String unknownDuration;
  final String unknownFormat;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    final code = locale.languageCode;
    return code == 'en' || code == 'uz';
  }

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
