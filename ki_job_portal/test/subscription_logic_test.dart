import 'package:flutter_test/flutter_test.dart';
import 'package:ki_job_portal/models/subscription_model.dart';
import 'package:ki_job_portal/models/subscription_plan_model.dart';

void main() {
  group('Subscription Logic Tests', () {
    test('Validity string for future date', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final sub = SubscriptionModel(
        userId: 'test',
        validUntil: futureDate,
      );
      expect(sub.validityString, contains('10 days remaining'));
    });

    test('Validity string for today', () {
      final today = DateTime.now();
      final sub = SubscriptionModel(
        userId: 'test',
        validUntil: today,
      );
      expect(sub.validityString, 'Expires today!');
    });

    test('Validity string for expired', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final sub = SubscriptionModel(
        userId: 'test',
        validUntil: pastDate,
        currentTier: 'pro',
      );
      expect(sub.validityString, 'Expired');
    });
  });

  group('Plan Comparison Logic', () {
    final starterPlan = SubscriptionPlan(
      id: 'starter',
      name: 'Starter',
      price: 299,
      durationDays: 30,
      features: [],
    );

    final proPlan = SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      price: 599,
      durationDays: 30,
      features: [],
    );

    test('Upgrade logic: Starter user looking at Pro', () {
      const currentPrice = 299;
      final sub = SubscriptionModel(currentTier: 'starter', validUntil: DateTime.now().add(const Duration(days: 1)), userId: 'u1');
      
      final bool isCurrent = sub.currentTier == proPlan.id && sub.isActive;
      final bool isUpgrade = sub.isActive && proPlan.price > currentPrice && !isCurrent;
      
      expect(isCurrent, false);
      expect(isUpgrade, true);
    });

    test('Included logic: Pro user looking at Starter', () {
      const currentPrice = 599;
      final sub = SubscriptionModel(currentTier: 'pro', validUntil: DateTime.now().add(const Duration(days: 1)), userId: 'u1');
      
      final bool isCurrent = sub.currentTier == starterPlan.id && sub.isActive;
      final bool isDowngradeOrSame = sub.isActive && starterPlan.price <= currentPrice && !isCurrent;
      
      expect(isCurrent, false);
      expect(isDowngradeOrSame, true);
    });
  });
}
