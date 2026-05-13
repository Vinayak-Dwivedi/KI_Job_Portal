import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/services/subscription_service.dart';
import '../../core/services/referral_service.dart';
import '../../core/services/coupon_service.dart';
import '../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';

import '../../models/subscription_plan_model.dart';

import '../../models/coupon_model.dart';

class SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const SubscriptionCheckoutScreen({
    super.key,
    required this.plan,
  });

  @override
  ConsumerState<SubscriptionCheckoutScreen> createState() => _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends ConsumerState<SubscriptionCheckoutScreen> {
  bool _isProcessing = false;
  final TextEditingController _couponController = TextEditingController();
  CouponModel? _appliedCoupon;
  String? _couponError;
  String? _referrerUid;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful! Now update Firestore.
    _processSubscription(paymentId: response.paymentId, orderId: response.orderId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  Future<void> _initiatePayment() async {
    // Temporarily bypass Razorpay (Phase 6 logic)
    await _processSubscription(paymentId: "mock_payment_id", orderId: "mock_order_id");
  }

  double get _discountAmount {
    if (_appliedCoupon == null) return 0;
    return widget.plan.price * (_appliedCoupon!.discountPercent / 100);
  }

  double get _finalPrice => widget.plan.price - _discountAmount;

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // 1. Try Coupon
    final coupon = await CouponService.validateCoupon(code);
    if (coupon != null) {
      setState(() {
        _appliedCoupon = coupon;
        _referrerUid = null;
        _couponError = null;
      });
      return;
    }

    // 2. Try Referral Code
    final referrer = await ReferralService.validateReferralCode(code);
    if (referrer != null) {
      setState(() {
        _referrerUid = referrer;
        _appliedCoupon = null;
        _couponError = null;
      });
      return;
    }

    setState(() {
      _couponError = 'Invalid code';
      _appliedCoupon = null;
      _referrerUid = null;
    });
  }

  Future<void> _processSubscription({String? paymentId, String? orderId}) async {
    // Note: In a real app, you'd verify the payment signature on the backend here.
    setState(() => _isProcessing = true);
    try {
      final authUser = ref.read(authProvider);
      if (authUser == null) throw Exception('User not logged in');
      
      final uid = authUser.uid;
      
      // Double check current subscription to prevent duplicate active tiers
      final currentSub = ref.read(subscriptionProvider).value;
      if (currentSub != null && currentSub.currentTier == widget.plan.id && currentSub.isActive) {
        throw Exception('You already have an active ${widget.plan.name} subscription.');
      }
      
      // Update usage if coupon was applied
      if (_appliedCoupon != null) {
        await CouponService.incrementUsage(_appliedCoupon!.id);
      }

      await SubscriptionService.updateSubscription(
        uid, 
        widget.plan.id, 
        widget.plan.durationDays, 
        widget.plan.maxApplicationsPerDay,
        widget.plan.credits,
        bonusCredits: _appliedCoupon?.bonusCredits ?? 0,
        referrerUid: _referrerUid,
        limitType: widget.plan.limitType,
        maxContactUnlocks: widget.plan.maxContactUnlocks,
        maxJobApplications: widget.plan.maxJobApplications,
        maxHires: widget.plan.maxHires,
      );
      
      await ref.read(workerProvider.notifier).loadProfile(uid);
      await ref.read(employerProvider.notifier).loadProfile(uid);

      if (mounted) {
        context.go('/subscription-success'); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction Successful! Credits added to your account. ⚡'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription update failed: $e'),
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
          'Secure Checkout', 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: _buildGlow(AppColors.primary.withOpacity(0.1), 300),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Your Order', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Secure transaction powered by Razorpay', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white38, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildOrderSummaryCard(),
                  
                  const SizedBox(height: 24),
                  _buildCouponSection(),
                  
                  const SizedBox(height: 32),
                  _buildSecurityBadge(),
                  
                  const SizedBox(height: 40),
                  _buildPayButton(),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Cancel anytime in account settings',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 40), // Extra padding for bottom
                ],
              ),
            ),
          ],
        ),
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
                        widget.plan.name, 
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.plan.durationDays} Days Access', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white38)
                      ),
                    ],
                  ),
                  Text(
                    '₹${widget.plan.price}', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Total', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white60)
                  ),
                  Text(
                    '₹${widget.plan.price}', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)
                  ),
                ],
              ),
              if (_appliedCoupon != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coupon Discount (${_appliedCoupon!.discountPercent.toInt()}%)', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))
                    ),
                    Text(
                      '-₹${_discountAmount.toStringAsFixed(1)}', 
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))
                    ),
                  ],
                ),
                if ((_appliedCoupon!.bonusCredits ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bonus Credits', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)
                      ),
                      Text(
                        '+${_appliedCoupon!.bonusCredits}', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)
                      ),
                    ],
                  ),
                ],
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
              'Your payment information is encrypted and never stored on our servers.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final currentSub = ref.watch(subscriptionProvider).value;
    final bool isAlreadyActive = currentSub != null && currentSub.currentTier == widget.plan.id && currentSub.isActive;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: (_isProcessing || isAlreadyActive) ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: isAlreadyActive ? Colors.white10 : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: isAlreadyActive ? 0 : 10,
          shadowColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isProcessing 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(
              isAlreadyActive ? 'Already Bought - Upgrade Available' : 'Confirm Payment', 
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900, 
                fontSize: isAlreadyActive ? 14 : 17, 
                letterSpacing: 0.5,
                color: isAlreadyActive ? Colors.white54 : Colors.white,
              )
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
                    hintText: 'Enter code (e.g. WELCOME50)',
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
        if (_appliedCoupon != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Coupon "${_appliedCoupon!.code}" applied! ${(_appliedCoupon!.bonusCredits ?? 0) > 0 ? "Enjoy +${_appliedCoupon!.bonusCredits} bonus credits!" : ""}', 
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (_referrerUid != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Referral code applied! You\'re helping a friend. 🤝', 
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
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
