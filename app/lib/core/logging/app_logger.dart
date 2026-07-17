// Tagged debug logger — the single debug surface for Rivendell.
//
// Tags (one per subsystem): DB / AUDIO / RECORD / ANKI / AI / MAIL / TASK /
// NOTIFY / CHART / CORE (see CLAUDE.md, "Debug surface"). A configurable tag
// set lets a developer follow one subsystem without noise from the rest.
//
// The concrete sink is injectable: tests pass a recording sink; production
// wires a sink that always forwards warnings/errors (so background-work
// failures — MAIL/AI/TASK — survive release builds) and additionally
// forwards debug/info in debug builds.

import 'package:flutter/foundation.dart';

/// A log tag — one per subsystem. Extend this enum as features land.
enum LogTag { db, audio, record, anki, ai, mail, task, notify, chart, core }

/// Severity (the levels a developer cares about at this stage).
///
/// Order matters: `index` comparison in [AppLogger.log] assumes ascending
/// severity (debug < info < warning < error). Do not reorder.
enum LogLevel { debug, info, warning, error }

/// Receives a formatted log line, with its [LogLevel] so a sink can route by
/// severity (e.g. always emit errors, gate debug to debug builds).
abstract class LogSink {
  const LogSink();

  void write(LogLevel level, String line);
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
    sink.write(level, _format(tag, level, message));
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

/// A production sink.
///
/// Warnings and errors always forward to `debugPrint` — these are the levels
/// used to diagnose background-work failures (MAIL/AI/TASK, NFR-2.1.3), which
/// run in release builds where debug/info would otherwise be silent. Debug and
/// info forward only in debug builds to keep release output clean.
class DebugPrintSink extends LogSink {
  const DebugPrintSink();

  @override
  void write(LogLevel level, String line) {
    if (!emitsInBuild(level, isDebugBuild: kDebugMode)) return;
    // avoid_print does not apply to debugPrint.
    debugPrint(line);
  }
}

/// True iff a line at [level] should emit given the build's debug flag.
///
/// Warnings and errors emit in every build; debug and info emit only in debug
/// builds. Pure (no Flutter imports) so the contract is unit-testable without
/// toggling the compile-time `kDebugMode` constant.
bool emitsInBuild(LogLevel level, {required bool isDebugBuild}) {
  final alwaysEmit = level == LogLevel.warning || level == LogLevel.error;
  return alwaysEmit || isDebugBuild;
}

/// A test sink: records every line that survives the filter.
class RecordingSink extends LogSink {
  final List<String> lines = <String>[];

  @override
  void write(LogLevel level, String line) => lines.add(line);
}
