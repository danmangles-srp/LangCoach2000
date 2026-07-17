// CoachNoteCommands — the mutation orchestrator seam (T15.5, FR-1.4.3). Locks
// that create/update/delete route through the commands layer over the
// repository, so presentation never touches the data layer directly. Real
// repo on a memory Drift store; the repository's own semantics are covered by
// its own test — this proves the wiring.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/coach/application/coach_note_commands.dart';
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
  late CoachNoteCommands commands;

  setUp(() {
    db = _db();
    commands = CoachNoteCommands(CoachNoteRepository(db));
  });
  tearDown(() => db.close());

  test(
    'create delegates to the repository and persists the note + agenda',
    () async {
      final refs = await _seedRefs(db);

      final note = await commands.create(
        title: 'Yor-Yor drill',
        body: 'Run the chorus twice.',
        recordingIds: [refs.recordingId],
        wordLogIds: [refs.wordLogId],
      );

      expect(note.note.title, 'Yor-Yor drill');
      expect(note.recordingIds, [refs.recordingId]);
      expect(note.wordLogIds, [refs.wordLogId]);
      // And it lands in the read the screen binds to.
      final all = await CoachNoteRepository(db).all();
      expect(all, hasLength(1));
      expect(all.single.note.id, note.note.id);
    },
  );

  test('update delegates and replaces the agenda wholesale', () async {
    final refs = await _seedRefs(db);
    final created = await commands.create(
      title: 'drill',
      recordingIds: [refs.recordingId],
    );

    final updated = await commands.update(
      created.note.id,
      title: 'Yor-Yor drill',
      body: 'Edited script.',
      recordingIds: const [],
      wordLogIds: [refs.wordLogId],
    );

    expect(updated.note.title, 'Yor-Yor drill');
    expect(updated.note.body, 'Edited script.');
    expect(updated.recordingIds, isEmpty);
    expect(updated.wordLogIds, [refs.wordLogId]);
  });

  test('delete delegates and removes the note', () async {
    final refs = await _seedRefs(db);
    final created = await commands.create(
      title: 'bye',
      recordingIds: [refs.recordingId],
    );

    await commands.delete(created.note.id);

    expect(await CoachNoteRepository(db).all(), isEmpty);
  });
}
