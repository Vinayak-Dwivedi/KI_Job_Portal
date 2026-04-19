import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';

class VerificationSuccessScreen extends ConsumerWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isEmployer = user?.role == 'employer';

    return Scaffold(
      backgroundColor: const Color(0xFF050A15), // Deep dark navy 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // ── Central Check Icon Graphic ──────────────────
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF111E2E), // Subtle dark aura
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF86EFAC), // Bright green
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF050A15),
                        size: 40,
                        weight: 800,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              ),
              
              const SizedBox(height: 32),
              
              // ── Heading & Subtitle ────────────────────────
              const Text(
                'Verification\nSuccessful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 16),
              
              Text(
                isEmployer
                    ? 'You can now post premium jobs\nand hire high-value workers.'
                    : 'You can now apply for premium jobs\nand high-value projects.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 500.ms).moveY(begin: 10, end: 0),

              const SizedBox(height: 48),

              // ── Identity Confirmed Card ───────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C2B), // Dark surface
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF1E293B),
                          child: const Icon(Icons.person, color: Colors.grey, size: 28),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF151C2B),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identity Confirmed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B).withAlpha(150),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF34D399), size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  isEmployer ? 'VERIFIED EMPLOYER' : 'VERIFIED WORKER',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isEmployer
                                ? 'Badge added to your public profile. Workers will see this on all your job posts.'
                                : 'Badge added to your public profile. Clients will see this on all your applications.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

              const Spacer(),

              // ── Buttons ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isEmployer) {
                      context.go('/employer/dashboard');
                    } else {
                      context.go('/worker/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8), // Primary blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Go to Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    if (isEmployer) {
                      context.go('/employer/profile');
                    } else {
                      context.go('/worker/profile');
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withAlpha(10)),
                    ),
                  ),
                  child: const Text(
                    'View My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1.seconds),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
