// Record sheet render test (T2.7). Presentation is coverage-excluded; this
// guards the phase → affordance wiring (idle shows Record, recording shows
// Stop + the elapsed timer, error shows the mapped message) via a controller
// whose initial state is injected.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/recording/application/recorder_controller.dart';
import 'package:rivendell/features/audio/recording/domain/recording_state.dart';
import 'package:rivendell/features/audio/recording/presentation/record_sheet.dart';
import 'package:rivendell/l10n/app_strings.dart';

RecordingState _injected = const RecordingState();

class _StateController extends RecorderController {
  @override
  RecordingState build() => _injected;
}

Widget _host() {
  return ProviderScope(
    overrides: [recorderControllerProvider.overrideWith(_StateController.new)],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(body: RecordSheet()),
    ),
  );
}

void main() {
  testWidgets('idle shows the Record affordance', (tester) async {
    _injected = const RecordingState();
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fiber_manual_record_rounded), findsOneWidget);
  });

  testWidgets('recording shows Stop + the elapsed timer', (tester) async {
    _injected = const RecordingState(
      phase: RecordPhase.recording,
      elapsed: Duration(seconds: 5),
    );
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('00:05'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('permission error maps to the localized message', (tester) async {
    _injected = const RecordingState(
      phase: RecordPhase.error,
      error: 'permission',
    );
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.textContaining('Microphone permission'), findsOneWidget);
  });
}
