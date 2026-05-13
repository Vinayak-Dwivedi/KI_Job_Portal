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
  final String? subLocation;
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
  final DateTime? dateOfBirth;
  final String? referralCode;
  final String? referredBy;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final DateTime? featuredUntil;

  // Extended Verification Details
  final String? companyRegistrationNumber;
  final String? gstNumber;

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
    this.subLocation,
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
    this.dateOfBirth,
    this.companyRegistrationNumber,
    this.gstNumber,
    this.documents = const [],
    this.referralCode,
    this.referredBy,
    this.latitude,
    this.longitude,
    this.isFeatured = false,
    this.featuredUntil,
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
      'subLocation': subLocation,
      'officeLatLng': officeLatLng,
      'logoUrl': logoUrl,
      'gstCertificateUrl': gstCertificateUrl,
      'govtIdUrl': govtIdUrl,
      'isVerified': isVerified,
      'credits': credits,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      'companyRegistrationNumber': companyRegistrationNumber,
      'gstNumber': gstNumber,
      'documents': documents.map((x) => x.toMap()).toList(),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'latitude': latitude,
      'longitude': longitude,
      'isFeatured': isFeatured,
      if (featuredUntil != null) 'featuredUntil': featuredUntil!.toIso8601String(),
    };
  }

  factory EmployerModel.fromMap(Map<String, dynamic> map, String uid) {
    String parsedLocation = '';
    String? subLocation;
    final locData = map['officeAddress'] ?? map['location'];
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
      subLocation: subLocation,
      officeLatLng: map['officeLatLng'] ?? map['locationLatLng'],
      logoUrl: map['logoUrl']?.toString() ?? map['profilePhotoUrl']?.toString() ?? map['userPhotoUrl']?.toString(),
      gstCertificateUrl: map['gstCertificateUrl']?.toString(),
      govtIdUrl: map['govtIdUrl']?.toString(),
      isVerified: map['isVerified'] ?? map['isUserVerified'] ?? false,
      credits: int.tryParse(map['credits']?.toString() ?? '50') ?? 50,
      bio: (map['bio'] ?? '').toString(),
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: int.tryParse(map['reviewCount']?.toString() ?? '0') ?? 0,
      dateOfBirth: parseDate(map['dateOfBirth']),
      companyRegistrationNumber: map['companyRegistrationNumber']?.toString(),
      gstNumber: map['gstNumber']?.toString(),
      documents: (map['documents'] as List?)
              ?.map((x) => DocumentModel.fromMap(Map<String, dynamic>.from(x)))
              .toList() ??
          [],
      referralCode: map['referralCode']?.toString(),
      referredBy: map['referredBy']?.toString(),
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      isFeatured: map['isFeatured'] ?? false,
      featuredUntil: parseDate(map['featuredUntil']),
    );
  }
}

