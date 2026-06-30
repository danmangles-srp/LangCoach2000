// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Per-word AI image cache (T4.3, FR-1.3.4). One row per Uzbek word that has
// been successfully rendered by Fal.ai, so a word is generated at most once
// across every recording. The queue handler writes a row only after the image
// bytes are on disk; absence of a row means "not generated" (placeholder).
//
// `uzbekWord` is the natural key. It is stored verbatim (any script: Latin,
// Cyrillic, with diacritics) — case- and script-sensitive on purpose, since
// "salom" and "Салом" are distinct cache entries to a learner.

import 'package:drift/drift.dart';

class AiImageCacheItems extends Table {
  TextColumn get uzbekWord => text()();
  TextColumn get relativePath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {uzbekWord},
  ];
}
