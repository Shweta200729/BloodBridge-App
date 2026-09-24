import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_service.dart';
import 'core/services/messaging_service.dart';
import 'core/services/storage_preference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await AppConfig.init();

  // Initialize Firebase Core services
  await FirebaseService.initialize();

  // Register the top-level FCM background handler BEFORE any other FCM calls
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const BloodBridgeApp(),
    ),
  );
}
