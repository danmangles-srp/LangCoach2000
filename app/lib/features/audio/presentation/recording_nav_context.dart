// Peer context handed to the recording detail route (M8, T8.1 / T8.2). Carries
// the ordered list of recording ids the user is moving through + where they
// launched from, so the detail screen can auto-advance on playback completion:
// queue launches advance to the next queue id; library launches advance to the
// preceding library row. Null (deep link, route restore) means no auto-advance.

import 'package:flutter/foundation.dart';

enum RecordingLaunchSource { queue, library }

@immutable
class RecordingNavContext {
  const RecordingNavContext({required this.peerIds, required this.source});

  /// Ordered ids the user is traversing: queue order (today then tomorrow) for
  /// a queue launch, or the library list order for a library launch.
  final List<int> peerIds;
  final RecordingLaunchSource source;

  /// Id to cue after [currentId] finishes, or null at the end of the list /
  /// when [currentId] isn't found. Queue → next id; library → preceding id.
  int? nextAfter(int currentId) {
    final index = peerIds.indexOf(currentId);
    if (index < 0) return null;
    switch (source) {
      case RecordingLaunchSource.queue:
        final next = index + 1;
        return next < peerIds.length ? peerIds[next] : null;
      case RecordingLaunchSource.library:
        final prev = index - 1;
        return prev >= 0 ? peerIds[prev] : null;
    }
  }
}
