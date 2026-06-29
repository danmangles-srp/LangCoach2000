// Audio indexer port (FR-1.1.2, T1.2). Abstract so [RecordingIndexer] depends
// on a pure seam and is unit-tested with a fake; the SAF MethodChannel impl
// lives in platform/. A scan returns the discovered files for a folder, or an
// empty list on failure (the impl logs; callers don't catch).

import 'package:rivendell/features/audio/data/recording_repository.dart';

abstract class AudioIndexerService {
  Future<List<ScannedFile>> scan(String folderUri);
}
