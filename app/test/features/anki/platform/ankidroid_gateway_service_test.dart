// AnkiDroidGatewayService channel contract — T4.1 (FR-1.3.3). Pins the
// 'rivendell/anki' channel name, the method + args shape for each op, the
// install default, and the explicit noteExists dupe check. The Kotlin side
// must answer these calls; runtime round-trip needs AnkiDroid on a device.
// (AnkiDroid's addNote does NOT dedupe — it always inserts.)

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/anki/domain/anki_model_spec.dart';
import 'package:rivendell/features/anki/platform/ankidroid_gateway_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('rivendell/anki');
  late List<MethodCall> calls;
  // First-field tracking lives across the handler within a single test, so
  // noteExists can report a prior addNote's first field as present.
  final knownFirstFields = <String>{};

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          // shouldRequestPermission / requestPermission / isInstalled carry no
          // args; the arg-bearing ops cast inline.
          final args = call.arguments as Map<Object?, Object?>?;
          switch (call.method) {
            case 'isInstalled':
              return true;
            case 'shouldRequestPermission':
              return true;
            case 'requestPermission':
              return false;
            case 'ensureDeck':
              return 7;
            case 'ensureModel':
              return 9;
            case 'noteExists':
              return knownFirstFields.contains(args?['firstField']);
            case 'addNote':
              final fields =
                  (args?['fields'] as List?)?.cast<String>() ?? const [];
              if (fields.isNotEmpty) knownFirstFields.add(fields.first);
              return 11; // always inserts — no dupe-null
            default:
              return null;
          }
        });
  });

  tearDown(() {
    knownFirstFields.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'isInstalled maps to the channel and defaults to false on null',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      expect(await AnkiDroidGatewayService().isInstalled(), isFalse);
    },
  );

  test('shouldRequestPermission maps to the channel (T16.2)', () async {
    final result = await AnkiDroidGatewayService().shouldRequestPermission();
    expect(result, isTrue);
    expect(calls.single.method, 'shouldRequestPermission');
    expect(calls.single.arguments, isNull);
  });

  test(
    'shouldRequestPermission defaults to false on a null channel reply',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      expect(
        await AnkiDroidGatewayService().shouldRequestPermission(),
        isFalse,
      );
    },
  );

  test('requestPermission maps to the channel (T16.2)', () async {
    final result = await AnkiDroidGatewayService().requestPermission();
    expect(result, isFalse);
    expect(calls.single.method, 'requestPermission');
    expect(calls.single.arguments, isNull);
  });

  test('requestPermission defaults to false on a null channel reply', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    expect(await AnkiDroidGatewayService().requestPermission(), isFalse);
  });

  test('ensureDeck sends name and returns the id', () async {
    final id = await AnkiDroidGatewayService().ensureDeck('Rivendell::L1');
    expect(id, 7);
    expect(calls.single.method, 'ensureDeck');
    expect(calls.single.arguments, {'name': 'Rivendell::L1'});
  });

  test('ensureModel sends the full spec shape', () async {
    final id = await AnkiDroidGatewayService().ensureModel(ankiType1Model);
    expect(id, 9);
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['name'], ankiType1Model.name);
    expect(args['fields'], ankiType1Model.fields);
    expect(args['front'], ankiType1Model.frontTemplate);
    expect(args['back'], ankiType1Model.backTemplate);
    expect(args['css'], ankiType1Model.css);
  });

  test('ensureDeck throws when the adapter returns no id', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => -1);
    expect(() => AnkiDroidGatewayService().ensureDeck('x'), throwsStateError);
  });

  test('hasNoteWithFirstField maps to noteExists + defaults false', () async {
    final service = AnkiDroidGatewayService();
    expect(
      await service.hasNoteWithFirstField(modelId: 9, firstField: 'cat'),
      isFalse,
    );
    await service.addNote(
      deckId: 7,
      modelId: 9,
      fields: ['cat', 'mushuk'],
      tags: {},
    );
    expect(
      await service.hasNoteWithFirstField(modelId: 9, firstField: 'cat'),
      isTrue,
    );
  });

  test('addNote sends ids + fields + tags and always returns an id', () async {
    final id = await AnkiDroidGatewayService().addNote(
      deckId: 7,
      modelId: 9,
      fields: ['cat', 'mushuk'],
      tags: {'lecture-1'},
    );
    expect(id, 11);
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['deckId'], 7);
    expect(args['modelId'], 9);
    expect(args['fields'], ['cat', 'mushuk']);
    expect(args['tags'], ['lecture-1']);
  });

  test(
    'addNote inserts again on a repeated first field (no auto-dedupe)',
    () async {
      final service = AnkiDroidGatewayService();
      final first = await service.addNote(
        deckId: 7,
        modelId: 9,
        fields: ['cat', 'mushuk'],
        tags: {},
      );
      final second = await service.addNote(
        deckId: 7,
        modelId: 9,
        fields: ['cat', 'mushuk'],
        tags: {},
      );
      expect(first, 11);
      expect(second, 11); // caller must guard via noteExists, not addNote
    },
  );
}
