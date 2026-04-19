import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../core/services/subscription_service.dart';

final subscriptionProvider = FutureProvider<SubscriptionModel?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  return await SubscriptionService.getSubscription(user.uid);
});
