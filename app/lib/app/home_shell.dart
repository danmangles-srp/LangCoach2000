// Rivendell — app home shell (T2.5). A two-destination bottom nav: the Today
// tab is the review queue (the app's primary surface — M2 story 3), the
// Library tab is the full recordings list (T1.4). Both stay built in an
// IndexedStack so switching is instant and transport/scroll state survives.

import 'package:flutter/material.dart';

import 'package:rivendell/features/audio/presentation/recordings_screen.dart';
import 'package:rivendell/features/gpa/presentation/today_queue_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayQueueScreen(), RecordingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.event_available_rounded),
            selectedIcon: const Icon(Icons.event_available_rounded),
            label: strings.queueNavToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_rounded),
            selectedIcon: const Icon(Icons.library_music_rounded),
            label: strings.queueNavLibrary,
          ),
        ],
      ),
    );
  }
}
