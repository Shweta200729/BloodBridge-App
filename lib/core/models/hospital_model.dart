import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Type of medical facility in the directory.
enum HospitalType {
  hospital,
  bloodBank,
  clinic;

  static HospitalType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'bloodbank':
      case 'blood_bank':
      case 'blood bank':
        return HospitalType.bloodBank;
      case 'clinic':
        return HospitalType.clinic;
      case 'hospital':
      default:
        return HospitalType.hospital;
    }
  }

  String get label {
    switch (this) {
      case HospitalType.hospital:
        return 'Hospital';
      case HospitalType.bloodBank:
        return 'Blood Bank';
      case HospitalType.clinic:
        return 'Clinic';
    }
  }
}

/// Immutable model representing a hospital or blood bank facility.
///
/// DATA INTEGRITY:
/// - Facilities that are demonstration entries are explicitly flagged with
///   [isSampleData] = true and [isVerified] = false.
/// - Coordinates ([latitude], [longitude]) are only populated if verified;
///   otherwise null.
class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final HospitalType type;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isSampleData;
  final String? operatingHours;
  final String? notes;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.type = HospitalType.hospital,
    this.phone,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isSampleData = false,
    this.operatingHours,
    this.notes,
  });

  /// True when both latitude and longitude are valid numeric coordinates.
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90.0 &&
      latitude! <= 90.0 &&
      longitude! >= -180.0 &&
      longitude! <= 180.0;

  /// True when a non-empty contact phone number is available.
  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  /// True when an address is provided.
  bool get hasAddress => address.trim().isNotEmpty;

  /// Calculates distance in kilometers from given coordinate point.
  /// Returns null if this facility has no valid coordinates.
  double? distanceTo(double userLat, double userLng) {
    if (!hasCoordinates) return null;
    return Geolocator.distanceBetween(
          userLat,
          userLng,
          latitude!,
          longitude!,
        ) /
        1000.0;
  }

  /// Formatted distance string e.g. "1.2 km away" or "850 m away".
  String? formattedDistanceTo(double? userLat, double? userLng) {
    if (userLat == null || userLng == null) return null;
    final km = distanceTo(userLat, userLng);
    if (km == null) return null;
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }

  /// Case-insensitive query matching against name, city, and address.
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        address.toLowerCase().contains(q);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'type': type.name,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isVerified': isVerified,
      'isSampleData': isSampleData,
      if (operatingHours != null) 'operatingHours': operatingHours!.trim(),
      if (notes != null) 'notes': notes!.trim(),
    };
  }

  factory HospitalModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return HospitalModel(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Facility',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      type: HospitalType.fromString(map['type'] as String?),
      phone: map['phone'] as String?,
      latitude: parseCoord(map['latitude']),
      longitude: parseCoord(map['longitude']),
      isVerified: map['isVerified'] as bool? ?? false,
      isSampleData: map['isSampleData'] as bool? ?? false,
      operatingHours: map['operatingHours'] as String?,
      notes: map['notes'] as String?,
    );
  }

  factory HospitalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return HospitalModel.fromMap(data, id: snapshot.id);
  }

  HospitalModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    HospitalType? type,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isSampleData,
    String? operatingHours,
    String? notes,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isSampleData: isSampleData ?? this.isSampleData,
      operatingHours: operatingHours ?? this.operatingHours,
      notes: notes ?? this.notes,
    );
  }
}
