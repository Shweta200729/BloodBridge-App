import 'package:blood_bridge/core/models/user_model.dart';
import 'package:blood_bridge/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Tests', () {
    test('Default values are set correctly', () {
      const user = UserModel(
        uid: 'user123',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
        bloodGroup: 'O+',
      );

      expect(user.uid, 'user123');
      expect(user.fullName, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(user.phone, '+1234567890');
      expect(user.bloodGroup, 'O+');
      expect(user.city, '');
      expect(user.isDonorAvailable, false);
      expect(user.isVerified, false);
      expect(user.donationsCount, 0);
      expect(user.livesSaved, 0);
    });

    test('toMap does not contain sensitive password field', () {
      final now = DateTime(2026, 1, 1);
      final user = UserModel(
        uid: 'user123',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
        bloodGroup: 'A-',
        city: 'Boston',
        isDonorAvailable: true,
        isVerified: false,
        createdAt: now,
        donationsCount: 3,
        livesSaved: 9,
      );

      final map = user.toMap();
      expect(map.containsKey('password'), isFalse);
      expect(map['uid'], 'user123');
      expect(map['fullName'], 'Jane Doe');
      expect(map['email'], 'jane@example.com');
      expect(map['phone'], '+1234567890');
      expect(map['bloodGroup'], 'A-');
      expect(map['city'], 'Boston');
      expect(map['isDonorAvailable'], true);
      expect(map['isVerified'], false);
      expect(map['donationsCount'], 3);
      expect(map['livesSaved'], 9);
    });

    test('fromMap accurately parses Map into UserModel', () {
      final map = {
        'fullName': 'Marcus Vance',
        'email': 'marcus@example.com',
        'phone': '+1987654321',
        'bloodGroup': 'B+',
        'city': 'Chicago',
        'isDonorAvailable': true,
        'isVerified': true,
        'donationsCount': 5,
        'livesSaved': 15,
      };

      final user = UserModel.fromMap(map, uid: 'marcus_uid');
      expect(user.uid, 'marcus_uid');
      expect(user.fullName, 'Marcus Vance');
      expect(user.email, 'marcus@example.com');
      expect(user.phone, '+1987654321');
      expect(user.bloodGroup, 'B+');
      expect(user.city, 'Chicago');
      expect(user.isDonorAvailable, true);
      expect(user.isVerified, true);
      expect(user.donationsCount, 5);
      expect(user.livesSaved, 15);
    });

    test('copyWith produces updated copy without modifying original', () {
      const original = UserModel(
        uid: 'user123',
        fullName: 'Original Name',
        email: 'orig@example.com',
        phone: '+1234567890',
        bloodGroup: 'AB+',
        isDonorAvailable: false,
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        isDonorAvailable: true,
        city: 'Seattle',
      );

      expect(original.fullName, 'Original Name');
      expect(original.isDonorAvailable, false);
      expect(original.city, '');

      expect(updated.fullName, 'Updated Name');
      expect(updated.isDonorAvailable, true);
      expect(updated.city, 'Seattle');
      expect(updated.bloodGroup, 'AB+');
    });
  });

  group('AuthService error message helper tests', () {
    test('maps common error codes to human-readable strings', () {
      final emailInUse = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        AuthService.getReadableErrorMessage(emailInUse),
        'An account already exists for this email address.',
      );

      final weakPass = FirebaseAuthException(code: 'weak-password');
      expect(
        AuthService.getReadableErrorMessage(weakPass),
        'The password provided is too weak. Please choose a stronger password.',
      );

      final networkFailed = FirebaseAuthException(code: 'network-request-failed');
      expect(
        AuthService.getReadableErrorMessage(networkFailed),
        'Network error. Please check your internet connection.',
      );

      final permissionDenied = FirebaseAuthException(code: 'permission-denied');
      expect(
        AuthService.getReadableErrorMessage(permissionDenied),
        'Permission denied.',
      );
    });
  });
}
