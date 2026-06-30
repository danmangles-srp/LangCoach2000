// Pure filename builder for in-app recordings (FR-1.1.3, T2.7). The recorder
// saves into the user-designated Samsung folder; a stable, sortable name keeps
// the new file discoverable in both Rivendell and the user's file manager.
//
// `recordedAt` is taken in (not DateTime.now()) so the format is deterministic
// and unit-testable. Local time, matching how the indexer stores `createdAt`
// (cursor epoch ms → DateTime.fromMillisecondsSinceEpoch, local).

/// `rivendell-YYYY-MMdd-HHmmss.m4a` — zero-padded, chronological on sort.
String buildRecordingFileName({required DateTime recordedAt}) {
  String two(int n) => n.toString().padLeft(2, '0');
  String four(int n) => n.toString().padLeft(4, '0');
  final y = four(recordedAt.year);
  final mo = two(recordedAt.month);
  final d = two(recordedAt.day);
  final h = two(recordedAt.hour);
  final mi = two(recordedAt.minute);
  final s = two(recordedAt.second);
  return 'rivendell-$y-$mo$d-$h$mi$s.m4a';
}
