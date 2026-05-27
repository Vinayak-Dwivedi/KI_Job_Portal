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

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  Map<String, dynamic>? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ReferralService.getReferralSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    
    // Fetch referral code and stats from the correct profile provider
    String? code;
    int referralCount = 0;
    int totalEarned = 0;
    
    if (user?.role == 'worker') {
      final worker = ref.watch(workerProvider);
      code = worker?.referralCode;
      referralCount = worker?.referralCount ?? 0;
      totalEarned = worker?.totalReferralCredits ?? 0;
    } else if (user?.role == 'employer') {
      final employer = ref.watch(employerProvider);
      code = employer?.referralCode;
      referralCount = employer?.referralCount ?? 0;
      totalEarned = employer?.totalReferralCredits ?? 0;
    }
    
    final referralCode = code ?? '------';
    final bonus = _settings?['bonusPerReferral'] ?? 100;
    final shareLink = 'https://kijobs.app/ref/${user?.uid ?? "error"}';

    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              'Share your referral link with friends. When they join and sign up, you get $bonus credits instantly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // STATS ROW
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context, 
                    'Successful Referrals', 
                    referralCount.toString(), 
                    Icons.people_alt_rounded,
                    Colors.blue
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context, 
                    'Total Credits Earned', 
                    totalEarned.toString(), 
                    Icons.account_balance_wallet_rounded,
                    Colors.green
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 🎫 REFERRAL LINK BOX
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
                    'YOUR REFERRAL LINK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shareLink,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Join me on KI Job Portal! Use my link to get started and earn credits. Download now: $shareLink',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('SHARE LINK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                      final reward = ref['bonusAmount'] ?? ref['rewardAmount'] ?? 0;
                      final name = ref['referredName'] ?? 'New User';
                      
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Text(
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
