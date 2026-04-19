import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<Map<String, dynamic>> _docs = [
    {'name': 'Aadhar Card', 'status': 'Verified', 'icon': Icons.badge_outlined, 'color': AppColors.secondary},
    {'name': 'PAN Card', 'status': 'Pending', 'icon': Icons.credit_card_rounded, 'color': Colors.amber},
    {'name': 'Trade Certificate', 'status': 'Not Uploaded', 'icon': Icons.description_outlined, 'color': AppColors.outlineVariant},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final isVerified = user?.isVerified ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verification', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVerified 
                      ? [AppColors.secondary, const Color(0xFF059669)] 
                      : [AppColors.primary, const Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isVerified ? AppColors.secondary : AppColors.primary).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVerified ? 'Profile Verified' : 'Verification Under Review',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified 
                        ? 'Your identity has been confirmed. You have full access to all features.' 
                        : 'Submit your documents to unlock higher credit limits and premium features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Verification Documents', theme),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = _docs[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: doc['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(doc['icon'], color: doc['color'], size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(doc['status'], style: TextStyle(color: doc['color'], fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (doc['status'] == 'Not Uploaded')
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.file_upload_outlined, color: theme.colorScheme.primary),
                        )
                      else if (doc['status'] == 'Verified')
                         const Icon(Icons.check_circle, color: AppColors.secondary, size: 20)
                      else
                        const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            
            if (!isVerified)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Upload New Document', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
