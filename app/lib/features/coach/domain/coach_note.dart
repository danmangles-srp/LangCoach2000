// Coach Bank read model (T15.5, FR-1.4.3). Lives in `domain/` so presentation
// + application depend on the feature's own vocabulary, not the Drift data
// layer. Wraps the generated [CoachNote] row plus the agenda link ids the
// repository joins in — the screen gets a note + its pinned recordings / vocab
// logs in one value.

import 'package:flutter/foundation.dart';

import 'package:rivendell/core/database/app_database.dart';

@immutable
class CoachNoteWithLinks {
  const CoachNoteWithLinks({
    required this.note,
    required this.recordingIds,
    required this.wordLogIds,
  });

  final CoachNote note;
  final List<int> recordingIds;
  final List<int> wordLogIds;
}
