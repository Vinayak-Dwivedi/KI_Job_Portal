import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ki_job_portal/models/coupon_model.dart';

class CouponService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<CouponModel?> validateCoupon(String code) async {
    final searchCode = code.trim().toUpperCase();
    debugPrint("🔍 [COUPON] Validating code: $searchCode");

    try {
      final query = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: searchCode)
          .get();

      if (query.docs.isEmpty) {
        debugPrint("❌ [COUPON] Code not found in database.");
        return null;
      }

      final doc = query.docs.first;
      final coupon = CouponModel.fromFirestore(doc);
      
      // Detailed validation logging
      final now = DateTime.now();
      final bool isStatusActive = coupon.status.toLowerCase() == 'active';
      final bool isNotExpired = coupon.expiryDate.isAfter(now);
      final bool hasUsageLeft = coupon.currentUsage < coupon.maxUsage;

      debugPrint("📊 [COUPON] Status: ${coupon.status}, Expire: ${coupon.expiryDate}, Usage: ${coupon.currentUsage}/${coupon.maxUsage}");

      if (!isStatusActive) {
        debugPrint("❌ [COUPON] Status is not active.");
        return null;
      }
      if (!isNotExpired) {
        debugPrint("❌ [COUPON] Coupon has expired.");
        return null;
      }
      if (!hasUsageLeft) {
        debugPrint("❌ [COUPON] Coupon has reached max usage.");
        return null;
      }

      debugPrint("✅ [COUPON] Coupon is valid! Discount: ${coupon.discountPercent}%");
      return coupon;
    } catch (e) {
      debugPrint("⚠️ [COUPON] Validation error: $e");
      return null;
    }
  }

  static Future<void> incrementUsage(String couponId) async {
    await _firestore.collection('coupons').doc(couponId).update({
      'currentUsage': FieldValue.increment(1),
    });
  }
}
