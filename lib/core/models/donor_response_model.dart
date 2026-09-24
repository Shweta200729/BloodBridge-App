import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a donor's response to an emergency request.
/// 'active' = donor has offered to help and has not withdrawn.
/// 'withdrawn' = donor withdrew their offer.
enum DonorResponseStatus {
  active,
  withdrawn;

  static DonorResponseStatus fromString(String? value) {
    switch (value) {
      case 'withdrawn':
        return DonorResponseStatus.withdrawn;
      case 'active':
      default:
        return DonorResponseStatus.active;
    }
  }
}

/// A donor's willingness to coordinate for a specific emergency request.
///
/// IMPORTANT: This is NOT a confirmation of medical eligibility, compatibility,
/// successful donation, or fulfillment. It only represents a donor's expressed
/// willingness to be contacted and coordinate.
///
/// Document ID is deterministic: '{requestId}_{donorUid}' to prevent duplicates
/// at the Firestore document level.
class DonorResponseModel {
  /// Format: '{requestId}_{donorUid}' — used as deterministic Firestore doc ID.
  final String id;
  final String requestId;
  final String donorUid;
  final String donorName;
  final String donorBloodGroup;
  final DonorResponseStatus status;
  final DateTime? respondedAt;
  final DateTime? updatedAt;

  const DonorResponseModel({
    required this.id,
    required this.requestId,
    required this.donorUid,
    required this.donorName,
    required this.donorBloodGroup,
    this.status = DonorResponseStatus.active,
    this.respondedAt,
    this.updatedAt,
  });

  /// Deterministic document ID prevents duplicate responses from same donor.
  static String buildId({
    required String requestId,
    required String donorUid,
  }) =>
      '${requestId}_$donorUid';

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'donorUid': donorUid,
      'donorName': donorName,
      'donorBloodGroup': donorBloodGroup,
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toWithdrawMap() {
    return {
      'status': DonorResponseStatus.withdrawn.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DonorResponseModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return DonorResponseModel(
      id: id,
      requestId: map['requestId'] as String? ?? '',
      donorUid: map['donorUid'] as String? ?? '',
      donorName: map['donorName'] as String? ?? 'Unknown Donor',
      donorBloodGroup: map['donorBloodGroup'] as String? ?? '',
      status: DonorResponseStatus.fromString(map['status'] as String?),
      respondedAt: parseTimestamp(map['respondedAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  factory DonorResponseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return DonorResponseModel.fromMap(data, id: snapshot.id);
  }

  DonorResponseModel copyWith({
    String? id,
    String? requestId,
    String? donorUid,
    String? donorName,
    String? donorBloodGroup,
    DonorResponseStatus? status,
    DateTime? respondedAt,
    DateTime? updatedAt,
  }) {
    return DonorResponseModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      donorUid: donorUid ?? this.donorUid,
      donorName: donorName ?? this.donorName,
      donorBloodGroup: donorBloodGroup ?? this.donorBloodGroup,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
