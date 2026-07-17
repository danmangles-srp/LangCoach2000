// Rivendell — application entrypoint.
//
// Wires the root ProviderScope + the App widget. Kept thin: real bootstrap
// (encrypted Drift store, queue worker) lands in T0.2/T0.3 behind app/ seams.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/app/app.dart';

void main() {
  runApp(const ProviderScope(child: RivendellApp()));
}
