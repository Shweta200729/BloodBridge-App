import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import 'firestore_service.dart';

// ─── Background handler (must be top-level) ───────────────────────────────────

/// Handles FCM messages when app is terminated or in background.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this fires on Android.
  if (kDebugMode) {
    print('[FCM] Background message: ${message.notification?.title}');
  }
}

// ─── Android notification channel ────────────────────────────────────────────

const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
  'blood_bridge_emergency', // id
  'Emergency Blood Requests', // name
  description: 'Urgent blood donation request notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// ─── Local notifications plugin instance ─────────────────────────────────────

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ─── Service ─────────────────────────────────────────────────────────────────

class MessagingService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  MessagingService(this._messaging, this._db);

  // Called once from main() after Firebase is initialised.
  Future<void> initNotifications({
    /// Called when the user taps a notification. Provides the [requestId]
    /// embedded in the notification payload so the router can navigate to it.
    void Function(String requestId)? onNotificationTap,
  }) async {
    // 1️⃣  Request permission (iOS / macOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('[FCM] Permission: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied — nothing to set up.
    }

    // 2️⃣  Configure local notifications plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested above via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (response) {
        // User tapped a local (foreground) notification
        final payload = response.payload;
        if (payload != null && onNotificationTap != null) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final requestId = data['requestId'] as String?;
            if (requestId != null && requestId.isNotEmpty) {
              onNotificationTap(requestId);
            }
          } catch (_) {}
        }
      },
    );

    // 3️⃣  Create the high-importance Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_emergencyChannel);

    // 4️⃣  Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Foreground message: ${message.notification?.title}');
      }
      _showLocalNotification(message);
    });

    // 5️⃣  Background tap handler — app was in background, user tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Notification tapped from background');
      }
      final requestId = message.data['requestId'] as String?;
      if (requestId != null && requestId.isNotEmpty && onNotificationTap != null) {
        onNotificationTap(requestId);
      }
    });

    // 6️⃣  Terminated-state tap — app was closed, user tapped notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final requestId = initialMessage.data['requestId'] as String?;
      if (requestId != null && requestId.isNotEmpty && onNotificationTap != null) {
        // Slight delay so the router has time to initialise
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap(requestId);
        });
      }
    }
  }

  // ── Token management ────────────────────────────────────────────────────────

  /// Fetches the current FCM token and saves it to the user's Firestore doc.
  Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _db
          .collection(FirebaseCollections.users)
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      if (kDebugMode) print('[FCM] Token saved for user $uid');

      // Also listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await _db
            .collection(FirebaseCollections.users)
            .doc(uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
        if (kDebugMode) print('[FCM] Token refreshed for user $uid');
      });
    } catch (e) {
      if (kDebugMode) print('[FCM] Failed to save token: $e');
    }
  }

  /// Removes the FCM token from Firestore (call on sign-out).
  Future<void> removeTokenForUser(String uid) async {
    try {
      await _db
          .collection(FirebaseCollections.users)
          .doc(uid)
          .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
      if (kDebugMode) print('[FCM] Token removed for user $uid');
    } catch (e) {
      if (kDebugMode) print('[FCM] Failed to remove token: $e');
    }
  }

  /// Returns the raw FCM token (for debugging / manual use).
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) print('[FCM] getToken error: $e');
      return null;
    }
  }

  // ── Notification fan-out (client-side) ──────────────────────────────────────

  /// Writes a notification document into each matching donor's
  /// `notifications` sub-collection in Firestore.
  ///
  /// Because we have no Cloud Functions, the *sender's* Flutter client performs
  /// this fan-out. Donors who have the app open will see it as an in-app alert
  /// via [listenForMyNotifications]. For background/terminated delivery the
  /// user needs a Cloud Function — this is the best-effort client-side fallback.
  Future<void> notifyDonorsAboutRequest({
    required String requestId,
    required String bloodGroup,
    required String city,
    required String hospitalName,
  }) async {
    try {
      // Query donors available and matching blood group
      final query = await _db
          .collection(FirebaseCollections.users)
          .where('isDonorAvailable', isEqualTo: true)
          .where('bloodGroup', isEqualTo: bloodGroup)
          .get();

      if (query.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in query.docs) {
        final notifRef = _db
            .collection(FirebaseCollections.users)
            .doc(doc.id)
            .collection(FirebaseCollections.notifications)
            .doc(); // auto-ID
        batch.set(notifRef, {
          'type': 'emergency_request',
          'requestId': requestId,
          'bloodGroup': bloodGroup,
          'city': city,
          'hospitalName': hospitalName,
          'title': '🚨 Urgent: $bloodGroup Blood Needed',
          'body': '$city • $hospitalName',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (kDebugMode) {
        print('[FCM] Notified ${query.docs.length} donors about request $requestId');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Fan-out error: $e');
    }
  }

  /// Writes a notification to the requester informing them a donor responded.
  Future<void> notifyRequesterOfResponse({
    required String requesterUid,
    required String requestId,
    required String donorName,
    required String donorBloodGroup,
  }) async {
    try {
      final notifRef = _db
          .collection(FirebaseCollections.users)
          .doc(requesterUid)
          .collection(FirebaseCollections.notifications)
          .doc();
      await notifRef.set({
        'type': 'donor_response',
        'requestId': requestId,
        'donorName': donorName,
        'donorBloodGroup': donorBloodGroup,
        'title': '✅ Donor Found!',
        'body': '$donorName ($donorBloodGroup) has offered to help',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('[FCM] Notified requester $requesterUid of donor response');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Requester notification error: $e');
    }
  }

  // ── Listen to in-app notifications ──────────────────────────────────────────

  /// Streams unread notification documents from the current user's subcollection.
  /// Sorts in-memory so no Firestore composite index is required.
  Stream<List<Map<String, dynamic>>> listenForMyNotifications(String uid) {
    return _db
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection(FirebaseCollections.notifications)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      list.sort((a, b) {
        final aRaw = a['createdAt'];
        final bRaw = b['createdAt'];
        final aTime = aRaw is Timestamp ? aRaw.toDate() : DateTime(0);
        final bTime = bRaw is Timestamp ? bRaw.toDate() : DateTime(0);
        return bTime.compareTo(aTime); // newest first
      });
      return list.take(20).toList();
    });
  }

  /// Marks a specific notification as read.
  Future<void> markNotificationRead(String uid, String notifId) async {
    await _db
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection(FirebaseCollections.notifications)
        .doc(notifId)
        .update({'isRead': true});
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _emergencyChannel.id,
          _emergencyChannel.name,
          channelDescription: _emergencyChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final messagingServiceProvider = Provider<MessagingService>((ref) {
  final messaging = ref.watch(messagingProvider);
  final db = ref.watch(firestoreProvider);
  return MessagingService(messaging, db);
});

/// Unread notifications for the current user.
final myNotificationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, uid) {
    final service = ref.watch(messagingServiceProvider);
    return service.listenForMyNotifications(uid);
  },
);
