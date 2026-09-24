import 'package:blood_bridge/core/models/user_model.dart';
import 'package:blood_bridge/core/services/auth_service.dart';
import 'package:blood_bridge/core/services/storage_preference_service.dart';
import 'package:blood_bridge/features/profile/presentation/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);
}

void main() {
  testWidgets('ProfileScreen renders without crashing when user is null', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
  });

  testWidgets('ProfileScreen renders with populated user data', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const testUser = UserModel(
      uid: 'test_123',
      fullName: 'Alice Smith',
      email: 'alice@example.com',
      phone: '+1 555 123 4567',
      bloodGroup: 'A+',
      city: 'Chicago',
      isDonorAvailable: true,
      isVerified: true,
      donationsCount: 4,
      livesSaved: 12,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(testUser)),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
  });
}
