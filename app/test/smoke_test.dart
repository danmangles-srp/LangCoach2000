// Smoke test — verifies the app builds and the bootstrap widget renders.
// Replaces the generated `widget_test.dart` (which references the removed
// counter UI). Kept lightweight; feature tests live under test/features/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';

void main() {
  testWidgets('RivendellApp renders the bootstrap title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RivendellApp()));
    await tester.pumpAndSettle();

    expect(find.text('Rivendell'), findsOneWidget);
    expect(find.text('M0 bootstrap'), findsOneWidget);
  });

  testWidgets('Material 3 is enabled', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RivendellApp()));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(MaterialApp).first));
    expect(theme.useMaterial3, isTrue);
  });
}
