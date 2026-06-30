// AiImageCacheRepository (T4.3). Pure logic over an in-memory Drift store.
// The cache is the "is this word generated?" oracle: a row exists iff the
// image is ready, and re-remembering a word overwrites (regeneration) rather
// than colliding.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';

void main() {
  late AppDatabase db;
  late AiImageCacheRepository cache;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cache = AiImageCacheRepository(db);
  });

  tearDown(() => db.close());

  test('pathFor is null before a word is remembered', () async {
    expect(await cache.pathFor('salom'), isNull);
    expect(await cache.has('salom'), isFalse);
  });

  test('remember records the path, has/pathFor see it', () async {
    await cache.remember(uzbekWord: 'salom', relativePath: 'ai_images/ab.png');

    expect(await cache.has('salom'), isTrue);
    expect(await cache.pathFor('salom'), 'ai_images/ab.png');
  });

  test(
    'remember is insert-or-replace on the word key (regeneration)',
    () async {
      await cache.remember(
        uzbekWord: 'salom',
        relativePath: 'ai_images/old.png',
      );
      await cache.remember(
        uzbekWord: 'salom',
        relativePath: 'ai_images/new.png',
      );

      expect(await cache.pathFor('salom'), 'ai_images/new.png');
      // No duplicate row.
      final rows = await db.select(db.aiImageCacheItems).get();
      expect(rows, hasLength(1));
    },
  );

  test(
    'words are case- and script-sensitive (distinct cache entries)',
    () async {
      await cache.remember(uzbekWord: 'salom', relativePath: 'a.png');
      await cache.remember(uzbekWord: 'Salom', relativePath: 'b.png');
      await cache.remember(uzbekWord: 'Салом', relativePath: 'c.png');

      expect(await cache.pathFor('salom'), 'a.png');
      expect(await cache.pathFor('Salom'), 'b.png');
      expect(await cache.pathFor('Салом'), 'c.png');
    },
  );
}
