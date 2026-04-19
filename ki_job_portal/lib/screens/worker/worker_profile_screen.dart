import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/worker_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../widgets/feed/post_card.dart';


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
      length: 4,
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
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  onPressed: () => context.pop(),
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
                              Text('${worker.experience} Exp', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
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
                  child: Row(
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
                          child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          onPressed: () {},
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    tabs: const [
                      Tab(text: "ABOUT"),
                      Tab(text: "POSTS"),
                      Tab(text: "APPLIED"),
                      Tab(text: "MY REQUESTS"),
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
              _buildPostsTab(userPostsAsync, theme, false),
              _buildAppliedTab(appliedJobs, theme),
              _buildPostsTab(userPostsAsync, theme, true), //Availability Only
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, worker, ThemeData theme, WidgetRef ref) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credits Card
          ref.watch(userCreditsProvider).when(
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              final balance = int.tryParse(data['balance']?.toString() ?? '0') ?? 0;
              return GestureDetector(
                onTap: () => context.push('/worker/earnings'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wallet, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account Credits',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('$balance Credits',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Tap to view history →',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/subscription'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('TOP UP'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          _sectionHeader('Expertise & Bio', theme),
          const SizedBox(height: 12),
          Text(
            worker.bio.isNotEmpty ? worker.bio : 'No bio provided.',
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

          _sectionHeader('Contact Information', theme),
          const SizedBox(height: 12),
          _contactTile(Icons.location_on_outlined, 'Location', worker.location.isNotEmpty ? worker.location : 'Not set', theme),
          const SizedBox(height: 32),

          _sectionHeader('Documents & Certifications', theme),
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
                      'No documents uploaded yet',
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

  Widget _buildPostsTab(AsyncValue<List<Map<String, dynamic>>> postsAsync, ThemeData theme, bool availabilityOnly) {
    return postsAsync.when(
      data: (posts) {
        final filtered = availabilityOnly 
            ? posts.where((p) => p['isAvailabilityPost'] == true).toList()
            : posts.where((p) => p['isAvailabilityPost'] != true).toList();
            
        if (filtered.isEmpty) {
          return Center(child: Text(availabilityOnly ? 'No job requests yet' : 'No posts yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
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

  Widget _buildAppliedTab(AsyncValue<List<Map<String, dynamic>>> jobsAsync, ThemeData theme) {
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(child: Text('You haven\'t applied to any jobs yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
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

  Widget _contactTile(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
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
