import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ReferralService {
  static final _db = FirebaseFirestore.instance;

  static String generateReferralCode(String name) {
    final prefix = name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    final random = Random().nextInt(9000) + 1000; // 4 digit random
    return '$prefix$random';
  }

  static Future<String?> validateReferralCode(String code) async {
    if (code.isEmpty) return null;

    final query = await _db
        .collection('users')
        .where('referralCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id; // Returns the UID of the referrer
  }

  static Future<void> setupReferralCode(String uid, String name) async {
    final code = generateReferralCode(name);
    await _db.collection('users').doc(uid).update({
      'referralCode': code,
    });
  }

  static Future<void> processReferralReward(String referredUid, String referrerCode) async {
    if (referrerCode.isEmpty) return;
    
    // 1. Validate code
    final referrerUid = await validateReferralCode(referrerCode);
    if (referrerUid == null || referrerUid == referredUid) return;

    // 2. Link them (Prevent multiple referrals for the same user)
    final userDoc = await _db.collection('users').doc(referredUid).get();
    if (userDoc.data()?['referredBy'] != null) return;

    await _db.collection('users').doc(referredUid).update({
      'referredBy': referrerUid,
    });

    // 3. Give reward (Signup Reward: 10 credits to referrer)
    await _db.collection('users').doc(referrerUid).update({
      'credits': FieldValue.increment(10),
    });

    // 3.5 Log in Transaction History
    await _db.collection('contactCredits').doc(referrerUid).collection('transactions').add({
      'title': 'Referral Reward',
      'description': 'Reward for referring a new user',
      'amount': 10,
      'type': 'credit',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Log the referral
    await _db.collection('referrals').add({
      'referrerUid': referrerUid,
      'referredUid': referredUid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'joined',
      'rewardAmount': 10,
    });
  }

  static Stream<List<Map<String, dynamic>>> getReferralHistory(String uid) {
    return _db
        .collection('referrals')
        .where('referrerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
