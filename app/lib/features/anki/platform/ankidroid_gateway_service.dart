// AnkiDroid-backed [AnkiGateway] (M4, FR-1.3.3, T4.1). Thin MethodChannel
// wrapper over the Kotlin side, which resolves ids against AnkiDroid's
// content provider and reports install state. The channel is injectable so
// the contract is pinneable without a device.

import 'package:flutter/services.dart';

import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';

class AnkiDroidGatewayService implements AnkiGateway {
  AnkiDroidGatewayService([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('rivendell/anki');

  final MethodChannel _channel;

  @override
  Future<bool> isInstalled() async {
    final result = await _channel.invokeMethod<bool>('isInstalled');
    return result ?? false;
  }

  @override
  Future<int> ensureDeck(String name) async {
    final id = await _channel.invokeMethod<int>('ensureDeck', {'name': name});
    if (id == null || id < 0) {
      throw StateError('ensureDeck("$name") returned no id');
    }
    return id;
  }

  @override
  Future<int> ensureModel(AnkiModelSpec spec) async {
    final id = await _channel.invokeMethod<int>('ensureModel', {
      'name': spec.name,
      'fields': spec.fields,
      'front': spec.frontTemplate,
      'back': spec.backTemplate,
      'css': spec.css,
    });
    if (id == null || id < 0) {
      throw StateError('ensureModel("${spec.name}") returned no id');
    }
    return id;
  }

  @override
  Future<bool> hasNoteWithFirstField({
    required int modelId,
    required String firstField,
  }) async {
    final result = await _channel.invokeMethod<bool>('noteExists', {
      'modelId': modelId,
      'firstField': firstField,
    });
    return result ?? false;
  }

  @override
  Future<int?> addNote({
    required int deckId,
    required int modelId,
    required List<String> fields,
    required Set<String> tags,
  }) async {
    return _channel.invokeMethod<int>('addNote', {
      'deckId': deckId,
      'modelId': modelId,
      'fields': fields,
      'tags': tags.toList(),
    });
  }

  @override
  Future<String?> addMedia({
    required String relativePath,
    required String preferredName,
  }) async {
    return _channel.invokeMethod<String>('addMedia', {
      'relativePath': relativePath,
      'preferredName': preferredName,
    });
  }
}
