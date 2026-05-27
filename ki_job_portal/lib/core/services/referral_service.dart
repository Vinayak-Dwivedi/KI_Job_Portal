import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReferralService {
  static final _db = FirebaseFirestore.instance;
  static const String baseUrl = 'http://localhost:5000/api'; // Use dynamic IP in prod

  static Future<Map<String, dynamic>> getReferralSettings() async {
    final snap = await _db.collection('settings').doc('referrals').get();
    if (snap.exists) return snap.data()!;
    return {
      'isActive': true,
      'bonusPerReferral': 100,
      'maxReferralsPerUser': 0,
      'validityWindowDays': 30
    };
  }

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

  static Future<void> processReferralReward(String referredUid, String referrerUid) async {
    if (referrerUid.isEmpty) return;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/referrals/award'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'referrerUid': referrerUid,
          'referredUid': referredUid,
        }),
      );

      if (response.statusCode == 200) {
        print("Referral awarded successfully via backend");
      } else {
        print("Failed to award referral: ${response.body}");
      }
    } catch (e) {
      print("Error calling referral award API: $e");
    }
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
