import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String bloodGroup;
  final String city;
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
    required this.bloodGroup,
    this.city = '',
    this.isDonorAvailable = false,
    this.isVerified = false,
    this.createdAt,
    this.donationsCount = 0,
    this.livesSaved = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'city': city,
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
      isDonorAvailable: isDonorAvailable ?? this.isDonorAvailable,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      donationsCount: donationsCount ?? this.donationsCount,
      livesSaved: livesSaved ?? this.livesSaved,
    );
  }
}
