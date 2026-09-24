import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fallback if .env is missing or unreadable
    }
  }

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get appName => dotenv.get('APP_NAME', fallback: 'BloodBridge');
  static String get appEnv => dotenv.get('APP_ENV', fallback: 'development');
  
  static String get googleMapsApiKey =>
      dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
      
  static String get firebaseApiKey =>
      dotenv.get('FIREBASE_API_KEY', fallback: '');
      
  static String get firebaseProjectId =>
      dotenv.get('FIREBASE_PROJECT_ID', fallback: 'bloodbridge-dev');

  static String get firebaseMessagingSenderId =>
      dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');

  static String get firebaseAppId =>
      dotenv.get('FIREBASE_APP_ID', fallback: '');

  static String get firebaseAndroidAppId =>
      dotenv.get('FIREBASE_ANDROID_APP_ID', fallback: firebaseAppId);

  static bool get isDev => _environment == Environment.development;
  static bool get isProd => _environment == Environment.production;
}
