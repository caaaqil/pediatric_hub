// Smoke test: the app boots into the splash screen while the persisted session
// is restored, before the router redirects to /login or to a role portal.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediatric_health_hub_mobile/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PediatricHealthHubApp()),
    );
    await tester.pump();

    expect(find.text('Pediatric Health Hub'), findsOneWidget);
  });
}
