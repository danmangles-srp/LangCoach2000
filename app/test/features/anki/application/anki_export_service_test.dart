// Type 1 Anki export (M4, T4.2). Drives [AnkiExportService.exportType1]
// through the in-memory [FakeAnkiGateway] — no device, no channel. The
// contract under test is idempotency: re-exporting the same recording skips
// everything because the first-field guard fires, and a fresh pair set only
// inserts what is genuinely new. Failures (addNote → null) are counted, not
// mistaken for dupes.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/anki/application/anki_export_service.dart';
import 'package:rivendell/features/anki/application/fake_anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';
import 'package:rivendell/features/anki/domain/anki_tag.dart';
import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';

void main() {
  late FakeAnkiGateway gateway;
  late RecordingSink sink;
  late AnkiExportService service;

  setUp(() {
    gateway = FakeAnkiGateway();
    sink = RecordingSink();
    service = AnkiExportService(
      gateway: gateway,
      logger: AppLogger(sink: sink),
    );
  });

  List<VocabPair> pairs([List<(String, String)> raw = const []]) =>
      raw.map((e) => VocabPair(english: e.$1, uzbek: e.$2)).toList();

  test('resolves the Rivendell deck and the Type 1 model once', () async {
    await service.exportType1(tag: 'Lecture 1.m4a', pairs: pairs());

    expect(gateway.decksCreated, ['Rivendell']);
    expect(gateway.modelsCreated, [ankiType1Model.name]);
  });

  test(
    'inserts every fresh pair, tagged by the sanitized recording name',
    () async {
      final result = await service.exportType1(
        tag: 'My Lecture 3.m4a',
        pairs: pairs([('hello', 'salom'), ('goodbye', 'xayr')]),
      );

      expect(result.added, 2);
      expect(result.skipped, 0);
      expect(result.failed, 0);

      expect(gateway.notes.length, 2);
      expect(gateway.notes[0].fields, ['hello', 'salom']);
      expect(gateway.notes[0].tags, {'My_Lecture_3.m4a'});
      expect(gateway.notes[1].fields, ['goodbye', 'xayr']);
      expect(gateway.notes[1].tags, {'My_Lecture_3.m4a'});
    },
  );

  test(
    'is idempotent: re-exporting the same recording skips everything',
    () async {
      final raw = pairs([('hello', 'salom'), ('goodbye', 'xayr')]);
      await service.exportType1(tag: 'Lecture.m4a', pairs: raw);

      final second = await service.exportType1(tag: 'Lecture.m4a', pairs: raw);

      expect(second.added, 0);
      expect(second.skipped, 2);
      expect(second.failed, 0);
      // No new rows created on the second pass.
      expect(gateway.notes.length, 2);
    },
  );

  test('only inserts pairs whose English field is genuinely new', () async {
    await service.exportType1(
      tag: 'Lecture.m4a',
      pairs: pairs([('hello', 'salom'), ('goodbye', 'xayr')]),
    );

    final second = await service.exportType1(
      tag: 'Lecture.m4a',
      pairs: pairs([
        ('hello', 'salom'), // dupe — skipped
        ('thanks', 'rahmat'), // new — added
      ]),
    );

    expect(second.added, 1);
    expect(second.skipped, 1);
    expect(second.failed, 0);
    expect(gateway.notes.last.fields, ['thanks', 'rahmat']);
  });

  test('counts a null insert as failed, not skipped', () async {
    // FakeAnkiGateway returns null only for empty field lists, which a real
    // parser never produces — so emulate a hard AnkiDroid failure by rejecting
    // the first insert only.
    final flaky = _RejectingGateway(rejectsAfter: 1);
    final flakyService = AnkiExportService(
      gateway: flaky,
      logger: AppLogger(sink: sink),
    );

    final result = await flakyService.exportType1(
      tag: 'Lecture.m4a',
      pairs: pairs([('hello', 'salom'), ('thanks', 'rahmat')]),
    );

    expect(result.failed, 1);
    expect(result.added, 1);
    expect(result.skipped, 0);
  });

  test('emits one info log line summarizing the run', () async {
    await service.exportType1(
      tag: 'Lecture.m4a',
      pairs: pairs([('hello', 'salom')]),
    );

    final ankiLines = sink.lines
        .where((l) => l.startsWith('[ANKI][INFO]'))
        .toList();
    expect(ankiLines.length, 1);
    expect(ankiLines.single, contains('type1 export tag=Lecture.m4a'));
    expect(ankiLines.single, contains('added=1'));
    expect(ankiLines.single, contains('skipped=0'));
  });

  test('uses the canonical deck name from ankiTag module', () async {
    await service.exportType1(tag: 'x', pairs: pairs());

    // Deck name constant is shared between the service and this test via the
    // domain module, so a rename there flips both.
    expect(gateway.decksCreated.single, ankiDeckName);
  });
}

/// A gateway that rejects the first `rejectsAfter` addNote calls (returns
/// null), then behaves like the fake. Used to assert that a null insert is
/// counted as a failure rather than a skip.
class _RejectingGateway extends FakeAnkiGateway {
  _RejectingGateway({required this.rejectsAfter});
  int rejectsAfter;

  @override
  Future<int?> addNote({
    required int deckId,
    required int modelId,
    required List<String> fields,
    required Set<String> tags,
  }) async {
    if (rejectsAfter > 0) {
      rejectsAfter--;
      return null;
    }
    return super.addNote(
      deckId: deckId,
      modelId: modelId,
      fields: fields,
      tags: tags,
    );
  }
}
