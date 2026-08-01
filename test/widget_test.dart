import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herdsim/main.dart';

void main() {
  testWidgets('HerdSim App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: HerdSimApp(),
      ),
    );

    // Verify that our main navigation shell loads
    expect(find.byType(MainNavigationShell), findsOneWidget);
  });
}
