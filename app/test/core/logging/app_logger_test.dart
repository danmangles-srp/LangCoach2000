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

  group('emitsInBuild', () {
    test('warnings and errors emit in every build', () {
      for (final level in [LogLevel.warning, LogLevel.error]) {
        expect(
          emitsInBuild(level, isDebugBuild: false),
          isTrue,
          reason: '$level in release',
        );
        expect(
          emitsInBuild(level, isDebugBuild: true),
          isTrue,
          reason: '$level in debug',
        );
      }
    });

    test('debug and info emit only in debug builds', () {
      expect(emitsInBuild(LogLevel.debug, isDebugBuild: true), isTrue);
      expect(emitsInBuild(LogLevel.info, isDebugBuild: true), isTrue);
      expect(
        emitsInBuild(LogLevel.debug, isDebugBuild: false),
        isFalse,
        reason: 'debug suppressed in release',
      );
      expect(
        emitsInBuild(LogLevel.info, isDebugBuild: false),
        isFalse,
        reason: 'info suppressed in release',
      );
    });
  });

  group('LogSink level routing', () {
    test('sink receives the level so it can gate by severity', () {
      final captured = <LogLevel>[];
      final sink = _LevelCapturingSink(captured);

      AppLogger(sink: sink)
        ..d(LogTag.mail, 'queued job started')
        ..e(LogTag.mail, 'queued job failed');

      expect(captured, [LogLevel.debug, LogLevel.error]);
    });
  });
}

class _LevelCapturingSink extends LogSink {
  _LevelCapturingSink(this.captured);

  final List<LogLevel> captured;

  @override
  void write(LogLevel level, String line) => captured.add(level);
}
