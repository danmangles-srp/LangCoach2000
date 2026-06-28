// Rivendell — top-level router.
//
// go_router shell with a first-run folder gate (FR-1.1.1): while no audio
// folder is persisted, every route redirects to onboarding. The home route is
// a placeholder until T1.4 lands the recordings list. Feature routes are
// added per milestone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/presentation/folder_onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (_, state) async {
      // Block first-route resolution until the folder check resolves so the
      // onboarding gate is correct from the first frame. If the DB open fails
      // (key mismatch, corrupt store), don't brick routing — let the requested
      // route render and surface the failure downstream (full recovery is a
      // follow-up).
      bool hasFolder;
      try {
        hasFolder = await ref.read(hasFolderProvider.future);
      } on Object {
        hasFolder = false;
      }
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!hasFolder && !onOnboarding) return '/onboarding';
      if (hasFolder && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _BootstrapScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const FolderOnboardingScreen(),
      ),
    ],
  );
});

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Rivendell', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'M1 — folder ready',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
