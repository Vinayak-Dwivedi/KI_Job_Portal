import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? targetPlanId;
  final String? targetUrl;
  final bool isActive;
  final DateTime createdAt;

  PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.targetPlanId,
    this.targetUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      targetPlanId: data['targetPlanId'],
      targetUrl: data['targetUrl'],
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetPlanId': targetPlanId,
      'targetUrl': targetUrl,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
