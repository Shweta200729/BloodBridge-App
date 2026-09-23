import 'package:blood_bridge/app.dart';
import 'package:blood_bridge/core/services/storage_preference_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BloodBridge splash screen renders successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const BloodBridgeApp(),
      ),
    );

    // Initial frame renders BloodBridge App title & tagline
    expect(find.text('BloodBridge'), findsOneWidget);
    expect(find.text('Blood can save a life. Connect. Donate. Save.'), findsOneWidget);

    // Advance 4 seconds to allow all splash timers & navigation delay to resolve
    await tester.pump(const Duration(seconds: 4));
  });
}
