import 'package:cloud_firestore/cloud_firestore.dart';
import 'document_model.dart';

class EmployerModel {
  final String uid;
  final String companyName;
  final String businessType;
  final String? website;
  final String contactPersonName;
  final String phone;
  final String? email;
  final String officeAddress;
  final GeoPoint? officeLatLng;
  final String? logoUrl;
  final String? gstCertificateUrl;
  final String? govtIdUrl;
  final bool isVerified;
  final int credits;
  final String bio;
  final double rating;
  final int reviewCount;
  final String hirerSubType;
  final List<DocumentModel> documents;

  EmployerModel({
    required this.uid,
    required this.companyName,
    required this.businessType,
    this.website,
    required this.contactPersonName,
    required this.phone,
    this.email,
    required this.officeAddress,
    this.officeLatLng,
    this.logoUrl,
    this.gstCertificateUrl,
    this.govtIdUrl,
    this.isVerified = false,
    this.credits = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.bio = '',
    this.hirerSubType = 'company',
    this.documents = const [],
  });

  String get name => companyName.isNotEmpty ? companyName : contactPersonName;
  String? get profilePhotoUrl => logoUrl;
  String get contactName => contactPersonName;

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'businessType': businessType,
      'hirerSubType': hirerSubType,
      'website': website,
      'contactPersonName': contactPersonName,
      'phone': phone,
      'email': email,
      'officeAddress': officeAddress,
      'officeLatLng': officeLatLng,
      'logoUrl': logoUrl,
      'gstCertificateUrl': gstCertificateUrl,
      'govtIdUrl': govtIdUrl,
      'isVerified': isVerified,
      'credits': credits,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'documents': documents.map((x) => x.toMap()).toList(),
    };
  }

  factory EmployerModel.fromMap(Map<String, dynamic> map, String uid) {
    // 🌍 Robust location parsing (Handle Map vs String)
    String parsedLocation = '';
    final locData = map['officeAddress'] ?? map['location'];
    if (locData is Map) {
      parsedLocation = (locData['address'] ?? '').toString();
    } else {
      parsedLocation = (locData ?? '').toString();
    }

    return EmployerModel(
      uid: uid,
      companyName: (map['companyName'] ?? map['name'] ?? '').toString(),
      businessType: (map['businessType'] ?? '').toString(),
      hirerSubType: (map['hirerSubType'] ?? 'company').toString(),
      website: map['website']?.toString(),
      contactPersonName: (map['contactPersonName'] ?? map['fullName'] ?? map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: map['email']?.toString(),
      officeAddress: parsedLocation,
      officeLatLng: map['officeLatLng'] ?? map['locationLatLng'],
      logoUrl: map['logoUrl']?.toString() ?? map['profilePhotoUrl']?.toString() ?? map['userPhotoUrl']?.toString(),
      gstCertificateUrl: map['gstCertificateUrl']?.toString(),
      govtIdUrl: map['govtIdUrl']?.toString(),
      isVerified: map['isVerified'] ?? map['isUserVerified'] ?? false,
      credits: int.tryParse(map['credits']?.toString() ?? '50') ?? 50,
      bio: (map['bio'] ?? '').toString(),
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: int.tryParse(map['reviewCount']?.toString() ?? '0') ?? 0,
      documents: (map['documents'] as List?)
              ?.map((x) => DocumentModel.fromMap(Map<String, dynamic>.from(x)))
              .toList() ??
          [],
    );
  }
}

