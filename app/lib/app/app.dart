// Rivendell — root widget + Material 3 theme.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/app/router.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class RivendellApp extends ConsumerWidget {
  const RivendellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the 80%-review watcher alive for the app's lifetime so background
    // playback still logs review events (FR-1.2.3, T2.2).
    ref.watch(reviewProgressWatcherProvider);
    return MaterialApp.router(
      title: 'Rivendell',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
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
