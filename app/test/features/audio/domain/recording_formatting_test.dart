import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/domain/recording_formatting.dart';

void main() {
  group('formatDurationMs', () {
    test('null / negative → null (duration unknown)', () {
      expect(formatDurationMs(null), isNull);
      expect(formatDurationMs(-1), isNull);
    });

    test('zero → 0:00', () {
      expect(formatDurationMs(0), '0:00');
    });

    test('sub-minute → m:ss with zero-padded seconds', () {
      expect(formatDurationMs(5000), '0:05');
      expect(formatDurationMs(4200), '0:04');
    });

    test('minutes → m:ss', () {
      expect(formatDurationMs(65_000), '1:05');
      expect(formatDurationMs(599_999), '9:59');
    });

    test('past an hour → h:mm:ss', () {
      expect(formatDurationMs(3_661_000), '1:01:01');
      expect(formatDurationMs(86_400_000), '24:00:00');
    });
  });

  group('formatBytes', () {
    test('under 1 KiB → bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('KiB / MiB range → one decimal under 10', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1_572_864), '1.5 MB');
    });

    test('≥10 rounds to whole units', () {
      expect(formatBytes(20_971_520), '20 MB');
    });

    test('caps at GB', () {
      // ~2.1 GiB stays in GB; does not overflow the unit list.
      expect(
        RegExp(r'^\d+(\.\d)? GB$').hasMatch(formatBytes(2_300_000_000)),
        isTrue,
      );
    });
  });
}
