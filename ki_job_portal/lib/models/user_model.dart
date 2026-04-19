import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String role; // "worker" or "employer"
  final bool isVerified;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.createdAt,
    this.fcmToken,
  });

  UserModel copyWith({
    String? uid,
    String? phone,
    String? role,
    bool? isVerified,
    bool? isProfileComplete,
    DateTime? createdAt,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'worker',
      isVerified: map['isVerified'] ?? false,
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'],
    );
  }
}
