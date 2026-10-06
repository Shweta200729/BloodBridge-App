import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/firebase_collections.dart';
import '../models/donor_response_model.dart';
import '../models/emergency_request_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

// ─── Collection path helpers ─────────────────────────────────────────────────

String _responsesPath(String requestId) =>
    '${FirebaseCollections.emergencyRequests}/$requestId/responses';

// ─── Service ─────────────────────────────────────────────────────────────────

class EmergencyRequestService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final MessagingService _messaging;

  EmergencyRequestService(this._db, this._auth, this._messaging);

  User? get _currentUser => _auth.currentUser;

  void _requireAuth() {
    if (_currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'You must be signed in to perform this action.',
      );
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates a new emergency request in Firestore.
  /// Returns the newly created document ID.
  Future<String> createRequest({
    required String bloodGroup,
    required int units,
    required String hospitalName,
    required String city,
    UrgencyLevel urgency = UrgencyLevel.urgent,
    String? contactPhone,
    String? patientCaseId,
  }) async {
    _requireAuth();

    final model = EmergencyRequestModel(
      id: '',
      requesterUid: _currentUser!.uid,
      bloodGroup: bloodGroup,
      units: units,
      hospitalName: hospitalName,
      city: city,
      urgency: urgency,
      status: RequestStatus.open,
      contactPhone: contactPhone,
      patientCaseId: patientCaseId,
    );

    final validationError = model.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final docRef = await _db
        .collection(FirebaseCollections.emergencyRequests)
        .add(model.toMap());

    // Notify available donors with matching blood group (client-side fan-out)
    await _messaging.notifyDonorsAboutRequest(
      requestId: docRef.id,
      bloodGroup: bloodGroup,
      city: city,
      hospitalName: hospitalName,
    );

    return docRef.id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Stream of all open requests, ordered by creation time (newest first).
  Stream<List<EmergencyRequestModel>> openRequestsStream({
    String? bloodGroupFilter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseCollections.emergencyRequests)
        .where('status', isEqualTo: RequestStatus.open.name);

    if (bloodGroupFilter != null && bloodGroupFilter.isNotEmpty) {
      query = query.where('bloodGroup', isEqualTo: bloodGroupFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(EmergencyRequestModel.fromFirestore)
          // Hide from donors if fulfilled or if a donor is already selected
          .where((req) {
            if (!req.status.isActive) return false;
            if (req.selectedDonorUid != null && req.selectedDonorUid!.isNotEmpty) {
              return false;
            }
            return true;
          })
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime); // Newest first
      });
      return list;
    }).handleError((_) => <EmergencyRequestModel>[]);
  }

  /// Stream of requests where the current logged-in donor has been selected/accepted by the hospital.
  /// Remains visible to the accepted donor even if the request is marked fulfilled or open.
  Stream<List<EmergencyRequestModel>> myAcceptedRequestsStream() {
    if (_currentUser == null) return Stream.value([]);
    return _db
        .collection(FirebaseCollections.emergencyRequests)
        .where('selectedDonorUid', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(EmergencyRequestModel.fromFirestore)
          .where((r) => r.status != RequestStatus.cancelled && r.status != RequestStatus.closed)
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime); // Newest first
      });
      return list;
    }).handleError((_) => <EmergencyRequestModel>[]);
  }

  /// Stream of all requests created by the current user.
  Stream<List<EmergencyRequestModel>> myRequestsStream() {
    if (_currentUser == null) return Stream.value([]);
    return _db
        .collection(FirebaseCollections.emergencyRequests)
        .where('requesterUid', isEqualTo: _currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(EmergencyRequestModel.fromFirestore)
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime); // Newest first
      });
      return list;
    }).handleError((_) => <EmergencyRequestModel>[]);
  }

  /// Stream of a single request by ID.
  Stream<EmergencyRequestModel?> requestStream(String requestId) {
    if (requestId.isEmpty) return Stream.value(null);
    return _db
        .collection(FirebaseCollections.emergencyRequests)
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return EmergencyRequestModel.fromFirestore(snapshot);
    }).handleError((_) {
      return null;
    });
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Cancels a request. Only the requester can cancel their own open request.
  Future<void> cancelRequest(String requestId) async {
    _requireAuth();

    await _db.runTransaction((tx) async {
      final docRef = _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId);
      final snapshot = await tx.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Request not found.');
      }

      final request = EmergencyRequestModel.fromFirestore(snapshot);

      if (request.requesterUid != _currentUser!.uid) {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'You can only cancel your own requests.',
        );
      }

      if (!request.status.isActive) {
        throw StateError(
            'Only open requests can be cancelled. This request is ${request.status.label}.');
      }

      tx.update(docRef, {
        'status': RequestStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Marks a request as fulfilled. Only the requester can do this.
  Future<void> markFulfilled(String requestId) async {
    _requireAuth();

    String? selectedDonorUid;
    String? hospitalName;
    String? bloodGroup;

    await _db.runTransaction((tx) async {
      final docRef = _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId);
      final snapshot = await tx.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Request not found.');
      }

      final request = EmergencyRequestModel.fromFirestore(snapshot);

      if (request.requesterUid != _currentUser!.uid) {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'You can only mark your own requests as fulfilled.',
        );
      }

      if (!request.status.isActive) {
        throw StateError(
            'Only open requests can be marked fulfilled. This request is ${request.status.label}.');
      }

      selectedDonorUid = request.selectedDonorUid;
      hospitalName = request.hospitalName;
      bloodGroup = request.bloodGroup;

      tx.update(docRef, {
        'status': RequestStatus.fulfilled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Credit the selected donor's profile
      if (selectedDonorUid != null && selectedDonorUid!.isNotEmpty) {
        final donorUserRef = _db
            .collection(FirebaseCollections.users)
            .doc(selectedDonorUid);
        tx.update(donorUserRef, {
          'donationsCount': FieldValue.increment(1),
          'livesSaved': FieldValue.increment(1),
        });
      }
    });

    // Notify the accepted donor that the donation was successfully fulfilled
    if (selectedDonorUid != null && selectedDonorUid!.isNotEmpty) {
      try {
        final notifRef = _db
            .collection(FirebaseCollections.users)
            .doc(selectedDonorUid!)
            .collection(FirebaseCollections.notifications)
            .doc();
        await notifRef.set({
          'type': 'donation_fulfilled',
          'requestId': requestId,
          'hospitalName': hospitalName ?? 'The hospital',
          'bloodGroup': bloodGroup ?? '',
          'title': '❤️ Donation Fulfilled!',
          'body': 'Your blood donation for $hospitalName has been marked fulfilled. Thank you for saving a life!',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  // ── Donor Responses ───────────────────────────────────────────────────────

  /// Adds a donor response to a request.
  /// Uses a deterministic doc ID to prevent duplicate responses from the same donor.
  /// NOTE: This represents willingness to coordinate only — not medical eligibility.
  Future<void> respondToRequest({
    required String requestId,
    required String donorName,
    required String donorBloodGroup,
  }) async {
    _requireAuth();

    final donorUid = _currentUser!.uid;
    final docId = DonorResponseModel.buildId(
      requestId: requestId,
      donorUid: donorUid,
    );

    await _db.runTransaction((tx) async {
      // Verify request is still open
      final requestRef = _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId);
      final requestSnapshot = await tx.get(requestRef);

      if (!requestSnapshot.exists || requestSnapshot.data() == null) {
        throw Exception('Request not found.');
      }

      final request = EmergencyRequestModel.fromFirestore(requestSnapshot);
      if (!request.status.isActive) {
        throw StateError(
            'This request is no longer open (${request.status.label}).');
      }

      // Check for existing response
      final responseRef =
          _db.collection(_responsesPath(requestId)).doc(docId);
      final responseSnapshot = await tx.get(responseRef);

      if (responseSnapshot.exists && responseSnapshot.data() != null) {
        final existing = DonorResponseModel.fromFirestore(responseSnapshot);
        if (existing.status == DonorResponseStatus.active) {
          throw StateError('You have already responded to this request.');
        }
        // Re-activate a previously withdrawn response
        tx.update(responseRef, {
          'status': DonorResponseStatus.active.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final response = DonorResponseModel(
        id: docId,
        requestId: requestId,
        donorUid: donorUid,
        donorName: donorName,
        donorBloodGroup: donorBloodGroup,
      );

      tx.set(responseRef, response.toMap());
    });

    // Notify the requester that a donor has responded (outside transaction)
    try {
      final requestSnap = await _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId)
          .get();
      if (requestSnap.exists && requestSnap.data() != null) {
        final requesterUid =
            requestSnap.data()!['requesterUid'] as String? ?? '';
        if (requesterUid.isNotEmpty) {
          await _messaging.notifyRequesterOfResponse(
            requesterUid: requesterUid,
            requestId: requestId,
            donorName: donorName,
            donorBloodGroup: donorBloodGroup,
          );
        }
      }
    } catch (_) {
      // Non-fatal — don't block the response flow
    }
  }

  /// Withdraws a donor's own response. Only the donor who responded can withdraw.
  Future<void> withdrawResponse({
    required String requestId,
  }) async {
    _requireAuth();

    final donorUid = _currentUser!.uid;
    final docId = DonorResponseModel.buildId(
      requestId: requestId,
      donorUid: donorUid,
    );

    await _db.runTransaction((tx) async {
      final responseRef =
          _db.collection(_responsesPath(requestId)).doc(docId);
      final snapshot = await tx.get(responseRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('No response found to withdraw.');
      }

      final response = DonorResponseModel.fromFirestore(snapshot);

      if (response.donorUid != donorUid) {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'You can only withdraw your own response.',
        );
      }

      if (response.status == DonorResponseStatus.withdrawn) {
        throw StateError('This response has already been withdrawn.');
      }

      tx.update(responseRef, response.toWithdrawMap());
    });
  }

  /// Stream of active donor responses for a specific request.
  /// Only returns non-withdrawn responses, with any selected donor listed first.
  Stream<List<DonorResponseModel>> responsesStream(String requestId) {
    if (requestId.isEmpty) return Stream.value([]);
    return _db
        .collection(_responsesPath(requestId))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(DonorResponseModel.fromFirestore)
          .where((r) => r.status != DonorResponseStatus.withdrawn)
          .toList();
      list.sort((a, b) {
        if (a.status == DonorResponseStatus.selected &&
            b.status != DonorResponseStatus.selected) {
          return -1;
        }
        if (b.status == DonorResponseStatus.selected &&
            a.status != DonorResponseStatus.selected) {
          return 1;
        }
        final aTime = a.respondedAt ?? DateTime(0);
        final bTime = b.respondedAt ?? DateTime(0);
        return aTime.compareTo(bTime); // Oldest first
      });
      return list;
    }).handleError((_) {
      return <DonorResponseModel>[];
    });
  }

  /// Allows the hospital (requester) to select a donor from the response queue.
  Future<void> selectDonor({
    required String requestId,
    required String donorUid,
    required String donorName,
  }) async {
    _requireAuth();

    await _db.runTransaction((tx) async {
      final requestRef = _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId);
      final requestSnapshot = await tx.get(requestRef);

      if (!requestSnapshot.exists || requestSnapshot.data() == null) {
        throw Exception('Emergency request not found.');
      }

      final request = EmergencyRequestModel.fromFirestore(requestSnapshot);

      if (request.requesterUid != _currentUser!.uid) {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'Only the hospital that created this request can select donors.',
        );
      }

      final responseDocId = DonorResponseModel.buildId(
        requestId: requestId,
        donorUid: donorUid,
      );
      final responseRef =
          _db.collection(_responsesPath(requestId)).doc(responseDocId);
      final responseSnapshot = await tx.get(responseRef);

      if (!responseSnapshot.exists || responseSnapshot.data() == null) {
        throw Exception('Donor response not found in queue.');
      }

      // Update emergency request with selected donor info
      tx.update(requestRef, {
        'selectedDonorUid': donorUid,
        'selectedDonorName': donorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update donor response document status to selected
      tx.update(responseRef, {
        'status': DonorResponseStatus.selected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Notify the donor of selection
    try {
      final requestSnap = await _db
          .collection(FirebaseCollections.emergencyRequests)
          .doc(requestId)
          .get();
      if (requestSnap.exists && requestSnap.data() != null) {
        final data = requestSnap.data()!;
        final hospitalName =
            data['hospitalName'] as String? ?? 'The hospital';
        final bloodGroup = data['bloodGroup'] as String? ?? '';
        final contactPhone = data['contactPhone'] as String? ?? '';
        final city = data['city'] as String? ?? '';

        await _messaging.notifyDonorSelected(
          donorUid: donorUid,
          requestId: requestId,
          hospitalName: hospitalName,
          bloodGroup: bloodGroup,
          hospitalPhone: contactPhone,
          city: city,
        );
      }
    } catch (_) {
      // Non-fatal notification error
    }
  }

  /// Checks if the current user has an active or selected response for a given request.
  Future<DonorResponseModel?> getMyResponse(String requestId) async {
    _requireAuth();
    final docId = DonorResponseModel.buildId(
      requestId: requestId,
      donorUid: _currentUser!.uid,
    );
    final snapshot = await _db
        .collection(_responsesPath(requestId))
        .doc(docId)
        .get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return DonorResponseModel.fromFirestore(snapshot);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final emergencyRequestServiceProvider =
    Provider<EmergencyRequestService>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final messaging = ref.watch(messagingServiceProvider);
  return EmergencyRequestService(db, auth, messaging);
});

/// In-memory holder for the currently selected request (ensures instant 0ms load on detail screen)
final selectedEmergencyRequestProvider =
    StateProvider<EmergencyRequestModel?>((ref) => null);

/// Stream of open emergency requests (optionally filtered by blood group).
final openRequestsProvider =
    StreamProvider.family<List<EmergencyRequestModel>, String?>(
  (ref, bloodGroupFilter) {
    final service = ref.watch(emergencyRequestServiceProvider);
    return service.openRequestsStream(bloodGroupFilter: bloodGroupFilter);
  },
);

/// Stream of the current user's own requests.
final myRequestsProvider =
    StreamProvider<List<EmergencyRequestModel>>((ref) {
  final service = ref.watch(emergencyRequestServiceProvider);
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return service.myRequestsStream();
});

/// Stream of requests where the current logged-in donor has been accepted/selected by the hospital.
final myAcceptedRequestsProvider =
    StreamProvider<List<EmergencyRequestModel>>((ref) {
  final service = ref.watch(emergencyRequestServiceProvider);
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return service.myAcceptedRequestsStream();
});

/// Stream of a single request by ID.
final requestDetailProvider =
    StreamProvider.family<EmergencyRequestModel?, String>((ref, requestId) {
  final service = ref.watch(emergencyRequestServiceProvider);
  return service.requestStream(requestId);
});

/// Stream of active donor responses for a given request ID.
final requestResponsesProvider =
    StreamProvider.family<List<DonorResponseModel>, String>(
  (ref, requestId) {
    final service = ref.watch(emergencyRequestServiceProvider);
    return service.responsesStream(requestId);
  },
);
