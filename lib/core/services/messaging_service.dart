import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

class MessagingService {
  final FirebaseMessaging _messaging;

  MessagingService(this._messaging);

  Future<void> initNotifications() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permissions');
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received push notification: ${message.notification?.title}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization warning: $e');
      }
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }
}

final messagingServiceProvider = Provider<MessagingService>((ref) {
  final messaging = ref.watch(messagingProvider);
  return MessagingService(messaging);
});
