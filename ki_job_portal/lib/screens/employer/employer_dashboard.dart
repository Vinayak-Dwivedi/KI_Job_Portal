import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/utils/profile_utils.dart';
import '../../core/theme/app_colors.dart';

class EmployerDashboardScreen extends ConsumerStatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  ConsumerState<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends ConsumerState<EmployerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final currentProfile = ref.read(employerProvider);
      if (auth != null && currentProfile == null) {
        ref.read(employerProvider.notifier).loadProfile(auth.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final employer = ref.watch(employerProvider);
    final feedAsyncValue = ref.watch(unifiedFeedProvider);
    final employerJobsAsync = ref.watch(employerJobsProvider(employer?.uid ?? ""));
    final theme = Theme.of(context);

    if (employer == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = ref.read(authProvider);
            if (auth != null) await ref.read(employerProvider.notifier).loadProfile(auth.uid);
          },
          backgroundColor: theme.scaffoldBackgroundColor,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                /// ── Header ───────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/public-profile/${employer.uid}/employer'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)]),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: theme.cardColor,
                          backgroundImage: (employer.profilePhotoUrl != null && employer.profilePhotoUrl!.isNotEmpty)
                              ? NetworkImage(employer.profilePhotoUrl!)
                              : null,
                          child: (employer.profilePhotoUrl == null || employer.profilePhotoUrl!.isEmpty)
                              ? Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${employer.companyName.isNotEmpty ? employer.companyName : employer.contactName}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Employer • ${employer.hirerSubType}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    _buildIconButton(Icons.search_rounded, theme, () => context.push('/search')),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final announcementsAsync = ref.watch(systemAnnouncementsProvider);
                        return Stack(
                          children: [
                            _buildIconButton(Icons.notifications_none_rounded, theme, () => context.push('/announcements')),
                            announcementsAsync.when(
                              data: (list) => list.isNotEmpty 
                                ? Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                /// ── Quick Actions Grid ──────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _QuickActionTile(
                      label: 'Post a Job',
                      icon: Icons.add_business_rounded,
                      color: const Color(0xFF2563EB),
                      theme: theme,
                      onTap: () => context.push('/employer/create-job'),
                    ),
                    _QuickActionTile(
                      label: 'Create Post',
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF059669),
                      theme: theme,
                      onTap: () => context.push('/feed/create'),
                    ),
                    _QuickActionTile(
                      label: 'Find Workers',
                      icon: Icons.person_search_rounded,
                      color: const Color(0xFFEA580C),
                      theme: theme,
                      onTap: () => context.go('/employer/workers'),
                    ),
                    _QuickActionTile(
                      label: 'Job Postings',
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFF1E3A8A),
                      theme: theme,
                      onTap: () => context.go('/employer/my-jobs'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                /// ── Insights ───────────────────────────────
                Text(
                  'Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Credits',
                        value: '${employer.credits}',
                        progress: 1.0,
                        color: const Color(0xFFFBBF24),
                        theme: theme,
                        onTap: () => context.push('/subscription'),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        label: 'Active Jobs',
                        value: employerJobsAsync.when(
                          data: (jobs) => jobs.length.toString().padLeft(2, '0'),
                          loading: () => '..',
                          error: (_, __) => '00',
                        ),
                        progress: 0.7,
                        color: const Color(0xFF2563EB),
                        theme: theme,
                        onTap: () => context.go('/employer/my-jobs'),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        label: 'Strength',
                        value: '${ProfileUtils.calculateStrength(
                          name: employer.contactName,
                          phone: employer.phone,
                          email: employer.email,
                          bio: employer.bio,
                          location: employer.officeAddress,
                          businessType: employer.hirerSubType,
                          isVerified: true,
                          isWorker: false,
                        ).toInt()}%',
                        progress: 0.8,
                        color: const Color(0xFF059669),
                        theme: theme,
                        onTap: () => context.push('/edit-profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                /// ── Recent Updates ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Updates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                feedAsyncValue.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No updates available.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length > 10 ? 10 : posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: posts[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, ThemeData theme, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
