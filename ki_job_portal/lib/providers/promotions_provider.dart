import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ki_job_portal/models/promotion_model.dart';

final promotionsProvider = StreamProvider<List<PromotionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList());
});
