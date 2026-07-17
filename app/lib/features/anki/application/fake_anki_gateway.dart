// In-memory [AnkiGateway] for tests and offline UI scaffolding (T4.1). Mirrors
// AnkiDroid's semantics closely enough to drive deck/model resolution and the
// explicit first-field dupe guard the export service relies on: decks/models
// are create-or-find by name, addNote always inserts, and hasNoteWithFirstField
// tracks the first field per model.

import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';

class FakeAnkiGateway implements AnkiGateway {
  final Map<String, int> _deckIds = {};
  final Map<String, int> _modelIds = {};
  final Map<int, Set<String>> _firstFieldsByModel = {};
  int _nextId = 1000;

  /// Names of decks created, in creation order — handy for assertions.
  final List<String> decksCreated = [];
  final List<String> modelsCreated = [];

  /// Every note accepted (non-null), in insertion order.
  final List<AcceptedNote> notes = [];

  /// Per-relativePath media results the fake will return from [addMedia]. A
  /// path absent from the map (or mapped to null) simulates an AnkiDroid import
  /// failure. The value is the formatted field string a real gateway returns.
  final Map<String, String?> mediaResults = {};

  /// What [shouldRequestPermission] returns. Default false = "already granted"
  /// so the happy-path export proceeds without a prompt (mirrors a device that
  /// already granted READ_WRITE). Tests flip this true to drive the gate.
  bool shouldRequestPermissionResult = false;

  /// What [requestPermission] returns. Default true = "user granted" so the
  /// one-time prompt proceeds into the export. Tests flip this false to drive
  /// the denied branch.
  bool requestPermissionResult = true;

  /// Times [requestPermission] was called — lets a test assert the prompt fired
  /// exactly once (no re-prompt loop).
  int requestPermissionCalls = 0;

  @override
  Future<bool> isInstalled() async => true;

  @override
  Future<bool> shouldRequestPermission() async => shouldRequestPermissionResult;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return requestPermissionResult;
  }

  @override
  Future<int> ensureDeck(String name) async {
    final existing = _deckIds[name];
    if (existing != null) return existing;
    final id = _nextId++;
    _deckIds[name] = id;
    decksCreated.add(name);
    return id;
  }

  @override
  Future<int> ensureModel(AnkiModelSpec spec) async {
    final existing = _modelIds[spec.name];
    if (existing != null) return existing;
    final id = _nextId++;
    _modelIds[spec.name] = id;
    modelsCreated.add(spec.name);
    return id;
  }

  @override
  Future<bool> hasNoteWithFirstField({
    required int modelId,
    required String firstField,
  }) async {
    return _firstFieldsByModel[modelId]?.contains(firstField) ?? false;
  }

  @override
  Future<int?> addNote({
    required int deckId,
    required int modelId,
    required List<String> fields,
    required Set<String> tags,
  }) async {
    if (fields.isEmpty) return null;
    final id = _nextId++;
    _firstFieldsByModel
        .putIfAbsent(modelId, () => <String>{})
        .add(fields.first);
    notes.add(
      AcceptedNote(
        id: id,
        deckId: deckId,
        modelId: modelId,
        fields: List<String>.unmodifiable(fields),
        tags: Set<String>.unmodifiable(tags),
      ),
    );
    return id;
  }

  @override
  Future<String?> addMedia({
    required String relativePath,
    required String preferredName,
  }) async {
    return mediaResults[relativePath];
  }
}

class AcceptedNote {
  const AcceptedNote({
    required this.id,
    required this.deckId,
    required this.modelId,
    required this.fields,
    required this.tags,
  });

  final int id;
  final int deckId;
  final int modelId;
  final List<String> fields;
  final Set<String> tags;
}
