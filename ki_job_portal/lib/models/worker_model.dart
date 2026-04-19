import 'dart:io';
import 'document_model.dart';

class WorkerModel {
  final String uid;
  final String name;
  final String? profilePhotoUrl;
  final File? localImageFile; // For unuploaded changes
  final String location;
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
  final List<DocumentModel> documents;

  WorkerModel({
    required this.uid,
    required this.name,
    this.profilePhotoUrl,
    this.localImageFile,
    this.location = '',
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
    this.documents = const [],
  });

  WorkerModel copyWith({
    String? uid,
    String? name,
    String? profilePhotoUrl,
    File? localImageFile,
    String? location,
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
    List<DocumentModel>? documents,
  }) {
    return WorkerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      localImageFile: localImageFile ?? this.localImageFile,
      location: location ?? this.location,
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
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'location': location,
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
      'documents': documents.map((x) => x.toMap()).toList(),
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map, String uid) {
    // 🌍 Robust location parsing (Handle Map vs String)
    String parsedLocation = '';
    final locData = map['location'];
    if (locData is Map) {
      parsedLocation = (locData['address'] ?? '').toString();
    } else {
      parsedLocation = (locData ?? '').toString();
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
      documents: (map['documents'] as List?)
              ?.map((x) => DocumentModel.fromMap(Map<String, dynamic>.from(x)))
              .toList() ??
          [],
    );
  }
}
