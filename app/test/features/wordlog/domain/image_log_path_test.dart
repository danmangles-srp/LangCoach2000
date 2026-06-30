// buildImageLogPath — T3.3 (FR-1.3.1). Pure: the path format, dot handling,
// case-insensitivity, and rejection of unsupported types.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/wordlog/domain/image_log_path.dart';

void main() {
  test('builds wordlog/<id>/<stem>.<ext> for a jpg', () {
    expect(
      buildImageLogPath(
        recordingId: 7,
        stem: '1719000000000',
        extension: 'jpg',
      ),
      'wordlog/7/1719000000000.jpg',
    );
  });

  test('accepts an extension with a leading dot', () {
    expect(
      buildImageLogPath(recordingId: 3, stem: 's', extension: '.png'),
      'wordlog/3/s.png',
    );
  });

  test('lowercases an uppercase extension in the stored path', () {
    expect(
      buildImageLogPath(recordingId: 1, stem: 's', extension: 'JPEG'),
      'wordlog/1/s.jpeg',
    );
  });

  test('throws on an unsupported extension', () {
    expect(
      () => buildImageLogPath(recordingId: 1, stem: 's', extension: 'gif'),
      throwsArgumentError,
    );
    expect(
      () => buildImageLogPath(recordingId: 1, stem: 's', extension: '.heic'),
      throwsArgumentError,
    );
  });
}
