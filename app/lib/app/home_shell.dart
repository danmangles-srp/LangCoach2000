// Rivendell — app home shell (T2.5). A five-destination bottom nav: the Today
// tab is the review queue (the app's primary surface — M2 story 3), the
// Library tab is the full recordings list (T1.4), the Tasks tab is the
// exercises/to-do surface (T5.2), the Coach tab is the Coach Bank (T5.5), the
// Stats tab is the analytics dashboard (T6.3). All stay built in an
// IndexedStack so switching is instant and transport/scroll state survives.

import 'package:flutter/material.dart';

import 'package:rivendell/features/audio/presentation/recordings_screen.dart';
import 'package:rivendell/features/coach/presentation/coach_bank_screen.dart';
import 'package:rivendell/features/gpa/presentation/today_queue_screen.dart';
import 'package:rivendell/features/metrics/presentation/stats_screen.dart';
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
        children: const [
          TodayQueueScreen(),
          RecordingsScreen(),
          TasksScreen(),
          StatsScreen(),
          CoachBankScreen(),
        ],
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
            NavigationDestination(
              icon: const Icon(Icons.insights_rounded),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: strings.statsTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_rounded),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: strings.coachTitle,
            ),
          ],
        ),
      ),
    );
  }
}
