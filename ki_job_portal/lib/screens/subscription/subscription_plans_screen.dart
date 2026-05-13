import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/subscription_plan_model.dart';
import '../../models/subscription_model.dart';
import '../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSubAsync = ref.watch(subscriptionProvider);
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Choose Your Path',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlow(AppColors.primary.withOpacity(0.15), 300),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildGlow(const Color(0xFF10B981).withOpacity(0.1), 400),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('subscription_plans').orderBy('price').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final plans = snapshot.data!.docs.map((doc) => SubscriptionPlan.fromFirestore(doc)).toList();

              if (plans.isEmpty) {
                return const Center(
                  child: Text(
                    'No plans available. Check back soon!',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
                child: Column(
                  children: [
                    _buildBadge(),
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 40),

                    ...plans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildPremiumPlanCard(
                                    context, 
                                    ref,
                                    plan: plan, 
                                    currentSub: currentSubAsync.value
                                  ),
                                ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'UNLIMITED POTENTIAL',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Accelerate Your Growth',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Choose a premium plan to unlock elite features and priority job matching.',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: Colors.white60,
        height: 1.5,
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
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlanCard(
    BuildContext context, 
    WidgetRef ref,
    {required SubscriptionPlan plan, SubscriptionModel? currentSub}
  ) {
    final bool isElite = plan.name.toLowerCase().contains('elite') || plan.isPopular;
    final bool isCurrentPlan = currentSub != null && currentSub.currentTier == plan.id && currentSub.isActive;
    
    // Find current plan price to determine if upgrade is allowed
    final allPlans = ref.watch(subscriptionPlansProvider).value ?? [];
    double currentPrice = 0;
    if (currentSub != null && currentSub.isActive) {
      final currentPlanData = allPlans.where((p) => p.id == currentSub.currentTier).firstOrNull;
      currentPrice = currentPlanData?.price.toDouble() ?? 0;
    }

    final bool isUpgrade = currentSub != null && currentSub.isActive && plan.price > currentPrice && !isCurrentPlan;
    final bool isDowngradeOrSame = currentSub != null && currentSub.isActive && plan.price <= currentPrice && !isCurrentPlan;
    
    // Ownership lock: Only higher tiers (upgrade path) remain tappable
    // If it's the current plan, it's NOT interactable (user already owns it)
    final bool canInteract = isUpgrade || (currentSub == null || !currentSub.isActive);
    final bool isDimmed = isDowngradeOrSame;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentPlan || isDowngradeOrSame ? Colors.white.withOpacity(0.015) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCurrentPlan ? Colors.green.withOpacity(0.5) : (isElite ? AppColors.primary.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
              width: isElite || isCurrentPlan ? 2 : 1,
            ),
            boxShadow: isElite && !isDowngradeOrSame ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: -10,
              )
            ] : null,
          ),
          child: Opacity(
            opacity: isDimmed ? 0.5 : 1.0,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isElite)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4F46E5)],
                    ),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (isElite)
                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${plan.price}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0, left: 6),
                          child: Text(
                            plan.durationDays >= 90 ? '/quarter' : '/month',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isElite ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: isElite ? AppColors.primary : Colors.white60,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isCurrentPlan || isDowngradeOrSame ? null : () {
                          context.push('/subscription-checkout', extra: {
                            'plan': plan,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUpgrade ? AppColors.primary : Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isCurrentPlan 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.02),
                          disabledForegroundColor: isCurrentPlan ? Colors.green : Colors.white24,
                          elevation: isElite && !isCurrentPlan ? 10 : 0,
                          shadowColor: isElite && !isCurrentPlan ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: isCurrentPlan ? const BorderSide(color: Colors.green, width: 1) : null,
                        ),
                        child: Text(
                          isCurrentPlan 
                            ? '✅ Active Plan · ${currentSub.validityString}' 
                            : (isUpgrade 
                                ? '⬆ Upgrade to ${plan.name}' 
                                : (isDowngradeOrSame ? 'Included in your plan' : 'Select ${plan.name}')),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
