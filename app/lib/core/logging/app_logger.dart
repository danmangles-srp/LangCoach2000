// Tagged debug logger — the single debug surface for Rivendell.
//
// Tags (one per subsystem): DB / AUDIO / RECORD / ANKI / AI / MAIL / TASK /
// NOTIFY / CHART / CORE (see CLAUDE.md, "Debug surface"). A configurable tag
// set lets a developer follow one subsystem without noise from the rest.
//
// The concrete sink is injectable: tests pass a recording sink; production
// wires a debug-print sink (no-op outside debug builds).

import 'package:flutter/foundation.dart';

/// A log tag — one per subsystem. Extend this enum as features land.
enum LogTag { db, audio, record, anki, ai, mail, task, notify, chart, core }

/// Severity (the levels a developer cares about at this stage).
enum LogLevel { debug, info, warning, error }

/// Receives a formatted log line.
abstract class LogSink {
  const LogSink();

  void write(String line);
}

/// A tagged, filterable logger.
///
/// `enabledTags` gates which messages reach the sink: empty means "all tags".
/// `minLevel` drops anything below the floor.
class AppLogger {
  AppLogger({
    required this.sink,
    this.enabledTags = const <LogTag>{},
    this.minLevel = LogLevel.debug,
  });

  final LogSink sink;
  final Set<LogTag> enabledTags;
  final LogLevel minLevel;

  /// Log `message` under `tag` at `level`.
  void log(LogTag tag, String message, {LogLevel level = LogLevel.debug}) {
    if (!_passes(tag, level)) return;
    sink.write(_format(tag, level, message));
  }

  /// True iff this tag/level survives the filter.
  bool _passes(LogTag tag, LogLevel level) {
    if (level.index < minLevel.index) return false;
    if (enabledTags.isEmpty) return true;
    return enabledTags.contains(tag);
  }

  String _format(LogTag tag, LogLevel level, String message) {
    final tagStr = tag.name.toUpperCase();
    final levelStr = level.name.toUpperCase();
    return '[$tagStr][$levelStr] $message';
  }

  // Convenience per level -------------------------------------------------

  void d(LogTag tag, String message) => log(tag, message);
  void i(LogTag tag, String message) => log(tag, message, level: LogLevel.info);
  void w(LogTag tag, String message) =>
      log(tag, message, level: LogLevel.warning);
  void e(LogTag tag, String message) =>
      log(tag, message, level: LogLevel.error);
}

/// A production sink: forwards to `debugPrint` only in debug builds.
class DebugPrintSink extends LogSink {
  const DebugPrintSink();

  @override
  void write(String line) {
    if (kDebugMode) {
      // avoid_print does not apply to debugPrint.
      debugPrint(line);
    }
  }
}

/// A test sink: records every line that survives the filter.
class RecordingSink extends LogSink {
  final List<String> lines = <String>[];

  @override
  void write(String line) => lines.add(line);
}
