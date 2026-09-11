import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge/main.dart';

void main() {
  testWidgets('SignBridge app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SignBridgeApp()),
    );

    // Verify home screen renders
    expect(find.text('🤟 SignBridge'), findsOneWidget);
    expect(find.text('Sign → Speak'), findsOneWidget);
    expect(find.text('Speak → Sign'), findsOneWidget);
  });
}
