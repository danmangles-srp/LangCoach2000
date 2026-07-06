// On-disk storage path for a cached AI concept image (T4.3, FR-1.3.4). Pure.
//
// One image per Uzbek word, ever (FR-1.3.4 "generated at most once"). The
// filename is a sha1 of the word so any script — Latin, Cyrillic, with or
// without diacritics (oʻ, gʻ, ch, ng) — maps to a stable, collision-free ASCII
// filename without losing information by stripping non-ASCII. All AI images
// live under one flat `ai_images/` directory; there is no per-recording
// subdirectory because the cache is global across recordings.

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// `ai_images/<sha1(uzbekWord)>.png` — stable, script-agnostic, flat layout.
String buildAiImagePath(String uzbekWord) {
  final hex = sha1.convert(utf8.encode(uzbekWord)).toString();
  return 'ai_images/$hex.png';
}
