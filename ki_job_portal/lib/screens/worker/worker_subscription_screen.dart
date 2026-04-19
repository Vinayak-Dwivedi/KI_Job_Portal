import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkerSubscriptionScreen extends ConsumerStatefulWidget {
  const WorkerSubscriptionScreen({super.key});

  @override
  ConsumerState<WorkerSubscriptionScreen> createState() => _WorkerSubscriptionScreenState();
}

class _WorkerSubscriptionScreenState extends ConsumerState<WorkerSubscriptionScreen> {
  int _tabIndex = 0;
  String? _selectedPlan;

  static const int _totalContacts = 20;
  static const int _usedContacts = 14;

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
            // ── Usage Banner ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('FREE PLAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                        const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('${_totalContacts - _usedContacts} contacts remaining',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Upgrade to get unlimited contacts', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _usedContacts / _totalContacts,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${((_usedContacts / _totalContacts) * 100).round()}% OF MONTHLY LIMIT USED',
                        style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 0.5)),
                  ],
                ),
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
              _PlanCard(planKey: 'basic', badge: 'BASIC', price: '₹299', period: '/month', features: const ['20 contacts', 'Basic visibility'], highlighted: false, popularBadge: false, selectedPlan: _selectedPlan, onSelect: (k) => setState(() => _selectedPlan = k)),
              _PlanCard(planKey: 'professional', badge: 'PROFESSIONAL', price: '₹699', period: '/month', features: const ['50 contacts/month', 'Priority in search', 'Verified badge'], highlighted: true, popularBadge: true, selectedPlan: _selectedPlan, onSelect: (k) => setState(() => _selectedPlan = k)),
              _PlanCard(planKey: 'elite', badge: 'ELITE', price: '₹1499', period: '/month', features: const ['Unlimited contacts', 'All features included'], highlighted: false, popularBadge: false, selectedPlan: _selectedPlan, onSelect: (k) => setState(() => _selectedPlan = k)),
            ] else ...[
              const _CreditPack(amount: '10', price: '₹99', bonus: ''),
              const _CreditPack(amount: '30', price: '₹249', bonus: '+5 FREE'),
              const _CreditPack(amount: '100', price: '₹699', bonus: '+20 FREE'),
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
  final String planKey, badge, price, period;
  final List<String> features;
  final bool highlighted, popularBadge;
  final String? selectedPlan;
  final void Function(String) onSelect;

  const _PlanCard({required this.planKey, required this.badge, required this.price, required this.period, required this.features, required this.highlighted, required this.popularBadge, required this.selectedPlan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => onSelect(planKey),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: highlighted ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2), width: highlighted ? 2 : 1),
              boxShadow: highlighted ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: price, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
                    TextSpan(text: period, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                  ]),
                ),
                const SizedBox(height: 14),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 18, height: 18, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 12)),
                      const SizedBox(width: 8),
                      Text(f, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: highlighted
                      ? ElevatedButton(
                          onPressed: () => onSelect(planKey),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                          child: const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        )
                      : OutlinedButton(
                          onPressed: () => onSelect(planKey),
                          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.primary, side: BorderSide(color: theme.colorScheme.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (popularBadge)
          Positioned(
            top: -14, right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(20)),
              child: const Text('MOST POPULAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
            ),
          ),
      ],
    );
  }
}

class _CreditPack extends StatelessWidget {
  final String amount, price, bonus;
  const _CreditPack({required this.amount, required this.price, required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$amount Credits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                if (bonus.isNotEmpty) Text(bonus, style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(price, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
