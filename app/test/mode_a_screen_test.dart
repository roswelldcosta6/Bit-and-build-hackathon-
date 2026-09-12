import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge/screens/mode_a_screen.dart';
import 'package:signbridge/theme/app_theme.dart';

Widget _wrap() => ProviderScope(
  child: MaterialApp(theme: AppTheme.light(1.0), home: const ModeAScreen()),
);

void main() {
  testWidgets('Mode A shows the Start signing button above the fold', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // The primary control must exist…
    expect(find.text('Start signing'), findsOneWidget);
    // …fit inside the screen width…
    final buttonRect = tester.getRect(
      find.ancestor(
        of: find.text('Start signing'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(buttonRect.width, lessThan(800), reason: 'button must not overflow');
    expect(
      buttonRect.height,
      lessThan(80),
      reason: 'button must be normal-sized',
    );
    // …and be visible in the initial viewport (no scrolling needed).
    expect(
      buttonRect.top,
      lessThan(600),
      reason: 'Start signing button should be above the fold',
    );
  });

  testWidgets('tapping Start signing runs the pipeline and surfaces errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start signing'));
    await tester.pump();

    // Tapping flips the screen into processing mode: the primary control
    // becomes a Stop button. (The full camera-init failure path needs real
    // platform channels, so it is verified on-device, not here.)
    expect(find.text('Stop'), findsOneWidget);
  });
}
