import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ki_job_portal/providers/subscription_provider.dart';
import 'package:ki_job_portal/providers/worker_provider.dart';
import 'package:ki_job_portal/core/theme/app_colors.dart';
import 'package:ki_job_portal/models/subscription_plan_model.dart';
import 'package:ki_job_portal/models/subscription_model.dart';
import 'package:ki_job_portal/screens/subscription/subscription_checkout_screen.dart';
import 'package:ki_job_portal/screens/subscription/credit_checkout_screen.dart';
import 'package:ki_job_portal/providers/promotions_provider.dart';
import 'package:ki_job_portal/models/promotion_model.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerSubscriptionScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const WorkerSubscriptionScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<WorkerSubscriptionScreen> createState() => _WorkerSubscriptionScreenState();
}

class _WorkerSubscriptionScreenState extends ConsumerState<WorkerSubscriptionScreen> {
  late int _tabIndex;
  String? _selectedPlan;

  static const int _totalContacts = 20;
  static const int _usedContacts = 14;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          'Unlock More Opportunities',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dynamic Banner (Ads / Usage) ────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, child) {
                  final promotionsAsync = ref.watch(promotionsProvider);
                  
                  return promotionsAsync.when(
                    data: (promotions) {
                      if (promotions.isNotEmpty) {
                        final promo = promotions.first;
                        return _buildPromotionBanner(context, promo, theme, ref);
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ),

            // ── Toggle Tabs ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _TabBtn(label: 'Subscription Plans', index: 0, current: _tabIndex, onTap: (i) => setState(() => _tabIndex = i))),
                    Expanded(child: _TabBtn(label: 'Credit Packs', index: 1, current: _tabIndex, onTap: (i) => setState(() => _tabIndex = i))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Plan / Credit Cards ───────────────────────
            if (_tabIndex == 0) ...[
              ref.watch(subscriptionPlansProvider).when(
                data: (plans) {
                  final subState = ref.watch(subscriptionProvider);
                  final currentTier = subState.value?.currentTier ?? 'free';
                  final otherPlans = plans;

                  if (subState.isLoading) {
                    return _buildPlansSkeleton();
                  }

                  final currentPlan = plans.cast<SubscriptionPlan?>().firstWhere(
                    (p) => p?.id == currentTier,
                    orElse: () => null,
                  );
                  final currentPrice = currentPlan?.price ?? 0;

                  return Column(
                    children: otherPlans.map((plan) => _PlanCard(
                      plan: plan,
                      selectedPlan: _selectedPlan,
                      currentSubscription: subState.value,
                      currentPlanPrice: currentPrice,
                      onSelect: (k) => setState(() => _selectedPlan = k),
                    )).toList(),
                  );
                },
                loading: () => _buildPlansSkeleton(),
                error: (err, _) => Center(child: Text('Error loading plans: $err')),
              ),
            ] else ...[
              ref.watch(creditPacksProvider).when(
                data: (packs) => Column(
                  children: packs.map((pack) => _CreditPack(
                    id: pack['id'],
                    amount: pack['credits'].toString(),
                    price: '₹${pack['price']}',
                    bonus: pack['bonusText'] ?? '',
                  )).toList(),
                ),
                loading: () => _buildPacksSkeleton(),
                error: (err, _) => Center(child: Text('Error loading packs: $err')),
              ),
            ],

            const SizedBox(height: 16),

            // ── Secure Payments Footer ────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('SECURE PAYMENTS', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, color: theme.colorScheme.onSurfaceVariant, size: 32),
                      const SizedBox(width: 16),
                      Icon(Icons.payment, color: theme.colorScheme.onSurfaceVariant, size: 32),
                      const SizedBox(width: 16),
                      Icon(Icons.account_balance, color: theme.colorScheme.onSurfaceVariant, size: 32),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Cancel anytime. No hidden charges.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('© 2024 KI Marketplace. Secure payments via encrypted gateways.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPacksSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(3, (i) => const _CreditPack(id: 'loading', amount: '10', price: '₹99', bonus: 'Bonus')),
      ),
    );
  }

  Widget _buildPlansSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: List.generate(2, (i) => _PlanCard(
          plan: SubscriptionPlan(
            id: 'loading',
            name: 'Loading Plan Name',
            price: 999,
            durationDays: 30,
            features: ['Feature 1', 'Feature 2', 'Feature 3'],
          ),
          selectedPlan: null,
          currentSubscription: null,
          currentPlanPrice: 0,
          onSelect: (_) {},
        )),
      ),
    );
  }

  Widget _buildUsageBanner(BuildContext context, ThemeData theme, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Highlight subscription plans
        setState(() => _tabIndex = 0);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final subscription = ref.watch(subscriptionProvider).value;
                    final String tierName = subscription?.currentTier?.toUpperCase() ?? 'FREE PLAN';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tierName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
                const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final subscription = ref.watch(subscriptionProvider).value;
                final int maxApp = subscription?.maxApplicationsPerDay ?? 5;
                final int usedApp = subscription?.usedApplicationsToday ?? 0;
                final int remaining = maxApp - usedApp;
                final double progress = (usedApp / maxApp).clamp(0.0, 1.0);
                final int percentUsed = (progress * 100).toInt();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remaining Contacts Remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subscription?.currentTier == 'unlimited' 
                        ? 'You have unlimited contacts with your current plan.'
                        : 'Upgrade to get unlimited contacts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$percentUsed% OF MONTHLY LIMIT USED',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$usedApp/$maxApp',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionBanner(BuildContext context, PromotionModel promo, ThemeData theme, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (promo.targetPlanId != null) {
          // Navigate to a specific plan if possible
          setState(() => _tabIndex = 0);
          setState(() => _selectedPlan = promo.targetPlanId);
        } else if (promo.targetUrl != null) {
          final uri = Uri.parse(promo.targetUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          image: promo.imageUrl != null ? DecorationImage(
            image: NetworkImage(promo.imageUrl!),
            fit: BoxFit.cover,
          ) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PROMOTION',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                promo.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                promo.description,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _TabBtn({required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.white : theme.colorScheme.onSurfaceVariant, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ),
    );
  }
}
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String? selectedPlan;
  final SubscriptionModel? currentSubscription;
  final int currentPlanPrice;
  final void Function(String) onSelect;

  const _PlanCard({
    required this.plan,
    required this.selectedPlan,
    required this.currentSubscription,
    required this.currentPlanPrice,
    required this.onSelect,
  });

  Color get _badgeColor {
    try {
      return Color(int.parse((plan.badgeColor ?? '#F43F5E').replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF43F5E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = currentSubscription?.currentTier == plan.id && (currentSubscription?.isActive ?? false);
    final bool isUpgrade = currentSubscription != null && (currentSubscription?.isActive ?? false) && plan.price > currentPlanPrice && !isCurrent;
    final bool isDowngradeOrSame = currentSubscription != null && (currentSubscription?.isActive ?? false) && plan.price <= currentPlanPrice && !isCurrent;
    final hasBadge = plan.badgeLabel != null && plan.badgeLabel!.isNotEmpty;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: (isCurrent || isDowngradeOrSame) ? null : () => onSelect(plan.id),
          child: Opacity(
            opacity: isDowngradeOrSame ? 0.5 : 1.0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isCurrent ? theme.cardColor : theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCurrent ? Colors.green.withOpacity(0.5) : (hasBadge ? AppColors.primary : theme.colorScheme.outline.withOpacity(0.1)), 
                  width: hasBadge || isCurrent ? 2 : 1,
                ),
                boxShadow: hasBadge && !isDowngradeOrSame ? [
                  BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                ] : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // ── Header row ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.name.toUpperCase(), 
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    if (plan.limitType == kLimitTypeCredits && plan.credits > 0)
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${plan.credits} Credits',
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Price ────────────────────────────────────────────────
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '₹${plan.price}', 
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.colorScheme.onSurface, 
                        fontSize: 32, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '/${plan.durationDays} days', 
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.colorScheme.onSurfaceVariant, 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),



                // ── Features list ─────────────────────────────────────────
                const SizedBox(height: 20),
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20, 
                        height: 20, 
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1), 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f, 
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.colorScheme.onSurface, 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 24),
                _buildActionButton(context, theme, isCurrent, hasBadge),
                ],         // Column children
              ),           // Column
            ),             // Container
          ),               // Opacity
        ),                 // GestureDetector

        // ── Dynamic admin badge ───────────────────────────────────────────
        if (hasBadge)
          Positioned(
            top: -12, 
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _badgeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _badgeColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Text(
                plan.badgeLabel!.toUpperCase(), 
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildActionButton(BuildContext context, ThemeData theme, bool isCurrent, bool hasBadge) {
    String label = 'Choose Plan';
    bool isDisabled = false;
    Color? bgColor = hasBadge ? AppColors.primary : theme.colorScheme.surfaceVariant.withOpacity(0.5);
    Color? fgColor = hasBadge ? Colors.white : theme.colorScheme.onSurface;

    final bool isUpgrade = currentSubscription != null && (currentSubscription?.isActive ?? false) && plan.price > currentPlanPrice && !isCurrent;
    final bool isDowngradeOrSame = currentSubscription != null && (currentSubscription?.isActive ?? false) && plan.price <= currentPlanPrice && !isCurrent;

    if (isCurrent) {
      label = '✅ Active Plan · ${currentSubscription!.validityString}';
      isDisabled = true;
      bgColor = Colors.green.withOpacity(0.1);
      fgColor = Colors.green;
    } else if (isUpgrade) {
      label = '⬆ Upgrade to ${plan.name}';
      isDisabled = false;
      bgColor = AppColors.primary;
      fgColor = Colors.white;
    } else if (isDowngradeOrSame) {
      label = 'Included in your plan';
      isDisabled = true;
      bgColor = theme.colorScheme.surfaceVariant.withOpacity(0.2);
      fgColor = theme.colorScheme.onSurface.withOpacity(0.3);
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () {
          onSelect(plan.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionCheckoutScreen(plan: plan)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          side: isCurrent ? const BorderSide(color: Colors.green, width: 1) : null,
        ),
        child: Text(
          label, 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}



class _CreditPack extends StatelessWidget {
  final String id, amount, price, bonus;
  const _CreditPack({required this.id, required this.amount, required this.price, required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54, 
            height: 54, 
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$amount Credits', 
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: theme.colorScheme.onSurface),
                ),
                if (bonus.isNotEmpty) 
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      bonus, 
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price, 
                style: GoogleFonts.plusJakartaSans(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreditCheckoutScreen(pack: {
                          'id': id,
                          'credits': int.parse(amount),
                          'price': int.parse(price.replaceAll('₹', '')),
                        }),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(horizontal: 16), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                    elevation: 0,
                  ),
                  child: Text(
                    'Buy', 
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
