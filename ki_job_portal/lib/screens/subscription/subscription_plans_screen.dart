import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/subscription_plan_model.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Upgrade Pro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('subscription_plans').orderBy('price').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data!.docs.map((doc) => SubscriptionPlan.fromFirestore(doc)).toList();

          if (plans.isEmpty) {
            return const Center(child: Text('No subscription plans available at the moment.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Get Discovered Faster',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a plan that fits your career goals.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                ...plans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildPlanCard(
                      context,
                      plan: plan,
                    ),
                  );
                }),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required SubscriptionPlan plan,
  }) {
    final Color color = Color(int.parse(plan.color.replaceAll('#', '0xFF')));
    final String priceStr = '₹${plan.price}';
    final String duration = plan.durationDays >= 90 ? '/quarter' : '/mo';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? color : const Color(0xFFE2E8F0), width: isPopular ? 2 : 1),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
              child: const Text('MOST POPULAR', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceStr, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0, left: 4),
                      child: Text(duration, style: const TextStyle(color: Color(0xFF64748B))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF334155), fontSize: 14))),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/subscription-checkout', extra: {
                        'plan': plan,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Choose Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
