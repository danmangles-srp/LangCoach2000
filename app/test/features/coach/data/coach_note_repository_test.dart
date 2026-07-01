// CoachNoteRepository — CRUD + agenda links over the Drift store (T5.4,
// FR-1.4.3). In-memory db; the join tables reference recordings / word_logs,
// so a recording + its text log are seeded first to satisfy the FK. Covers
// create-with-links, getById, full-replace-on-update, delete, the all()
// ordering, and that orphaned links don't survive a note delete (cascade).

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/coach/data/coach_note_repository.dart';

AppDatabase _db() => AppDatabase.forTesting(NativeDatabase.memory());

/// Seed a recording + its text word log; return (recordingId, wordLogId).
Future<({int recordingId, int wordLogId})> _seedRefs(AppDatabase db) async {
  final rid = await db
      .into(db.recordings)
      .insert(
        RecordingsCompanion.insert(
          filePath: '/r.m4a',
          name: 'r.m4a',
          createdAt: DateTime(2026, 7),
          sizeBytes: 1,
          format: 'm4a',
        ),
      );
  final wid = await db
      .into(db.wordLogs)
      .insert(
        WordLogsCompanion.insert(
          recordingId: rid,
          kind: 'text',
          body: 'hi: salom',
        ),
      );
  return (recordingId: rid, wordLogId: wid);
}

void main() {
  late AppDatabase db;
  late CoachNoteRepository repo;

  setUp(() {
    db = _db();
    repo = CoachNoteRepository(db);
  });
  tearDown(() => db.close());

  test('create stores title/body and the linked agenda ids', () async {
    final refs = await _seedRefs(db);

    final note = await repo.create(
      title: 'Yor-Yor drill',
      body: 'Run the chorus twice.',
      recordingIds: [refs.recordingId],
      wordLogIds: [refs.wordLogId],
    );

    expect(note.note.title, 'Yor-Yor drill');
    expect(note.note.body, 'Run the chorus twice.');
    expect(note.recordingIds, [refs.recordingId]);
    expect(note.wordLogIds, [refs.wordLogId]);
    expect(note.note.createdAt, equals(note.note.updatedAt));
  });

  test('getById returns null for a missing id', () async {
    expect(await repo.getById(999), isNull);
  });

  test('update rewrites title/body and fully replaces the agenda', () async {
    final refs = await _seedRefs(db);
    final created = await repo.create(
      title: 'draft',
      recordingIds: [refs.recordingId],
    );

    final updated = await repo.update(
      created.note.id,
      title: 'Yor-Yor drill',
      body: 'New script.',
      recordingIds: const [],
      wordLogIds: [refs.wordLogId],
    );

    expect(updated.note.title, 'Yor-Yor drill');
    expect(updated.note.body, 'New script.');
    expect(updated.recordingIds, isEmpty);
    expect(updated.wordLogIds, [refs.wordLogId]);
  });

  test('update on a missing id throws', () async {
    expect(
      () => repo.update(
        999,
        title: 'x',
        recordingIds: const [],
        wordLogIds: const [],
      ),
      throwsStateError,
    );
  });

  test('delete removes the note and cascades its links', () async {
    final refs = await _seedRefs(db);
    final created = await repo.create(
      title: 'gone',
      recordingIds: [refs.recordingId],
      wordLogIds: [refs.wordLogId],
    );

    await repo.delete(created.note.id);

    expect(await repo.getById(created.note.id), isNull);
    // Join rows gone too.
    final joinRows = await db.select(db.coachNoteRecordings).get();
    expect(joinRows, isEmpty);
  });

  test('all returns notes newest-touched first with their agendas', () async {
    final refs = await _seedRefs(db);
    final a = await repo.create(title: 'a', recordingIds: [refs.recordingId]);
    final b = await repo.create(title: 'b');

    // Pin distinct updatedAt instants so the order is deterministic and
    // genuinely reflects "newest-touched first" (b edited after a).
    await (db.update(db.coachNotes)..where((t) => t.id.equals(a.note.id)))
        .write(CoachNotesCompanion(updatedAt: Value(DateTime(2026))));
    await (db.update(db.coachNotes)..where((t) => t.id.equals(b.note.id)))
        .write(CoachNotesCompanion(updatedAt: Value(DateTime(2026, 6))));

    final all = await repo.all();
    expect(all.map((n) => n.note.title), ['b', 'a']);
    final aRow = all.singleWhere((n) => n.note.title == 'a');
    expect(aRow.recordingIds, [refs.recordingId]);
    expect(aRow.wordLogIds, isEmpty);
  });

  test('a note with no links stores empty agendas', () async {
    final note = await repo.create(title: 'solo');
    expect(note.recordingIds, isEmpty);
    expect(note.wordLogIds, isEmpty);
  });
}
