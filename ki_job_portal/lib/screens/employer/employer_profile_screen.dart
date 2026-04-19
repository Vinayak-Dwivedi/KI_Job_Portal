import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';

class EmployerProfileScreen extends ConsumerWidget {
  const EmployerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employer = ref.watch(employerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    if (employer == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userPostsAsync = ref.watch(userPostsProvider(employer.uid));

    // Dynamic data
    final companyName = employer.companyName.isNotEmpty ? employer.companyName : 'Company Name';
    final bio = employer.bio;

    final rating = employer.rating > 0 ? employer.rating.toStringAsFixed(1) : 'New';
    final reviews = employer.reviewCount;
    final officeAddress = employer.officeAddress.isNotEmpty ? employer.officeAddress : 'Address not set';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/employer/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Background Gradient
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.1),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 100),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: employer.isVerified 
                              ? const LinearGradient(
                                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                            border: !employer.isVerified ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                            boxShadow: employer.isVerified 
                              ? [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.3), blurRadius: 15, spreadRadius: 2)] 
                              : [],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            backgroundImage: (employer.logoUrl != null && employer.logoUrl!.isNotEmpty)
                                ? NetworkImage(employer.logoUrl!)
                                : null,
                            child: (employer.logoUrl == null || employer.logoUrl!.isEmpty)
                                ? Text(
                                    companyName.isNotEmpty ? companyName.substring(0, 1).toUpperCase() : 'E',
                                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        if (employer.isVerified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                              ]
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          companyName,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (employer.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      employer.hirerSubType.toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(rating, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('•', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      Text('$reviews Ratings', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 12, color: theme.dividerColor.withOpacity(0.2)),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          officeAddress.isNotEmpty ? officeAddress.split(',').last.trim() : 'Location set',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Credits Box ──────────────────────────────────────────
                  ref.watch(userCreditsProvider).when(
                    data: (data) {
                      if (data == null) return const SizedBox.shrink();
                      final balance = int.tryParse(data['balance']?.toString() ?? '0') ?? 0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Recruitment Credits', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('$balance Credits Available', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/subscription'),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  
                  // ── Account Details Section ─────────────────────────────
                  _SectionHeader(title: 'Account Information', theme: theme),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildAccountRow(Icons.person_outline_rounded, 'Contact Person', employer.contactPersonName, theme),
                        const Divider(height: 24),
                        _buildAccountRow(Icons.business_rounded, 'Company Name', companyName, theme),
                        const Divider(height: 24),
                        _buildAccountRow(Icons.email_outlined, 'Email Address', employer.email ?? 'Not provided', theme),
                        const Divider(height: 24),
                        _buildAccountRow(Icons.phone_android_rounded, 'Phone Number', employer.phone, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/profile/employer/${employer.uid}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('View Public Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/edit-profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.outline),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // About Section
                  _SectionHeader(title: 'About Company', theme: theme),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    ),
                    child: Text(
                      bio.isNotEmpty ? bio : 'No description provided yet. Add your company profile to attract more professional workers.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Documents Section ──────────────────────────────────
                  _SectionHeader(title: 'Documents & Certifications', theme: theme),
                  const SizedBox(height: 12),
                  if (employer.documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                      ),
                      child: Center(
                        child: Text(
                          'No documents uploaded yet',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: employer.documents.length,
                      itemBuilder: (context, index) {
                        final doc = employer.documents[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  doc.type.toLowerCase() == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.name,
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Uploaded: ${doc.timestamp.day}/${doc.timestamp.month}/${doc.timestamp.year}',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined),
                                color: theme.colorScheme.primary,
                                onPressed: () async {
                                  final uri = Uri.parse(doc.url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),

                  // ── My Posts & Activity ──────────────────────────────
                  _SectionHeader(title: 'My Posts & Activity', theme: theme),
                  const SizedBox(height: 16),
                  userPostsAsync.when(
                    data: (posts) {
                      if (posts.isEmpty) {
                        return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('You haven\'t posted anything yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: posts[index]);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Center(child: Text('Error loading posts: $e', style: const TextStyle(color: Colors.red))),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
