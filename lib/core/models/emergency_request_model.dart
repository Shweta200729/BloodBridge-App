import 'package:cloud_firestore/cloud_firestore.dart';

/// Valid status values for an emergency blood request.
enum RequestStatus {
  open,
  fulfilled,
  cancelled,
  closed;

  static RequestStatus fromString(String? value) {
    switch (value) {
      case 'fulfilled':
        return RequestStatus.fulfilled;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'closed':
        return RequestStatus.closed;
      case 'open':
      default:
        return RequestStatus.open;
    }
  }

  String get label {
    switch (this) {
      case RequestStatus.open:
        return 'Open';
      case RequestStatus.fulfilled:
        return 'Fulfilled';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.closed:
        return 'Closed';
    }
  }

  bool get isActive => this == RequestStatus.open;
}

/// Valid urgency levels for an emergency request.
enum UrgencyLevel {
  critical,
  urgent,
  high,
  normal;

  static UrgencyLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CRITICAL':
        return UrgencyLevel.critical;
      case 'URGENT':
        return UrgencyLevel.urgent;
      case 'HIGH':
        return UrgencyLevel.high;
      case 'NORMAL':
      default:
        return UrgencyLevel.normal;
    }
  }

  String get label {
    switch (this) {
      case UrgencyLevel.critical:
        return 'CRITICAL';
      case UrgencyLevel.urgent:
        return 'URGENT';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.normal:
        return 'NORMAL';
    }
  }
}

/// Immutable model representing a blood emergency request.
///
/// [contactPhone] is optional and only stored when explicitly provided by the
/// requester. It is NOT automatically copied from the user profile.
class EmergencyRequestModel {
  final String id;
  final String requesterUid;
  final String bloodGroup;
  final int units;
  final String hospitalName;
  final String city;
  final UrgencyLevel urgency;
  final RequestStatus status;
  final String? contactPhone;
  final String? patientCaseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyRequestModel({
    required this.id,
    required this.requesterUid,
    required this.bloodGroup,
    required this.units,
    required this.hospitalName,
    required this.city,
    this.urgency = UrgencyLevel.urgent,
    this.status = RequestStatus.open,
    this.contactPhone,
    this.patientCaseId,
    this.createdAt,
    this.updatedAt,
  });

  // ─── Validation ────────────────────────────────────────────────────────────

  static const List<String> validBloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  /// Returns a non-null error string if the model has invalid data.
  String? validate() {
    if (requesterUid.isEmpty) return 'Requester UID is required.';
    if (!validBloodGroups.contains(bloodGroup)) return 'Invalid blood group.';
    if (units < 1 || units > 20) return 'Units must be between 1 and 20.';
    if (hospitalName.trim().isEmpty) return 'Hospital name is required.';
    if (city.trim().isEmpty) return 'City is required.';
    return null;
  }

  // ─── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'requesterUid': requesterUid,
      'bloodGroup': bloodGroup,
      'units': units,
      'hospitalName': hospitalName.trim(),
      'city': city.trim(),
      'urgency': urgency.label,
      'status': status.name,
      if (contactPhone != null && contactPhone!.trim().isNotEmpty)
        'contactPhone': contactPhone!.trim(),
      if (patientCaseId != null && patientCaseId!.trim().isNotEmpty)
        'patientCaseId': patientCaseId!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory EmergencyRequestModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return EmergencyRequestModel(
      id: id,
      requesterUid: map['requesterUid'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? '',
      units: (map['units'] as num?)?.toInt() ?? 1,
      hospitalName: map['hospitalName'] as String? ?? '',
      city: map['city'] as String? ?? '',
      urgency: UrgencyLevel.fromString(map['urgency'] as String?),
      status: RequestStatus.fromString(map['status'] as String?),
      contactPhone: map['contactPhone'] as String?,
      patientCaseId: map['patientCaseId'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  factory EmergencyRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return EmergencyRequestModel.fromMap(data, id: snapshot.id);
  }

  EmergencyRequestModel copyWith({
    String? id,
    String? requesterUid,
    String? bloodGroup,
    int? units,
    String? hospitalName,
    String? city,
    UrgencyLevel? urgency,
    RequestStatus? status,
    String? contactPhone,
    String? patientCaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyRequestModel(
      id: id ?? this.id,
      requesterUid: requesterUid ?? this.requesterUid,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      units: units ?? this.units,
      hospitalName: hospitalName ?? this.hospitalName,
      city: city ?? this.city,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      contactPhone: contactPhone ?? this.contactPhone,
      patientCaseId: patientCaseId ?? this.patientCaseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
