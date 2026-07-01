// Rivendell — app home shell (T2.5). A three-destination bottom nav: the Today
// tab is the review queue (the app's primary surface — M2 story 3), the
// Library tab is the full recordings list (T1.4), the Tasks tab is the
// exercises/to-do surface (T5.2). All stay built in an IndexedStack so
// switching is instant and transport/scroll state survives.

import 'package:flutter/material.dart';

import 'package:rivendell/features/audio/presentation/recordings_screen.dart';
import 'package:rivendell/features/gpa/presentation/today_queue_screen.dart';
import 'package:rivendell/features/tasks/presentation/tasks_screen.dart';
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
        children: const [TodayQueueScreen(), RecordingsScreen(), TasksScreen()],
      ),
      // T8.4: lift the nav bar above Android's system navigation buttons. The
      // nav bar consumes the bottom inset; the Scaffold already keeps the body
      // (the IndexedStack) above this region.
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
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
            NavigationDestination(
              icon: const Icon(Icons.checklist_rounded),
              selectedIcon: const Icon(Icons.checklist_rounded),
              label: strings.tasksTitle,
            ),
          ],
        ),
      ),
    );
  }
}
