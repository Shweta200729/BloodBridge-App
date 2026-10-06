import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String bloodGroup;
  final String city;
  final String userType; // 'donor' | 'hospital'
  final String? hospitalName;
  final String? licenseNumber;
  final String? address;
  final bool isDonorAvailable;
  final bool isVerified;
  final DateTime? createdAt;
  final int donationsCount;
  final int livesSaved;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.bloodGroup = '',
    this.city = '',
    this.userType = 'donor',
    this.hospitalName,
    this.licenseNumber,
    this.address,
    this.isDonorAvailable = false,
    this.isVerified = false,
    this.createdAt,
    this.donationsCount = 0,
    this.livesSaved = 0,
  });

  bool get isHospital => userType.toLowerCase() == 'hospital';
  bool get isDonor => !isHospital;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'city': city,
      'userType': userType,
      if (hospitalName != null) 'hospitalName': hospitalName,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (address != null) 'address': address,
      'isDonorAvailable': isDonorAvailable,
      'isVerified': isVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'donationsCount': donationsCount,
      'livesSaved': livesSaved,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? '',
      city: map['city'] as String? ?? '',
      userType: map['userType'] as String? ?? 'donor',
      hospitalName: map['hospitalName'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      address: map['address'] as String?,
      isDonorAvailable: map['isDonorAvailable'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      donationsCount: (map['donationsCount'] as num?)?.toInt() ?? 0,
      livesSaved: (map['livesSaved'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return UserModel.fromMap(data, uid: snapshot.id);
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? bloodGroup,
    String? city,
    String? userType,
    String? hospitalName,
    String? licenseNumber,
    String? address,
    bool? isDonorAvailable,
    bool? isVerified,
    DateTime? createdAt,
    int? donationsCount,
    int? livesSaved,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      city: city ?? this.city,
      userType: userType ?? this.userType,
      hospitalName: hospitalName ?? this.hospitalName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      address: address ?? this.address,
      isDonorAvailable: isDonorAvailable ?? this.isDonorAvailable,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      donationsCount: donationsCount ?? this.donationsCount,
      livesSaved: livesSaved ?? this.livesSaved,
    );
  }
}
