// Weekly report schedule + fire-time math (T6.6, FR-1.5.3). Pure Dart, no I/O
// — pinned to a caller-supplied "now" so the suite is deterministic. Local
// time throughout; all day-stepping uses calendar arithmetic
// (`DateTime(y, m, d ± n)`) so DST transitions don't drag the wall-clock slot
// off the configured hour (same convention as metrics_window.dart).
//
// Weekday follows Dart's `DateTime.weekday` convention (1=Monday … 7=Sunday).
// Default cadence: Saturday 09:00 (product decision — see plan.md T6.6).

import 'package:flutter/foundation.dart';

/// The day-of-week + time the weekly report fires. Persisted as JSON in the
/// encrypted KV store; read fresh per dispatch so a Settings change takes
/// effect without restarting anything.
@immutable
class ReportSchedule {
  const ReportSchedule({
    this.weekday = DateTime.saturday,
    this.hour = 9,
    this.minute = 0,
  });

  /// Parse from KV-shaped JSON. Values may arrive as `int` or `String`
  /// (Drift returns TEXT for the KV store); missing or unparseable fields fall
  /// back to defaults so a corrupt store never blocks dispatch. Out-of-range
  /// values clamp into range.
  factory ReportSchedule.fromJson(Map<String, Object?> json) {
    int parse(String key, int fallback, int min, int max) {
      final raw = json[key];
      final v = raw is int ? raw : int.tryParse('$raw');
      if (v == null) return fallback;
      if (v < min) return min;
      if (v > max) return max;
      return v;
    }

    return ReportSchedule(
      weekday: parse('weekday', DateTime.saturday, 1, 7),
      hour: parse('hour', 9, 0, 23),
      minute: parse('minute', 0, 0, 59),
    );
  }

  /// `DateTime.monday` … `DateTime.sunday` (1 … 7).
  final int weekday;

  /// 0 … 23, local time.
  final int hour;

  /// 0 … 59, local time.
  final int minute;

  static const ReportSchedule defaults = ReportSchedule();

  ReportSchedule copyWith({int? weekday, int? hour, int? minute}) {
    return ReportSchedule(
      weekday: weekday ?? this.weekday,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, Object?> toJson() => {
    'weekday': weekday,
    'hour': hour,
    'minute': minute,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportSchedule &&
          other.weekday == weekday &&
          other.hour == hour &&
          other.minute == minute);

  @override
  int get hashCode => Object.hash(weekday, hour, minute);

  @override
  String toString() => 'ReportSchedule(weekday=$weekday, $hour:$minute)';
}

/// Walk back to the most recent local midnight whose `weekday` matches
/// `schedule.weekday`, at or before [now].
DateTime _weekStartMidnight(ReportSchedule schedule, DateTime now) {
  var d = DateTime(now.year, now.month, now.day);
  while (d.weekday != schedule.weekday) {
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return d;
}

/// The most recent scheduled instant at or before [now] — the slot the
/// dispatcher should treat as "due" for the current cycle.
DateTime scheduledInstantOnOrBefore(ReportSchedule schedule, DateTime now) {
  final midnight = _weekStartMidnight(schedule, now);
  final candidate = DateTime(
    midnight.year,
    midnight.month,
    midnight.day,
    schedule.hour,
    schedule.minute,
  );
  if (!candidate.isAfter(now)) return candidate;
  // Today's slot hasn't arrived yet → step back 7 days. Calendar arithmetic
  // keeps the wall-clock hour stable across a DST boundary.
  return DateTime(
    midnight.year,
    midnight.month,
    midnight.day - 7,
    schedule.hour,
    schedule.minute,
  );
}

/// The next scheduled instant strictly after [now]. Used by the "next send"
/// indicator in Settings.
DateTime nextFireFrom(ReportSchedule schedule, DateTime now) {
  final midnight = _weekStartMidnight(schedule, now);
  final candidate = DateTime(
    midnight.year,
    midnight.month,
    midnight.day,
    schedule.hour,
    schedule.minute,
  );
  if (candidate.isAfter(now)) return candidate;
  return DateTime(
    midnight.year,
    midnight.month,
    midnight.day + 7,
    schedule.hour,
    schedule.minute,
  );
}

/// True iff the current cycle's slot has arrived and [lastSent] (if any) is
/// from an earlier cycle. This is the gate the workmanager dispatch task
/// polls: it makes the send idempotent within a cycle (a retry later in the
/// week won't double-send) and self-healing (a missed Saturday fires on the
/// next poll until it succeeds, then waits for the next cycle).
bool shouldFireNow(ReportSchedule schedule, DateTime now, DateTime? lastSent) {
  final due = scheduledInstantOnOrBefore(schedule, now);
  if (lastSent == null) return true;
  return lastSent.isBefore(due);
}
