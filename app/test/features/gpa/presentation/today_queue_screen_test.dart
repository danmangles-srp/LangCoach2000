// TodayQueueScreen widget test (T2.5). Presentation is coverage-excluded, so
// this guards wiring + l10n + the empty branch rather than chasing coverage.
// The populated list + one-tap play are exercised on-device (see PR "How to
// verify"); the AsyncValue→widget mapping mirrors RecordingsScreen (T1.4).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/gpa/presentation/today_queue_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

// Notifier that never touches the platform service — returns idle so the queue
// tiles render without a real audio engine.
class _IdleAudio extends AudioPlayerController {
  @override
  PlaybackSnapshot build() => const PlaybackSnapshot.idle();
}

void main() {
  testWidgets('empty queue shows the localized empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayQueueProvider.overrideWith((ref) async => const <QueueItem>[]),
          audioPlayerControllerProvider.overrideWith(_IdleAudio.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TodayQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Review Queue"), findsOneWidget);
    expect(find.text('Nothing due today'), findsOneWidget);
  });

  testWidgets('error state offers retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayQueueProvider.overrideWith(
            (ref) async => throw StateError('boom'),
          ),
          audioPlayerControllerProvider.overrideWith(_IdleAudio.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: TodayQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load recordings"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
