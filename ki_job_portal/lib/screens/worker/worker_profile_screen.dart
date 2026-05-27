import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/worker_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/profile/profile_charts.dart';
import '../../widgets/common/user_credits_widget.dart';
import '../../widgets/profile/profile_boost_dialog.dart';
import '../../l10n/app_localizations.dart';


class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(workerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    if (worker == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userPostsAsync = ref.watch(userPostsProvider(worker.uid));
    final appliedJobs = ref.watch(workerAppliedJobsProvider);

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                leading: context.canPop()
                    ? IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                        onPressed: () => context.pop(),
                      )
                    : null,
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
                                  gradient: worker.isVerified 
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                  border: !worker.isVerified ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                                  boxShadow: worker.isVerified 
                                    ? [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.3), blurRadius: 15, spreadRadius: 2)] 
                                    : [],
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: theme.colorScheme.surfaceVariant,
                                  backgroundImage: (worker.profilePhotoUrl != null && worker.profilePhotoUrl!.isNotEmpty)
                                      ? NetworkImage(worker.profilePhotoUrl!)
                                      : null,
                                  child: (worker.profilePhotoUrl == null || worker.profilePhotoUrl!.isEmpty)
                                      ? Icon(Icons.person, size: 45, color: theme.colorScheme.onSurfaceVariant)
                                      : null,
                                ),
                              ),
                              if (worker.isVerified)
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
                              Text(
                                worker.name,
                                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                              if (worker.isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'New',
                                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Text('•', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(width: 4),
                              Text('${worker.experience} ${AppLocalizations.of(context)!.experience}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                              if (worker.dateOfBirth != null) ...[
                                const SizedBox(width: 4),
                                Text('•', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                const SizedBox(width: 4),
                                Text('${_calculateAge(worker.dateOfBirth!)} ${AppLocalizations.of(context)!.years}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.push('/edit-profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(AppLocalizations.of(context)!.editProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                final profileUrl = 'https://kijobportal.web.app/profile/worker/${worker.uid}';
                                Share.share('Check out ${worker.name}\'s profile on KI Job Portal: $profileUrl');
                              },
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (!worker.isVerified) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/settings/verification'),
                            icon: const Icon(Icons.verified_user_outlined, color: Colors.blue),
                            label: const Text('GET VERIFIED', style: TextStyle(fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              foregroundColor: Colors.blue[800],
                              side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      if (worker.isFeatured == false) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _boostProfile(context, ref, worker.uid),
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
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.tabAbout.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabStats.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabPosts.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabSaved.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabApplied.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabMyRequests.toUpperCase()),
                      Tab(text: AppLocalizations.of(context)!.tabVisitors.toUpperCase()),
                    ],
                  ),
                  theme.scaffoldBackgroundColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildAboutTab(context, worker, theme, ref),
              _buildStatsTab(worker.uid),
              _buildPostsTab(context, userPostsAsync, theme, false),
              _buildSavedTab(context, ref, theme),
              _buildAppliedTab(context, appliedJobs, theme),
              _buildPostsTab(context, userPostsAsync, theme, true), //Availability Only
              _buildVisitorsTab(worker.uid, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ProfileCharts(uid: uid, isOwner: true),
    );
  }

  Widget _buildAboutTab(BuildContext context, worker, ThemeData theme, WidgetRef ref) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💳 CREDITS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.availableCredits,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const UserCreditsWidget(
                          fontSize: 32,
                          iconSize: 32,
                          color: Colors.white,
                          showLabel: false,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push('/profile/credits'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.viewTransactionHistory,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push('/profile/visitors'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.whoViewedMyProfile,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _sectionHeader(AppLocalizations.of(context)!.expertiseAndBio, theme),
          const SizedBox(height: 12),
          Text(
            worker.bio.isNotEmpty ? worker.bio : AppLocalizations.of(context)!.noBio,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (worker.skills as List).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Text(s, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
          const SizedBox(height: 32),

          _sectionHeader(AppLocalizations.of(context)!.contactInformation, theme),
          const SizedBox(height: 12),
          _contactTile(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, 
            worker.subLocation != null && worker.subLocation!.isNotEmpty 
              ? '${worker.subLocation}, ${worker.location}' 
              : (worker.location.isNotEmpty ? worker.location : AppLocalizations.of(context)!.notSet), 
            theme, context),
          if (worker.referralCode != null && worker.referralCode!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _contactTile(Icons.qr_code_rounded, AppLocalizations.of(context)!.referralCodeLabel, 
              worker.referralCode!, 
              theme, context,
              isReferral: true,
            ),
          ],
          const SizedBox(height: 32),

          _sectionHeader(AppLocalizations.of(context)!.portfolioDocuments, theme),
          const SizedBox(height: 16),
          if (worker.documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.noDocumentsUploadedYet,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: worker.documents.length,
              itemBuilder: (context, index) {
                final doc = worker.documents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                            if (doc.category != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(doc.category!, style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Uploaded on ${_formatDate(doc.timestamp)}',
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
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch document')),
                              );
                            }
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildPostsTab(BuildContext context, AsyncValue<List<Map<String, dynamic>>> postsAsync, ThemeData theme, bool availabilityOnly) {
    return postsAsync.when(
      data: (posts) {
        final filtered = availabilityOnly 
            ? posts.where((p) => p['isAvailabilityPost'] == true).toList()
            : posts.where((p) => p['isAvailabilityPost'] != true).toList();
            
        if (filtered.isEmpty) {
          return Center(child: Text(availabilityOnly ? AppLocalizations.of(context)!.noJobRequestsYet : AppLocalizations.of(context)!.noPostsYet, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: filtered.length,
          itemBuilder: (context, index) => PostCard(post: filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAppliedTab(BuildContext context, AsyncValue<List<Map<String, dynamic>>> jobsAsync, ThemeData theme) {
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noApplicationsYet, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
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

  Widget _buildSavedTab(BuildContext context, WidgetRef ref, ThemeData theme) {
    final savedJobsAsync = ref.watch(savedJobsProvider);
    return savedJobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noSavedPostsYet, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
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

  Widget _sectionHeader(String title, ThemeData theme) {
    return Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5));
  }

  Widget _contactTile(IconData icon, String label, String value, ThemeData theme, BuildContext context, {bool isReferral = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isReferral)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.referralCodeCopied)),
                );
              },
              color: theme.colorScheme.primary,
            ),
        ],
      ),
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
    final worker = ref.read(workerProvider);
    if (worker == null) return;

    showDialog(
      context: context,
      builder: (ctx) => ProfileBoostDialog(
        currentCredits: worker.credits,
        onConfirm: (days) async {
          Navigator.pop(ctx);
          try {
            await ref.read(workerProvider.notifier).boostProfile(days);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Profile boosted successfully! 🚀',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981), // AppColors.secondary
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
