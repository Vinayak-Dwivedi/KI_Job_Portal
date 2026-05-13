import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ki_job_portal/models/subscription_plan_model.dart';
import 'package:ki_job_portal/models/subscription_model.dart';

class SubscriptionService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<SubscriptionModel?> getSubscription(String uid) async {
    final doc = await _firestore.collection('subscriptions').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return SubscriptionModel(userId: uid);
    }
    return SubscriptionModel.fromMap(doc.data()!);
  }

  static Future<List<SubscriptionPlan>> getAllPlans() async {
    final snapshot = await _firestore.collection('subscription_plans').get();
    return snapshot.docs.map((doc) => SubscriptionPlan.fromFirestore(doc)).toList();
  }

  /// Called when a user purchases a subscription plan.
  /// - Always adds [creditsToGrant] to the user's unified credit balance.
  /// - Copies limit quotas from the plan to the subscription document.
  /// - [limitType] determines whether credits or quotas govern usage.
  static Future<void> updateSubscription(
    String uid,
    String tier,
    int durationDays,
    int maxApp,
    int creditsToGrant, {
    int bonusCredits = 0,
    String? referrerUid,
    String limitType = kLimitTypeLimits,
    int? maxContactUnlocks,
    int? maxJobApplications,
    int? maxHires,
  }) async {
    // Prevent duplicate active subscription for the same tier
    final currentSub = await getSubscription(uid);
    if (currentSub != null && currentSub.currentTier == tier && currentSub.isActive) {
      throw Exception('You already have an active $tier subscription.');
    }

    final expiry = DateTime.now().add(Duration(days: durationDays));
    final totalCredits = creditsToGrant + bonusCredits;

    // ── Write subscription doc ─────────────────────────────────────────────
    final subData = <String, dynamic>{
      'userId': uid,
      'currentTier': tier,
      'validUntil': Timestamp.fromDate(expiry),
      'maxApplicationsPerDay': maxApp,
      'usedApplicationsToday': 0,
      'lastApplicationDate': Timestamp.fromDate(DateTime.now()),
      'limitType': limitType,
      // Reset all period-based counters on new subscription
      'usedContactUnlocks': 0,
      'usedJobApplications': 0,
      'usedHires': 0,
    };

    // Write quota limits (null = unlimited, omit from map)
    if (maxContactUnlocks != null) subData['maxContactUnlocks'] = maxContactUnlocks;
    if (maxJobApplications != null) subData['maxJobApplications'] = maxJobApplications;
    if (maxHires != null) subData['maxHires'] = maxHires;

    await _firestore.collection('subscriptions').doc(uid).set(subData, SetOptions(merge: true));

    // ── Always add credits to the unified balance ──────────────────────────
    await _firestore.collection('users').doc(uid).update({
      'subscriptionTier': tier,
      'subscriptionValidUntil': Timestamp.fromDate(expiry),
      if (totalCredits > 0) 'credits': FieldValue.increment(totalCredits),
    });

    // ── Referral reward ────────────────────────────────────────────────────
    if (referrerUid != null && referrerUid.isNotEmpty) {
      await _firestore.collection('users').doc(referrerUid).update({
        'credits': FieldValue.increment(20),
      });
      await _firestore.collection('users').doc(uid).update({
        'referredBy': referrerUid,
      });
      await _logTransaction(referrerUid, 20, 'Referral Bonus', 'Referral reward for inviting a new user');
    }

    // ── Transaction log ────────────────────────────────────────────────────
    if (totalCredits > 0) {
      await _logTransaction(uid, totalCredits, 'Subscription: $tier', 'Plan activation — credits added to wallet');
    }
  }

  /// Add credits to the user's unified wallet (from Credit Pack purchase).
  static Future<void> addCredits(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'credits': FieldValue.increment(amount),
    });
    await _logTransaction(uid, amount, 'Credit Top-up', 'Direct purchase of contact credits');
  }

  static Future<void> _logTransaction(String uid, int amount, String title, String description) async {
    try {
      await _firestore
          .collection('contactCredits')
          .doc(uid)
          .collection('transactions')
          .add({
        'title': title,
        'description': description,
        'amount': amount,
        'type': amount >= 0 ? 'credit' : 'debit',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore logging failures
    }
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

    final updates = <String, dynamic>{
      'usedApplicationsToday': newUsed,
      'lastApplicationDate': Timestamp.fromDate(DateTime.now()),
    };

    // Also increment period counter in limits mode
    if (sub.limitType == kLimitTypeLimits) {
      updates['usedJobApplications'] = FieldValue.increment(1);
    }

    await _firestore.collection('subscriptions').doc(uid).update(updates);
    return true;
  }

  /// Deduct a contact unlock (limits mode). Returns true on success.
  static Future<bool> deductContactUnlock(String uid) async {
    final sub = await getSubscription(uid);
    if (sub == null || !sub.canUnlockContact) return false;

    if (sub.limitType == kLimitTypeLimits) {
      await _firestore.collection('subscriptions').doc(uid).update({
        'usedContactUnlocks': FieldValue.increment(1),
      });
    }
    return true;
  }

  /// Deduct a hire action (limits mode). Returns true on success.
  static Future<bool> deductHire(String uid) async {
    final sub = await getSubscription(uid);
    if (sub == null || !sub.canHireWorker) return false;

    if (sub.limitType == kLimitTypeLimits) {
      await _firestore.collection('subscriptions').doc(uid).update({
        'usedHires': FieldValue.increment(1),
      });
    }
    return true;
  }

  static Future<bool> isSubscriptionActive(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    final tier = data['subscriptionTier'] ?? 'free';
    if (tier == 'free') return true;
    final end = (data['subscriptionValidUntil'] as Timestamp?)?.toDate();
    if (end == null) return false;
    return end.isAfter(DateTime.now());
  }

  static Future<void> checkAndDeactivateIfExpired(String uid) async {
    final isActive = await isSubscriptionActive(uid);
    if (!isActive) {
      await _firestore.collection('users').doc(uid).update({'subscriptionTier': 'free'});
      await _firestore.collection('subscriptions').doc(uid).update({'currentTier': 'free'});
    }
  }
}
