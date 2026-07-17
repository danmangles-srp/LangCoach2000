// Rivendell — root widget + Material 3 theme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/app/router.dart';

class RivendellApp extends ConsumerWidget {
  const RivendellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Rivendell',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }

  // Material 3, seed-driven. Design tokens harden at the M1 design-review pass.
  ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6B),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
