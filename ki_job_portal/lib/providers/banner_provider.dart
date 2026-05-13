import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? headline;
  final String? subhead;
  final String? targetRoute;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.headline,
    this.subhead,
    this.targetRoute,
    required this.isActive,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      headline: data['headline'],
      subhead: data['subhead'],
      targetRoute: data['targetRoute'],
      isActive: data['isActive'] ?? false,
    );
  }
}

final activeBannerProvider = StreamProvider<BannerModel?>((ref) {
  return FirebaseFirestore.instance
      .collection('system_config')
      .doc('active_banner')
      .snapshots()
      .map((doc) => doc.exists ? BannerModel.fromFirestore(doc) : null);
});
