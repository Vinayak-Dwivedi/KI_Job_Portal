import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/referral_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../core/theme/app_colors.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    
    // Fetch referral code from the correct profile provider
    String? code;
    if (user?.role == 'worker') {
      code = ref.watch(workerProvider)?.referralCode;
    } else if (user?.role == 'employer') {
      code = ref.watch(employerProvider)?.referralCode;
    }
    
    final referralCode = code ?? '------';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🎁 HERO ILLUSTRATION/ICON
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.card_giftcard_rounded, size: 80, color: AppColors.primary),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            
            Text(
              'Invite Friends & Earn Credits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Share your referral code with friends. When they join, you get 10 credits instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 🎫 REFERRAL CODE BOX
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR REFERRAL CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Join me on KI Job Portal! Use my referral code $referralCode to get started. Download now: https://kijobportal.web.app',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('SHARE CODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 48),
            
            // 📜 REFERRAL HISTORY
            Row(
              children: [
                Text(
                  'REFERRAL HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.history_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 16),
            
            if (user != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ReferralService.getReferralHistory(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final referrals = snapshot.data ?? [];
                  
                  if (referrals.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No referrals yet',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: referrals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ref = referrals[index];
                      final reward = ref['rewardAmount'] ?? 0;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_add_rounded, color: Colors.green, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New User Joined',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'Successful Referral',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+$reward cr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
