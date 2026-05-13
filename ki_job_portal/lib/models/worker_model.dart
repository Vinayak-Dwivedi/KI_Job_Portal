import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'document_model.dart';

class WorkerModel {
  final String uid;
  final String name;
  final String? profilePhotoUrl;
  final File? localImageFile; // For unuploaded changes
  final String location;
  final String? subLocation;
  final String bio;
  final String jobCategory; // "blue_collar", "white_collar", "both"
  final List<String> jobTitles;
  final List<String> skills;
  final int experience;
  final bool isVerified;
  final String phone;
  final String? email;
  final int credits;
  final double rating;
  final int reviewCount;
  final DateTime? dateOfBirth;
  final String? referralCode;
  final String? referredBy;
  final double? latitude;
  final double? longitude;
  
  // Extended Verification Details
  final String? gender;
  final String? nationality;
  final String? permanentAddress;
  final String? aadhaarNumber;
  final String? emergencyContact;
  final Map<String, dynamic>? bankDetails;

  final bool isAvailable;
  final bool isTopRated;
  final bool isElite;
  final bool isExpert;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final List<Map<String, dynamic>> portfolio;
  final List<DocumentModel> documents;

  WorkerModel({
    required this.uid,
    required this.name,
    this.profilePhotoUrl,
    this.localImageFile,
    this.location = '',
    this.subLocation,
    this.bio = '',
    this.jobCategory = 'blue_collar',
    this.jobTitles = const [],
    this.skills = const [],
    this.experience = 0,
    this.isVerified = false,
    required this.phone,
    this.email = '',
    this.credits = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.permanentAddress,
    this.aadhaarNumber,
    this.emergencyContact,
    this.bankDetails,
    this.isAvailable = true,
    this.isTopRated = false,
    this.isElite = false,
    this.isExpert = false,
    this.isFeatured = false,
    this.featuredUntil,
    this.portfolio = const [],
    this.documents = const [],
    this.referralCode,
    this.referredBy,
    this.latitude,
    this.longitude,
  });

  WorkerModel copyWith({
    String? uid,
    String? name,
    String? profilePhotoUrl,
    File? localImageFile,
    String? location,
    String? subLocation,
    String? bio,
    String? jobCategory,
    List<String>? jobTitles,
    List<String>? skills,
    bool? isVerified,
    String? phone,
    String? email,
    int? credits,
    int? experience,
    double? rating,
    int? reviewCount,
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    String? permanentAddress,
    String? aadhaarNumber,
    String? emergencyContact,
    Map<String, dynamic>? bankDetails,
    bool? isAvailable,
    bool? isTopRated,
    bool? isElite,
    bool? isExpert,
    bool? isFeatured,
    DateTime? featuredUntil,
    List<Map<String, dynamic>>? portfolio,
    List<DocumentModel>? documents,
    String? referralCode,
    String? referredBy,
    double? latitude,
    double? longitude,
  }) {
    return WorkerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      localImageFile: localImageFile ?? this.localImageFile,
      location: location ?? this.location,
      subLocation: subLocation ?? this.subLocation,
      bio: bio ?? this.bio,
      jobCategory: jobCategory ?? this.jobCategory,
      jobTitles: jobTitles ?? this.jobTitles,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      credits: credits ?? this.credits,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bankDetails: bankDetails ?? this.bankDetails,
      isAvailable: isAvailable ?? this.isAvailable,
      isTopRated: isTopRated ?? this.isTopRated,
      isElite: isElite ?? this.isElite,
      isExpert: isExpert ?? this.isExpert,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      portfolio: portfolio ?? this.portfolio,
      documents: documents ?? this.documents,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'location': location,
      'subLocation': subLocation,
      'bio': bio,
      'jobCategory': jobCategory,
      'jobTitles': jobTitles,
      'skills': skills,
      'experience': experience,
      'isVerified': isVerified,
      'phone': phone,
      'email': email,
      'credits': credits,
      'rating': rating,
      'reviewCount': reviewCount,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
      'permanentAddress': permanentAddress,
      'aadhaarNumber': aadhaarNumber,
      'emergencyContact': emergencyContact,
      'bankDetails': bankDetails,
      'isAvailable': isAvailable,
      'isTopRated': isTopRated,
      'isElite': isElite,
      'isExpert': isExpert,
      'isFeatured': isFeatured,
      if (featuredUntil != null) 'featuredUntil': featuredUntil!.toIso8601String(),
      'portfolio': portfolio,
      'documents': documents.map((x) => x.toMap()).toList(),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map, String uid) {
    // 🌍 Robust location parsing (Handle Map vs String)
    String parsedLocation = '';
    String? subLocation;
    final locData = map['location'];
    if (locData is Map) {
      parsedLocation = (locData['address'] ?? '').toString();
      subLocation = (locData['subLocation'] ?? map['subLocation'] ?? '').toString();
      if (subLocation.isEmpty) subLocation = null;
    } else {
      parsedLocation = (locData ?? '').toString();
      subLocation = (map['subLocation'] ?? '').toString();
      if (subLocation.isEmpty) subLocation = null;
    }

    // 📅 Robust Date parsing (Handle Timestamp vs String)
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is Timestamp) return data.toDate();
      if (data is String) return DateTime.tryParse(data);
      return null;
    }

    // 🛠️ Robust List parsing
    List<String> parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return data.map((e) => e.toString()).toList();
      if (data is String && data.isNotEmpty) return [data];
      return [];
    }

    return WorkerModel(
      uid: uid,
      name: (map['name'] ?? map['fullName'] ?? '').toString(),
      profilePhotoUrl: map['profilePhotoUrl']?.toString() ?? map['userPhotoUrl']?.toString(),
      location: parsedLocation,
      subLocation: subLocation,
      bio: (map['bio'] ?? '').toString(),
      jobCategory: (map['jobCategory'] ?? 'blue_collar').toString(),
      jobTitles: parseList(map['jobTitles']),
      skills: parseList(map['skills']),
      experience: int.tryParse(map['experience']?.toString() ?? '0') ?? 0,
      isVerified: map['isVerified'] ?? map['isUserVerified'] ?? false,
      phone: (map['phone'] ?? '').toString(),
      email: map['email']?.toString(),
      credits: int.tryParse(map['credits']?.toString() ?? '50') ?? 50,
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: int.tryParse(map['reviewCount']?.toString() ?? '0') ?? 0,
      dateOfBirth: parseDate(map['dateOfBirth']),
      gender: map['gender']?.toString(),
      nationality: map['nationality']?.toString(),
      permanentAddress: map['permanentAddress']?.toString(),
      aadhaarNumber: map['aadhaarNumber']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      bankDetails: map['bankDetails'] as Map<String, dynamic>?,
      isAvailable: map['isAvailable'] ?? true,
      isTopRated: map['isTopRated'] ?? false,
      isElite: map['isElite'] ?? false,
      isExpert: map['isExpert'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      featuredUntil: parseDate(map['featuredUntil']),
      portfolio: (map['portfolio'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      documents: (map['documents'] as List?)
              ?.map((x) => DocumentModel.fromMap(Map<String, dynamic>.from(x)))
              .toList() ??
          [],
      referralCode: map['referralCode']?.toString(),
      referredBy: map['referredBy']?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
    );
  }
}
