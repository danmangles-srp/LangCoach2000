// Coverage gate for the *logic surface* of a Flutter app.
//
// Usage:
//   dart scripts/check_coverage.dart <lcov.info> [--min=80] [--exclude=<regex>,<regex>]
//
// Reads an lcov tracefile (from `flutter test --coverage`) and enforces a minimum
// line-coverage percentage over files that hold real logic. Generated code,
// localisations, entrypoints, app shells, presentation (widgets), and platform
// adapters are excluded by default — they are verified by widget/golden tests and
// on-device, not by this percentage (see .claude/skills/structure.md).
//
// Lives in scripts/ (not inside the app) so the floor survives app rebuilds and is
// shared across every app the toolkit bootstraps. Self-contained: only dart:io.
//
// Exits 0 when coverage >= min (or there is no measurable logic yet), else 1.

import 'dart:io';

const defaultMin = 80.0;

const defaultExcludes = <String>[
  r'\.g\.dart$',
  r'\.freezed\.dart$',
  r'\.gr\.dart$',
  r'\.config\.dart$',
  r'\.mocks\.dart$',
  r'/l10n/',
  r'/generated/',
  r'(^|/)main\.dart$',
  r'(^|/)bootstrap\.dart$',
  r'(^|/)firebase_options\.dart$',
  r'(^|/)app/', // app shell: router, theme, root widget
  r'/presentation/', // screens & widgets — widget/golden tested
  r'/platform/', // device/SDK adapters — coverage:ignore
];

void main(List<String> args) {
  final positional = <String>[];
  var min = defaultMin;
  final excludes = <String>[...defaultExcludes];

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      stdout.writeln(
        'usage: dart scripts/check_coverage.dart <lcov.info> [--min=80] [--exclude=re,re]',
      );
      return;
    } else if (arg.startsWith('--min=')) {
      final value = double.tryParse(arg.substring('--min='.length));
      if (value == null) {
        _fail('invalid --min value: $arg');
      }
      if (value < 0 || value > 100) {
        _fail('--min must be between 0 and 100: $arg');
      }
      min = value; // promoted non-null: _fail returns Never.
    } else if (arg.startsWith('--exclude=')) {
      excludes.addAll(
        arg
            .substring('--exclude='.length)
            .split(',')
            .where((s) => s.isNotEmpty),
      );
    } else if (arg.startsWith('--')) {
      _fail('unknown flag: $arg');
    } else {
      positional.add(arg);
    }
  }

  final lcovPath = positional.isNotEmpty
      ? positional.first
      : 'coverage/lcov.info';
  final file = File(lcovPath);
  if (!file.existsSync()) {
    _fail(
      'lcov file not found: $lcovPath  (run `flutter test --coverage` first)',
    );
  }

  final patterns = excludes.map(RegExp.new).toList();
  bool isExcluded(String path) {
    final normalised = path.replaceAll(r'\', '/');
    return patterns.any((re) => re.hasMatch(normalised));
  }

  // Honor the well-known `// coverage:ignore-file` marker: a file opt-ing out
  // of line-coverage entirely (typical for platform-plugin seams that can't be
  // exercised without a device). Lets pure logic stay at 100% while platform
  // glue is verified on-device instead of dragging the floor.
  //
  // Resolved once per SF (when its record opens) so each source file is read at
  // most once across the whole pass.
  bool optsOut(String path) {
    final src = File(path);
    if (!src.existsSync()) return false;
    return src.readAsLinesSync().any((l) => l.contains('coverage:ignore-file'));
  }

  var totalFound = 0;
  var totalHit = 0;
  final files = <_FileCov>[];

  String? current;
  var currentOptsOut = false;
  var curFound = 0;
  var curHit = 0;

  void flush() {
    final path = current;
    if (path != null &&
        !isExcluded(path) &&
        !currentOptsOut &&
        curFound > 0) {
      totalFound += curFound;
      totalHit += curHit;
      files.add(_FileCov(path, curFound, curHit));
    }
    current = null;
    currentOptsOut = false;
    curFound = 0;
    curHit = 0;
  }

  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      flush();
      final path = line.substring(3);
      current = path;
      currentOptsOut = optsOut(path);
    } else if (line.startsWith('DA:')) {
      // DA:<line>,<hits> — require a numeric line number to skip malformed records.
      final parts = line.substring(3).split(',');
      if (parts.length >= 2 && int.tryParse(parts[0]) != null) {
        curFound++;
        if ((int.tryParse(parts[1]) ?? 0) > 0) curHit++;
      }
    } else if (line == 'end_of_record') {
      flush();
    }
  }
  flush();

  if (totalFound == 0) {
    stdout.writeln('coverage: no measurable logic lines yet — gate passes.');
    return;
  }

  final pct = 100.0 * totalHit / totalFound;
  stdout.writeln(
    'coverage: ${pct.toStringAsFixed(1)}% '
    '($totalHit/$totalFound logic lines across ${files.length} files; '
    'floor ${min.toStringAsFixed(0)}%)',
  );

  if (pct < min) {
    files.sort((a, b) => a.pct.compareTo(b.pct));
    stdout.writeln('lowest-covered logic files:');
    for (final f in files.where((f) => f.pct < 100).take(10)) {
      stdout.writeln('  ${f.pct.toStringAsFixed(0).padLeft(3)}%  ${f.path}');
    }
    _fail(
      'coverage ${pct.toStringAsFixed(1)}% is below the ${min.toStringAsFixed(0)}% floor.',
    );
  }
  stdout.writeln('coverage: PASS');
}

class _FileCov {
  _FileCov(this.path, this.found, this.hit);
  final String path;
  final int found;
  final int hit;
  double get pct => found == 0 ? 100 : 100.0 * hit / found;
}

Never _fail(String message) {
  stderr.writeln('check_coverage: $message');
  exit(1);
}
