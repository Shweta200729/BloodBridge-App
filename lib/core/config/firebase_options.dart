import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'app_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example usage:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        return android;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey.isNotEmpty
            ? AppConfig.firebaseApiKey
            : 'AIzaSyDemoApiKeyForBloodBridgeWeb123',
        appId: AppConfig.firebaseAppId.isNotEmpty
            ? AppConfig.firebaseAppId
            : '1:123456789012:web:demo1234567890',
        messagingSenderId: AppConfig.firebaseMessagingSenderId.isNotEmpty
            ? AppConfig.firebaseMessagingSenderId
            : '123456789012',
        projectId: AppConfig.firebaseProjectId,
        authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey.isNotEmpty
            ? AppConfig.firebaseApiKey
            : 'AIzaSyDemoApiKeyForBloodBridgeAndroid123',
        appId: AppConfig.firebaseAppId.isNotEmpty
            ? AppConfig.firebaseAppId
            : '1:123456789012:android:demo1234567890',
        messagingSenderId: AppConfig.firebaseMessagingSenderId.isNotEmpty
            ? AppConfig.firebaseMessagingSenderId
            : '123456789012',
        projectId: AppConfig.firebaseProjectId,
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey.isNotEmpty
            ? AppConfig.firebaseApiKey
            : 'AIzaSyDemoApiKeyForBloodBridgeIOS123',
        appId: AppConfig.firebaseAppId.isNotEmpty
            ? AppConfig.firebaseAppId
            : '1:123456789012:ios:demo1234567890',
        messagingSenderId: AppConfig.firebaseMessagingSenderId.isNotEmpty
            ? AppConfig.firebaseMessagingSenderId
            : '123456789012',
        projectId: AppConfig.firebaseProjectId,
        storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
        iosBundleId: 'com.bloodbridge.bloodBridge',
      );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => android;
}
