import 'package:cloud_firestore/cloud_firestore.dart';


import '../../models/subscription_model.dart';

class SubscriptionService {
  static final _firestore = FirebaseFirestore.instance;






  static Future<SubscriptionModel?> getSubscription(String uid) async {
    final doc = await _firestore.collection('subscriptions').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      // If no document exists, they are on 'free' tier locally
      return SubscriptionModel(userId: uid);
    }
    return SubscriptionModel.fromMap(doc.data()!);
  }

  static Future<void> updateSubscription(String uid, String tier, int durationDays, int maxApp, int creditsToGrant) async {
    final expiry = DateTime.now().add(Duration(days: durationDays));
    
    await _firestore.collection('subscriptions').doc(uid).set({
      'userId': uid,
      'currentTier': tier,
      'validUntil': Timestamp.fromDate(expiry),
      'maxApplicationsPerDay': maxApp,
      'usedApplicationsToday': 0,
      'lastApplicationDate': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
    
    // Also update users collection for quick checks and add credits
    await _firestore.collection('users').doc(uid).update({
      'subscriptionTier': tier,
      'subscriptionValidUntil': Timestamp.fromDate(expiry),
      'credits': FieldValue.increment(creditsToGrant),
    });
  }

  static Future<void> addCredits(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'credits': FieldValue.increment(amount),
    });
  }

  static Future<bool> deductApplication(String uid) async {
    final sub = await getSubscription(uid);
    if (sub == null || !sub.isActive || !sub.canApplyForJob) return false;

    int newUsed = sub.usedApplicationsToday + 1;
    // reset if new day
    if (sub.lastApplicationDate != null) {
      final now = DateTime.now();
      if (now.day != sub.lastApplicationDate!.day || 
          now.month != sub.lastApplicationDate!.month || 
          now.year != sub.lastApplicationDate!.year) {
        newUsed = 1;
      }
    }

    await _firestore.collection('subscriptions').doc(uid).update({
      'usedApplicationsToday': newUsed,
      'lastApplicationDate': Timestamp.fromDate(DateTime.now()),
    });
    return true;
  }
}
