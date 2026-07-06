// RecordingNavContext (M8, T8.2). Pure logic — the auto-advance id rule:
// queue launches pick the next id in order; library launches pick the
// preceding id; null at the ends / when the id isn't in the peer list.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';

RecordingNavContext _nav(List<int> ids, RecordingLaunchSource source) =>
    RecordingNavContext(peerIds: ids, source: source);

void main() {
  group('queue launch (next in order)', () {
    test('advances to the next id', () {
      final nav = _nav([1, 2, 3], RecordingLaunchSource.queue);
      expect(nav.nextAfter(1), 2);
      expect(nav.nextAfter(2), 3);
    });

    test('returns null at the end of the list', () {
      final nav = _nav([1, 2, 3], RecordingLaunchSource.queue);
      expect(nav.nextAfter(3), isNull);
    });
  });

  group('library launch (preceding row)', () {
    test('advances to the preceding id', () {
      final nav = _nav([1, 2, 3], RecordingLaunchSource.library);
      expect(nav.nextAfter(3), 2);
      expect(nav.nextAfter(2), 1);
    });

    test('returns null at the top of the list', () {
      final nav = _nav([1, 2, 3], RecordingLaunchSource.library);
      expect(nav.nextAfter(1), isNull);
    });
  });

  test('returns null when the id is not in the peer list', () {
    final nav = _nav([1, 2, 3], RecordingLaunchSource.queue);
    expect(nav.nextAfter(99), isNull);
  });

  test('empty peer list never advances', () {
    final queue = _nav(<int>[], RecordingLaunchSource.queue);
    final library = _nav(<int>[], RecordingLaunchSource.library);
    expect(queue.nextAfter(1), isNull);
    expect(library.nextAfter(1), isNull);
  });
}
