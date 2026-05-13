import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

import '../../core/services/subscription_service.dart';
import '../../core/services/coupon_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../models/coupon_model.dart';

class CreditCheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pack;

  const CreditCheckoutScreen({
    super.key,
    required this.pack,
  });

  @override
  ConsumerState<CreditCheckoutScreen> createState() => _CreditCheckoutScreenState();
}

class _CreditCheckoutScreenState extends ConsumerState<CreditCheckoutScreen> {
  bool _isProcessing = false;
  final TextEditingController _couponController = TextEditingController();
  CouponModel? _appliedCoupon;
  String? _couponError;

  double get _originalPrice => (widget.pack['price'] ?? 0).toDouble();

  double get _discountAmount {
    if (_appliedCoupon == null) return 0;
    return _originalPrice * (_appliedCoupon!.discountPercent / 100);
  }

  double get _finalPrice => _originalPrice - _discountAmount;

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final coupon = await CouponService.validateCoupon(code);
    setState(() {
      if (coupon != null) {
        _appliedCoupon = coupon;
        _couponError = null;
      } else {
        _couponError = 'Invalid or expired coupon';
        _appliedCoupon = null;
      }
    });
  }

  Future<void> _processPurchase() async {
    setState(() => _isProcessing = true);
    try {
      final authUser = ref.read(authProvider);
      if (authUser == null) throw Exception('User not logged in');
      
      final uid = authUser.uid;
      
      if (_appliedCoupon != null) {
        await CouponService.incrementUsage(_appliedCoupon!.id);
      }

      final credits = widget.pack['credits'] as int;
      await SubscriptionService.addCredits(uid, credits);
      
      await ref.read(workerProvider.notifier).loadProfile(uid);
      await ref.read(employerProvider.notifier).loadProfile(uid);
      
      // Force invalidate the credits stream to ensure absolute UI consistency
      ref.invalidate(userCreditsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('$credits Credits added successfully! ⚡', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/subscription-success'); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: Text(
          'Buy Credits', 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlow(AppColors.primary.withOpacity(0.1), 300),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary', 
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)
                ),
                const SizedBox(height: 40),
                
                _buildOrderSummaryCard(),
                
                const SizedBox(height: 24),
                _buildCouponSection(),
                
                const SizedBox(height: 32),
                _buildSecurityBadge(),
                
                const Spacer(),
                
                _buildPayButton(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.pack['credits']} Credits', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instant Top-up', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white38)
                      ),
                    ],
                  ),
                  Text(
                    '₹$_originalPrice', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)
                  ),
                ],
              ),
              if (_appliedCoupon != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount (${_appliedCoupon!.discountPercent.toInt()}%)', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))
                    ),
                    Text(
                      '-₹${_discountAmount.toInt()}', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))
                    ),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payable', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                  ),
                  Text(
                    '₹${_finalPrice.toStringAsFixed(1)}', 
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: AppColors.primary,
                      shadows: [Shadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)]
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Have a Coupon?', 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _couponError != null ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _couponController,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  'Apply', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        if (_couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _couponError!, 
              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Secure transaction powered by KI Portal Encryption.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isProcessing 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(
              'Pay ₹${_finalPrice.toStringAsFixed(1)}', 
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5)
            ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
        ],
      ),
    );
  }
}
