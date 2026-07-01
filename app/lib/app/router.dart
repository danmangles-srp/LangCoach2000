// Rivendell — top-level router.
//
// go_router shell with a first-run folder gate (FR-1.1.1): while no audio
// folder is persisted, every route redirects to onboarding. The home route is
// the recordings list (T1.4). Feature routes are added per milestone.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rivendell/app/home_shell.dart';
import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/presentation/folder_onboarding_screen.dart';
import 'package:rivendell/features/audio/presentation/recording_detail_screen.dart';
import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';
import 'package:rivendell/features/audio/presentation/recordings_screen.dart';
import 'package:rivendell/features/settings/presentation/settings_screen.dart';

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
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
      GoRoute(
        // T1.6: tap a recording -> detail + player. A non-numeric id (stale
        // link) falls back to the library rather than rendering a broken
        // detail screen. The optional `extra` carries the peer-id list +
        // launch source (T8.2) so the detail can auto-advance on completion;
        // null (deep link / restore) disables auto-advance.
        path: '/recordings/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const RecordingsScreen();
          final extra = state.extra;
          final nav = extra is RecordingNavContext ? extra : null;
          return RecordingDetailScreen(recordingId: id, navContext: nav);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const FolderOnboardingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
