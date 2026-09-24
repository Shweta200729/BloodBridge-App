import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/firebase_collections.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth;
  final FirestoreService _firestore;
  final MessagingService _messaging;

  AuthService(this._auth, this._firestore, this._messaging);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String bloodGroup,
    String city = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update Firebase Auth profile
        await user.updateDisplayName(fullName.trim());

        // Create user document in Firestore without storing password
        final userModel = UserModel(
          uid: user.uid,
          fullName: fullName.trim(),
          email: email.trim().toLowerCase(),
          phone: phone.trim(),
          bloodGroup: bloodGroup,
          city: city.trim(),
          isDonorAvailable: false,
          isVerified: false,
          createdAt: DateTime.now(),
          donationsCount: 0,
          livesSaved: 0,
        );

        await _firestore.setData(
          path: '${FirebaseCollections.users}/${user.uid}',
          data: userModel.toMap(),
        );
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != user.uid) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'You can only update your own profile.',
      );
    }

    await _firestore.setData(
      path: '${FirebaseCollections.users}/${user.uid}',
      data: user.toMap(),
    );
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String bloodGroup,
    required bool isDonorAvailable,
    String? city,
  }) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'You can only update your own profile.',
      );
    }

    final Map<String, dynamic> updateData = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'bloodGroup': bloodGroup,
      'isDonorAvailable': isDonorAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (city != null) {
      updateData['city'] = city.trim();
    }

    // Only update specified fields; strictly protect isVerified, uid, createdAt
    await _firestore.setData(
      path: '${FirebaseCollections.users}/$uid',
      data: updateData,
      merge: true,
    );

    if (fullName.trim().isNotEmpty && current.displayName != fullName.trim()) {
      await current.updateDisplayName(fullName.trim());
    }
  }

  Future<void> updateDonorAvailability({
    required String uid,
    required bool isAvailable,
  }) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'You can only update your own donor availability.',
      );
    }

    await _firestore.setData(
      path: '${FirebaseCollections.users}/$uid',
      data: {
        'isDonorAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final docSnapshot = await _firestore.doc('${FirebaseCollections.users}/$uid').get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return UserModel.fromFirestore(docSnapshot);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Best-effort: remove FCM token so signed-out device stops receiving pushes
      await _messaging.removeTokenForUser(uid);
    }
    await _auth.signOut();
  }

  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email address.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Console.';
        case 'weak-password':
          return 'The password provided is too weak. Please choose a stronger password.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No user found for that email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'too-many-requests':
          return 'Too many unsuccessful attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'permission-denied':
          return error.message ?? 'Permission denied.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  final messaging = ref.watch(messagingServiceProvider);
  return AuthService(auth, firestore, messaging);
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirebaseCollections.users)
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromFirestore(snapshot);
  });
});

final availableDonorsStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirebaseCollections.users)
      .where('isDonorAvailable', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  });
});
