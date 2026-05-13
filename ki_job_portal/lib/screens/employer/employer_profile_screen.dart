import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/profile/profile_charts.dart';
import '../../widgets/common/user_credits_widget.dart';
import '../../widgets/profile/profile_boost_dialog.dart';
import '../../l10n/app_localizations.dart';

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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
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
                    icon: Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      final profileUrl = 'https://kijobportal.web.app/profile/employer/${employer.uid}';
                      Share.share('Check out ${employer.companyName.isNotEmpty ? employer.companyName : employer.contactPersonName}\'s profile on KI Job Portal: $profileUrl');
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
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
                                  radius: 45,
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
                                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (employer.isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
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
                          if (employer.dateOfBirth != null) ...[
                            const SizedBox(width: 4),
                            Text('•', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 4),
                            Text('${_calculateAge(employer.dateOfBirth!)} Yrs', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (employer.isFeatured == false) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _boostProfile(context, ref, employer.uid),
                            icon: const Icon(Icons.bolt_rounded, color: Colors.amber),
                            label: const Text('BOOST PROFILE — 80 CREDITS', style: TextStyle(fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.withOpacity(0.1),
                              foregroundColor: Colors.amber[800],
                              side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
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
                                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(AppLocalizations.of(context)!.recruitmentCredits, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          const UserCreditsWidget(
                                            fontSize: 24,
                                            iconSize: 28,
                                            showLabel: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/buy-credits'),
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
                                const SizedBox(height: 12),
                                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => context.push('/profile/credits'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.viewTransactionHistory,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    tabs: const [
                      Tab(text: "ABOUT"),
                      Tab(text: "STATS"),
                      Tab(text: "POSTS"),
                      Tab(text: "SAVED"),
                      Tab(text: "VISITORS"),
                    ],
                  ),
                  theme.scaffoldBackgroundColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildAboutTab(employer, companyName, officeAddress, bio, theme, context),
              SingleChildScrollView(child: ProfileCharts(uid: employer.uid, isOwner: true)),
              _buildPostsTab(userPostsAsync, theme),
              _buildSavedTab(ref, theme),
              _buildVisitorsTab(employer.uid, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(employer, String companyName, String officeAddress, String bio, ThemeData theme, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                _buildAccountRow(Icons.person_outline_rounded, 'Contact Person', employer.contactPersonName, theme, context),
                const Divider(height: 24),
                _buildAccountRow(Icons.business_rounded, 'Company Name', companyName, theme, context),
                const Divider(height: 24),
                _buildAccountRow(Icons.email_outlined, 'Email Address', employer.email ?? 'Not provided', theme, context),
                const Divider(height: 24),
                _buildAccountRow(Icons.phone_android_rounded, 'Phone Number', employer.phone, theme, context),
                const Divider(height: 24),
                _buildAccountRow(Icons.location_on_outlined, 'Office Location', 
                  employer.subLocation != null && employer.subLocation!.isNotEmpty 
                    ? '${employer.subLocation}, ${officeAddress}' 
                    : officeAddress, 
                  theme, context),
                if (employer.referralCode != null && employer.referralCode!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildAccountRow(Icons.qr_code_rounded, 'Referral Code', 
                    employer.referralCode!, 
                    theme, context,
                    isReferral: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                child: Text('No documents uploaded yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
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
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(doc.type.toLowerCase() == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (doc.category != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(doc.category!, style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text('Uploaded: ${doc.timestamp.day}/${doc.timestamp.month}/${doc.timestamp.year}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPostsTab(AsyncValue<List<Map<String, dynamic>>> postsAsync, ThemeData theme) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(child: Text('You haven\'t posted anything yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSavedTab(WidgetRef ref, ThemeData theme) {
    final savedJobsAsync = ref.watch(savedJobsProvider);
    return savedJobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(child: Text('No saved posts yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: jobs.length,
          itemBuilder: (context, index) => PostCard(post: jobs[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAccountRow(IconData icon, String label, String value, ThemeData theme, BuildContext context, {bool isReferral = false}) {
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (isReferral)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referral code copied!')),
              );
            },
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildVisitorsTab(String uid, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('visitors')
          .orderBy('viewedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('No visitors yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'A visitor';
            final photo = data['photo'] ?? '';
            final visitorUid = data['uid'] ?? '';
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: const Text('Recently visited', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => context.push('/profile/worker/$visitorUid'),
            );
          },
        );
      },
    );
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _boostProfile(BuildContext context, WidgetRef ref, String uid) async {
    final employer = ref.read(employerProvider);
    if (employer == null) return;

    showDialog(
      context: context,
      builder: (ctx) => ProfileBoostDialog(
        currentCredits: employer.credits,
        onConfirm: (days) async {
          Navigator.pop(ctx);
          try {
            await ref.read(employerProvider.notifier).boostProfile(days);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile boosted successfully! 🚀'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
