import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final double discountPercent;
  final int maxUsage;
  final int currentUsage;
  final DateTime expiryDate;
  final String status;
  final int bonusCredits;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxUsage,
    required this.currentUsage,
    required this.expiryDate,
    required this.status,
    required this.bonusCredits,
  });

  bool get isActive => status.toLowerCase() == 'active' && 
                      currentUsage < maxUsage && 
                      expiryDate.isAfter(DateTime.now());

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(days: 30));
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CouponModel(
      id: doc.id,
      code: data['code']?.toString() ?? '',
      discountPercent: (data['discountPercent'] ?? 0).toDouble(),
      maxUsage: int.tryParse(data['maxUsage']?.toString() ?? '100') ?? 100,
      currentUsage: int.tryParse(data['currentUsage']?.toString() ?? '0') ?? 0,
      expiryDate: _parseDate(data['expiryDate']),
      status: data['status']?.toString() ?? 'Active',
      bonusCredits: int.tryParse(data['bonusCredits']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercent': discountPercent,
      'maxUsage': maxUsage,
      'currentUsage': currentUsage,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status,
      'bonusCredits': bonusCredits,
    };
  }
}
