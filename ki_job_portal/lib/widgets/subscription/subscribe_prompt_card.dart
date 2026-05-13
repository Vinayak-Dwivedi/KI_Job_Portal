import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscribePromptCard extends StatelessWidget {
  final String featureName;
  final String requiredTier;

  const SubscribePromptCard({
    super.key,
    required this.featureName,
    required this.requiredTier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF60A5FA), size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock $featureName',
            style: const TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 24, 
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Upgrade to ${requiredTier.toUpperCase()} to access this premium feature and accelerate your growth.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6), 
              fontSize: 15, 
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('Navigating to subscription plans...');
                GoRouter.of(context).push('/subscription-plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Upgrade Plan', 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
