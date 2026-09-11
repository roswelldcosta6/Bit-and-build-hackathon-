import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge/main.dart';

void main() {
  testWidgets('shows the SignBridge launch screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SignBridgeApp()));
    await tester.pump();
    expect(find.text('SignBridge'), findsOneWidget);
  });
}
