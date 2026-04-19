import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_provider.dart';
import 'subscribe_prompt_card.dart';

class SubscriptionGate extends ConsumerWidget {
  final Widget child;
  final String requiredTier; // 'pro', 'elite'
  final String featureName;

  const SubscriptionGate({
    super.key,
    required this.child,
    this.requiredTier = 'pro',
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return subAsync.when(
      data: (sub) {
        bool hasAccess = false;
        if (sub != null && sub.isActive) {
          if (requiredTier == 'elite') {
            hasAccess = sub.currentTier == 'elite';
          } else if (requiredTier == 'pro') {
            hasAccess = sub.currentTier == 'pro' || sub.currentTier == 'elite';
          }
        }

        if (hasAccess) return child;

        // If not, blur the child and overlay prompt
        return Stack(
          children: [
            // The restricted content blurred
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Opacity(
                  opacity: 0.5,
                  child: IgnorePointer(child: child),
                ),
              ),
            ),
            // The Prompt Card
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SubscribePromptCard(
                    featureName: featureName,
                    requiredTier: requiredTier,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Stack(
        children: [
           Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (e, st) => child, // Fail open if error maybe, or mock behavior
    );
  }
}
