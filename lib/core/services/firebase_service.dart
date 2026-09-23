import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      if (kDebugMode) {
        print('BloodBridge Firebase Core initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BloodBridge Firebase initialization warning: $e');
      }
      // Keep app resilient if Firebase options aren't configured with real credentials yet
      _isInitialized = false;
    }
  }
}

final firebaseInitializerProvider = FutureProvider<bool>((ref) async {
  await FirebaseService.initialize();
  return FirebaseService.isInitialized;
});
