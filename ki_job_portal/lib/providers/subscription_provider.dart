import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ki_job_portal/models/subscription_model.dart';
import 'package:ki_job_portal/models/subscription_plan_model.dart';
import 'package:ki_job_portal/core/services/subscription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ki_job_portal/providers/auth_provider.dart';

final subscriptionProvider = StreamProvider<SubscriptionModel?>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance.collection('subscriptions').doc(user.uid).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) {
      return SubscriptionModel(userId: user.uid);
    }
    return SubscriptionModel.fromMap(doc.data()!);
  });
});

/// Streams subscription plans in real-time from Firestore so any admin
/// changes are reflected immediately without app restart.
final subscriptionPlansProvider = StreamProvider<List<SubscriptionPlan>>((ref) {
  return FirebaseFirestore.instance
      .collection('subscription_plans')
      .orderBy('price')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => SubscriptionPlan.fromFirestore(doc))
          .toList());
});

/// Streams credit bundles in real-time from Firestore.
final creditPacksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('credit_bundles')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
});
