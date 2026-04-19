import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/subscription_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';

import '../../models/subscription_plan_model.dart';

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

  Future<void> _processSubscription() async {
    setState(() => _isProcessing = true);
    try {
      final auth = FirebaseAuth.instance.currentUser;
      if (auth == null) throw Exception('User not logged in');
      
      final uid = auth.uid;
      
      await SubscriptionService.updateSubscription(
        uid, 
        widget.plan.id, 
        widget.plan.durationDays, 
        widget.plan.maxApplicationsPerDay,
        widget.plan.credits
      );
      
      // Refresh local profile state for both roles to be safe
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

  void _startPayment() {
    _processSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(widget.plan.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                       Text('₹${widget.plan.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                     ],
                   ),
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 16.0),
                     child: Divider(color: Color(0xFFE2E8F0)),
                   ),
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Total Value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                       Text('₹0 Due Now (Test)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                     ],
                   ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isProcessing 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Pay Securely', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
        ],
        ),
      ),
    );
  }
}
