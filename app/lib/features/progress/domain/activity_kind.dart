// ActivityKind (M11 T11.4). The two manual-activity flavors. Mirrors the
// XpSource pattern: a stable column value for persistence + a from-column
// parse for reads.

import 'package:rivendell/features/progress/domain/xp_level.dart';

enum ActivityKind {
  reading('reading'),
  movie('movie');

  const ActivityKind(this.columnValue);

  final String columnValue;

  /// The matching [XpSource] for the +15 award (T11.2 hook).
  XpSource get xpSource =>
      this == ActivityKind.reading ? XpSource.reading : XpSource.movie;

  static ActivityKind fromColumn(String value) =>
      ActivityKind.values.firstWhere(
        (k) => k.columnValue == value,
        orElse: () =>
            throw ArgumentError.value(value, 'value', 'unknown ActivityKind'),
      );
}
