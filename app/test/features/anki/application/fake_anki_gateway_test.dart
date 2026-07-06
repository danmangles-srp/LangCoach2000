// FakeAnkiGateway + AnkiModelSpec — T4.1 (FR-1.3.3). Pins the create-or-find
// id stability for decks/models and the first-field dupe semantics the export
// service relies on, plus the predefined Type 1 / Type 2 model shapes.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/anki/application/fake_anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';

void main() {
  group('AnkiModelSpec', () {
    test('Type 1 maps English front → Uzbek back', () {
      expect(ankiType1Model.fields, ['English', 'Uzbek']);
      expect(ankiType1Model.frontTemplate, contains('{{English}}'));
      expect(ankiType1Model.backTemplate, contains('{{Uzbek}}'));
    });

    test('Type 2 maps Image front → Uzbek back', () {
      expect(ankiType2Model.fields, ['Uzbek', 'Image']);
      expect(ankiType2Model.frontTemplate, contains('{{Image}}'));
      expect(ankiType2Model.backTemplate, contains('{{Uzbek}}'));
    });
  });

  group('FakeAnkiGateway', () {
    late FakeAnkiGateway gateway;

    setUp(() => gateway = FakeAnkiGateway());

    test('ensureDeck is create-or-find: same name → same id', () async {
      final first = await gateway.ensureDeck('Rivendell::Lecture 1');
      final second = await gateway.ensureDeck('Rivendell::Lecture 1');
      expect(second, first);
      expect(gateway.decksCreated, ['Rivendell::Lecture 1']);
    });

    test('ensureModel is create-or-find by name', () async {
      final first = await gateway.ensureModel(ankiType1Model);
      final second = await gateway.ensureModel(ankiType1Model);
      expect(second, first);
      expect(gateway.modelsCreated, [ankiType1Model.name]);
    });

    test('addNote accepts a fresh first field', () async {
      final deck = await gateway.ensureDeck('d');
      final model = await gateway.ensureModel(ankiType1Model);
      final id = await gateway.addNote(
        deckId: deck,
        modelId: model,
        fields: ['cat', 'mushuk'],
        tags: {'lecture-1'},
      );
      expect(id, isNotNull);
      expect(gateway.notes.single.tags, {'lecture-1'});
    });

    test('addNote always inserts (no auto-dedupe)', () async {
      final deck = await gateway.ensureDeck('d');
      final model = await gateway.ensureModel(ankiType1Model);
      final first = await gateway.addNote(
        deckId: deck,
        modelId: model,
        fields: ['cat', 'mushuk'],
        tags: {'lecture-1'},
      );
      final second = await gateway.addNote(
        deckId: deck,
        modelId: model,
        fields: ['cat', 'mushuk'],
        tags: {'lecture-1'},
      );
      expect(first, isNotNull);
      expect(second, isNotNull); // AnkiDroid inserts again — caller must guard
      expect(gateway.notes, hasLength(2));
    });

    test('hasNoteWithFirstField is the idempotency guard', () async {
      final deck = await gateway.ensureDeck('d');
      final model = await gateway.ensureModel(ankiType1Model);
      expect(
        await gateway.hasNoteWithFirstField(modelId: model, firstField: 'cat'),
        isFalse,
      );
      await gateway.addNote(
        deckId: deck,
        modelId: model,
        fields: ['cat', 'mushuk'],
        tags: {},
      );
      expect(
        await gateway.hasNoteWithFirstField(modelId: model, firstField: 'cat'),
        isTrue,
      );
      expect(
        await gateway.hasNoteWithFirstField(modelId: model, firstField: 'dog'),
        isFalse,
      );
    });

    test('first fields are scoped per model', () async {
      final deck = await gateway.ensureDeck('d');
      final m1 = await gateway.ensureModel(ankiType1Model);
      final m2 = await gateway.ensureModel(ankiType2Model);
      await gateway.addNote(
        deckId: deck,
        modelId: m1,
        fields: ['cat', 'mushuk'],
        tags: {},
      );
      // Same first field under a different model is not a dupe.
      expect(
        await gateway.hasNoteWithFirstField(modelId: m2, firstField: 'cat'),
        isFalse,
      );
    });
  });
}
