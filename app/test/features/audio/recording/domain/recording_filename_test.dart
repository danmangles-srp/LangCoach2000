// buildRecordingFileName — pure logic (T2.7). No device.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/recording/domain/recording_filename.dart';

void main() {
  test('formats a sortable, zero-padded m4a name', () {
    final name = buildRecordingFileName(
      recordedAt: DateTime(2026, 6, 29, 14, 30, 5),
    );
    expect(name, 'rivendell-2026-0629-143005.m4a');
  });

  test('pads single-digit fields', () {
    final name = buildRecordingFileName(
      recordedAt: DateTime(2026, 1, 1, 1, 1, 1),
    );
    expect(name, 'rivendell-2026-0101-010101.m4a');
  });

  test('always carries the .m4a extension the indexer recognizes', () {
    final name = buildRecordingFileName(
      recordedAt: DateTime(2026, 12, 31, 23, 59, 59),
    );
    expect(name.endsWith('.m4a'), isTrue);
  });
}
