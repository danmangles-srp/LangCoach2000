// FolderRepository — KeyValues-backed folder persistence + warn-once (T1.1).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';

void main() {
  late AppDatabase db;
  late FolderRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FolderRepository(KvRepository(db));
  });

  tearDown(() => db.close());

  test('hasFolder is false until a folder is set', () async {
    expect(await repo.hasFolder(), isFalse);
    expect(await repo.currentFolder(), isNull);
  });

  test('setFolder persists and currentFolder round-trips', () async {
    await repo.setFolder('content://tree/primary%3AVoice%20Recorder');
    expect(await repo.hasFolder(), isTrue);
    expect(
      await repo.currentFolder(),
      'content://tree/primary%3AVoice%20Recorder',
    );
  });

  test('setFolder overwrites a prior pick', () async {
    await repo.setFolder('/old');
    await repo.setFolder('/new');
    expect(await repo.currentFolder(), '/new');
  });

  test('clear forgets the folder', () async {
    await repo.setFolder('/svr');
    await repo.clear();
    expect(await repo.hasFolder(), isFalse);
    expect(await repo.currentFolder(), isNull);
  });

  group('non-SVR warn-once', () {
    test('warns until shown is marked', () async {
      expect(await repo.shouldShowNonSvrWarning(), isTrue);
      await repo.markNonSvrWarningShown();
      expect(await repo.shouldShowNonSvrWarning(), isFalse);
    });
  });
}
