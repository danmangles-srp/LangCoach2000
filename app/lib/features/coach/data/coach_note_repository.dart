// Repository over the Coach Bank tables (T5.4, FR-1.4.3). Pure logic over the
// Drift store — no platform deps, fully unit-tested. A note carries its script
// ([title]/[body]) plus the recordings and vocab logs it maps into an agenda.
// Links are replaced wholesale on every create/update (delete-then-insert in a
// transaction) so the caller passes the full desired set and never has to
// diff. Reads return [CoachNoteWithLinks] so the screen gets the agenda in one
// trip; [all] batches the join reads (3 queries total, not N+1).

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';

class CoachNoteWithLinks {
  const CoachNoteWithLinks({
    required this.note,
    required this.recordingIds,
    required this.wordLogIds,
  });

  final CoachNote note;
  final List<int> recordingIds;
  final List<int> wordLogIds;
}

class CoachNoteRepository {
  CoachNoteRepository(this._db);

  final AppDatabase _db;

  Future<CoachNoteWithLinks> create({
    required String title,
    String? body,
    List<int> recordingIds = const [],
    List<int> wordLogIds = const [],
  }) async {
    return _db.transaction(() async {
      final id = await _db
          .into(_db.coachNotes)
          .insert(CoachNotesCompanion.insert(title: title, body: Value(body)));
      await _writeLinks(id, recordingIds, wordLogIds);
      return (await _load(id))!;
    });
  }

  Future<CoachNoteWithLinks?> getById(int id) => _load(id);

  Future<CoachNoteWithLinks> update(
    int id, {
    required String title,
    required List<int> recordingIds,
    required List<int> wordLogIds,
    String? body,
  }) async {
    return _db.transaction(() async {
      final affected =
          await (_db.update(
            _db.coachNotes,
          )..where((t) => t.id.equals(id))).write(
            CoachNotesCompanion(
              title: Value(title),
              body: Value(body),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (affected == 0) {
        throw StateError('coach note $id not found');
      }
      await _writeLinks(id, recordingIds, wordLogIds);
      return (await _load(id))!;
    });
  }

  Future<void> delete(int id) async {
    // Join rows cascade (PRAGMA foreign_keys = ON), so deleting the note
    // clears its agenda links without a separate step.
    await (_db.delete(_db.coachNotes)..where((t) => t.id.equals(id))).go();
  }

  /// Every note with its agenda, newest-touched first. Three queries total
  /// (notes + both join tables), grouped in Dart — never one-per-note.
  Future<List<CoachNoteWithLinks>> all() async {
    final notes =
        await (_db.select(_db.coachNotes)..orderBy([
              (t) => OrderingTerm.desc(t.updatedAt),
              // Tiebreaker so two notes touched within the same millisecond
              // still order deterministically (newest id first).
              (t) => OrderingTerm.desc(t.id),
            ]))
            .get();
    if (notes.isEmpty) return const [];

    final recsByNote = await _recordingIdsByNote();
    final wordsByNote = await _wordLogIdsByNote();

    return [
      for (final n in notes)
        CoachNoteWithLinks(
          note: n,
          recordingIds: recsByNote[n.id] ?? const [],
          wordLogIds: wordsByNote[n.id] ?? const [],
        ),
    ];
  }

  /// Replace a note's agenda links: wipe both join tables for [noteId], then
  /// re-insert the desired set. insertOrIgnore keeps a repeated id from
  /// throwing on the composite key.
  Future<void> _writeLinks(
    int noteId,
    List<int> recordingIds,
    List<int> wordLogIds,
  ) async {
    await (_db.delete(
      _db.coachNoteRecordings,
    )..where((t) => t.noteId.equals(noteId))).go();
    await (_db.delete(
      _db.coachNoteWordLogs,
    )..where((t) => t.noteId.equals(noteId))).go();
    await _db.batch((b) {
      b
        ..insertAll(_db.coachNoteRecordings, [
          for (final r in recordingIds)
            CoachNoteRecordingsCompanion.insert(noteId: noteId, recordingId: r),
        ], mode: InsertMode.insertOrIgnore)
        ..insertAll(_db.coachNoteWordLogs, [
          for (final w in wordLogIds)
            CoachNoteWordLogsCompanion.insert(noteId: noteId, wordLogId: w),
        ], mode: InsertMode.insertOrIgnore);
    });
  }

  Future<Map<int, List<int>>> _recordingIdsByNote() async {
    final rows = await _db.select(_db.coachNoteRecordings).get();
    final byNote = <int, List<int>>{};
    for (final r in rows) {
      byNote.putIfAbsent(r.noteId, () => <int>[]).add(r.recordingId);
    }
    return byNote;
  }

  Future<Map<int, List<int>>> _wordLogIdsByNote() async {
    final rows = await _db.select(_db.coachNoteWordLogs).get();
    final byNote = <int, List<int>>{};
    for (final w in rows) {
      byNote.putIfAbsent(w.noteId, () => <int>[]).add(w.wordLogId);
    }
    return byNote;
  }

  Future<CoachNoteWithLinks?> _load(int id) async {
    final note = await (_db.select(
      _db.coachNotes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (note == null) return null;
    final recs = await (_db.select(
      _db.coachNoteRecordings,
    )..where((t) => t.noteId.equals(id))).map((r) => r.recordingId).get();
    final words = await (_db.select(
      _db.coachNoteWordLogs,
    )..where((t) => t.noteId.equals(id))).map((w) => w.wordLogId).get();
    return CoachNoteWithLinks(
      note: note,
      recordingIds: recs,
      wordLogIds: words,
    );
  }
}
