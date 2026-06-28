// AppLogger — tag-filtering and level-floor unit tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('empty enabledTags passes every tag', () {
      final sink = RecordingSink();
      AppLogger(sink: sink)
        ..d(LogTag.db, 'db msg')
        ..i(LogTag.audio, 'audio msg')
        ..e(LogTag.anki, 'anki msg');

      expect(sink.lines.length, 3);
    });

    test('enabledTags filters to the configured set', () {
      final sink = RecordingSink();
      AppLogger(sink: sink, enabledTags: const {LogTag.db, LogTag.audio})
        ..d(LogTag.db, 'kept')
        ..d(LogTag.audio, 'kept')
        ..d(LogTag.anki, 'dropped')
        ..d(LogTag.mail, 'dropped');

      expect(sink.lines.length, 2);
      expect(sink.lines.every((l) => l.contains('kept')), isTrue);
    });

    test('minLevel drops anything below the floor', () {
      final sink = RecordingSink();
      AppLogger(sink: sink, minLevel: LogLevel.warning)
        ..d(LogTag.core, 'debug dropped')
        ..i(LogTag.core, 'info dropped')
        ..w(LogTag.core, 'warning kept')
        ..e(LogTag.core, 'error kept');

      expect(sink.lines.length, 2);
      expect(sink.lines.first, contains('[WARNING]'));
      expect(sink.lines.last, contains('[ERROR]'));
    });

    test('formatted line carries the uppercased tag and level', () {
      final sink = RecordingSink();
      AppLogger(sink: sink).i(LogTag.audio, 'hello');

      expect(sink.lines.single, '[AUDIO][INFO] hello');
    });

    test('RecordingSink records in insertion order', () {
      final sink = RecordingSink();
      AppLogger(sink: sink)
        ..d(LogTag.core, 'first')
        ..d(LogTag.core, 'second');

      expect(sink.lines, ['[CORE][DEBUG] first', '[CORE][DEBUG] second']);
    });
  });
}
