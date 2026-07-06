import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/l10n/app_strings.dart';

void main() {
  group('AppStrings', () {
    test('uz bundle is distinct from en for every public string', () {
      const en = AppStrings(Locale('en'));
      const uz = AppStrings(Locale('uz'));
      // Every shipped user-facing string has a non-empty Uzbek translation
      // that differs from English — guards against copy-paste leaving en in
      // both bundles.
      expect(uz.recordingsTitle, isNotEmpty);
      expect(uz.recordingsTitle, isNot(en.recordingsTitle));
      expect(uz.emptyTitle, isNotEmpty);
      expect(uz.emptyTitle, isNot(en.emptyTitle));
      expect(uz.emptyBody, isNotEmpty);
      expect(uz.emptyBody, isNot(en.emptyBody));
      expect(uz.emptyHint, isNotEmpty);
      expect(uz.emptyHint, isNot(en.emptyHint));
      expect(uz.loading, isNotEmpty);
      expect(uz.loading, isNot(en.loading));
      expect(uz.errorTitle, isNotEmpty);
      expect(uz.errorTitle, isNot(en.errorTitle));
      expect(uz.retry, isNotEmpty);
      expect(uz.retry, isNot(en.retry));
      expect(uz.scanTooltip, isNotEmpty);
      expect(uz.scanTooltip, isNot(en.scanTooltip));
      expect(uz.scanFailed, isNotEmpty);
      expect(uz.scanFailed, isNot(en.scanFailed));
    });

    test('scannedCount interpolates the number and differs per locale', () {
      const en = AppStrings(Locale('en'));
      const uz = AppStrings(Locale('uz'));
      expect(en.scannedCount(12), contains('12'));
      expect(uz.scannedCount(12), contains('12'));
      expect(uz.scannedCount(12), isNot(en.scannedCount(12)));
    });

    test('record strings differ per locale and interpolate the name', () {
      const en = AppStrings(Locale('en'));
      const uz = AppStrings(Locale('uz'));
      expect(uz.recordTooltip, isNot(en.recordTooltip));
      expect(uz.recordStop, isNot(en.recordStop));
      expect(uz.recordFailed, isNot(en.recordFailed));
      expect(en.recordSaved('x.m4a'), contains('x.m4a'));
      expect(uz.recordSaved('x.m4a'), isNot(en.recordSaved('x.m4a')));
    });

    test('unknown locale falls back to English', () {
      const fr = AppStrings(Locale('fr'));
      expect(fr.recordingsTitle, 'Recordings');
    });

    test('placeholders are stable across locales', () {
      const en = AppStrings(Locale('en'));
      const uz = AppStrings(Locale('uz'));
      expect(en.unknownDuration, uz.unknownDuration);
      expect(en.unknownFormat, uz.unknownFormat);
    });

    test('supportedLocales includes uz + en', () {
      final codes = AppStrings.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      expect(codes, containsAll(const ['en', 'uz']));
    });

    test('delegate loads synchronously for supported locales', () async {
      const delegate = AppStrings.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('uz')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      final loaded = await delegate.load(const Locale('uz'));
      expect(loaded.recordingsTitle, 'Yozuvlar');
    });
  });
}
