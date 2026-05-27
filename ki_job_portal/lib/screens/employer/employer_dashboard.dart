import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/utils/profile_utils.dart';
import '../../core/theme/app_colors.dart';
import '../common/notifications_screen.dart';
import '../../l10n/app_localizations.dart';

class EmployerDashboardScreen extends ConsumerStatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  ConsumerState<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends ConsumerState<EmployerDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final currentProfile = ref.read(employerProvider);
      if (auth != null && currentProfile == null) {
        ref.read(employerProvider.notifier).loadProfile(auth.uid);
      }
      _checkHighlightedPost();
    });
  }

  void _checkHighlightedPost() {
    final postId = ref.read(highlightedPostIdProvider);
    if (postId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final feed = ref.read(unifiedFeedProvider).value;
        if (feed != null) {
          final index = feed.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            // Estimate position: AppBar (~100) + Actions (~200) + Insights (~200)
            final targetOffset = 500.0 + (index * 450.0);
            _scrollController.animateTo(
              targetOffset,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOutCubic,
            );
            ref.read(highlightedPostIdProvider.notifier).state = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Listen for highlight changes even if screen is already built
    ref.listen(highlightedPostIdProvider, (prev, next) {
      if (next != null) {
        _checkHighlightedPost();
      }
    });

    final employer = ref.watch(employerProvider);
    final feedAsyncValue = ref.watch(unifiedFeedProvider);
    final filteredFeed = ref.watch(filteredUnifiedFeedProvider);
    final currentFilter = ref.watch(feedTypeFilterProvider);
    final employerJobsAsync = ref.watch(employerJobsProvider(employer?.uid ?? ""));

    if (employer == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlow(AppColors.primary.withOpacity(0.08), 350),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: _buildGlow(const Color(0xFF10B981).withOpacity(0.05), 400),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final auth = ref.read(authProvider);
                if (auth != null) await ref.read(employerProvider.notifier).loadProfile(auth.uid);
              },
              backgroundColor: AppColors.darkSurfaceContainer,
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Modern AppBar ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/profile/employer/${employer.uid}'),
                            child: Hero(
                              tag: 'profile_pic',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white10,
                                  backgroundImage: (employer.profilePhotoUrl != null && employer.profilePhotoUrl!.isNotEmpty)
                                      ? NetworkImage(employer.profilePhotoUrl!)
                                      : null,
                                  child: (employer.profilePhotoUrl == null || employer.profilePhotoUrl!.isEmpty)
                                      ? Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant, size: 20)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.namaste}, ${employer.contactName.split(' ')[0]}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${AppLocalizations.of(context)!.hirer} • ${employer.hirerSubType}',
                                  style: GoogleFonts.plusJakartaSans(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderIcon(context, Icons.search_rounded, () => context.push('/search')),
                          const SizedBox(width: 12),
                          Consumer(
                            builder: (context, ref, child) {
                              final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                              return _buildHeaderIcon(
                                context,
                                Icons.notifications_outlined,
                                () => context.push('/notifications'),
                                badgeCount: unreadCount,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderIcon(context, Icons.chat_bubble_outline_rounded, () {
                            debugPrint('Navigating to chats...');
                            context.push('/chats');
                          }),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Actions ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _ActionCard(
                            label: AppLocalizations.of(context)!.postJob,
                            icon: Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                            onTap: () => context.push('/employer/create-job'),
                          ),
                          _ActionCard(
                            label: AppLocalizations.of(context)!.findPros,
                            icon: Icons.person_search_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => context.go('/employer/workers'),
                          ),
                          _ActionCard(
                            label: AppLocalizations.of(context)!.myJobs,
                            icon: Icons.list_alt_rounded,
                            color: const Color(0xFFFBBF24),
                            onTap: () => context.go('/employer/my-jobs'),
                          ),
                          _ActionCard(
                            label: AppLocalizations.of(context)!.community,
                            icon: Icons.groups_2_rounded,
                            color: const Color(0xFFEC4899),
                            onTap: () {
                              ref.read(feedTypeFilterProvider.notifier).state = FeedType.community;
                              _scrollController.animateTo(
                                520.0,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                          ),
                          _ActionCard(
                            label: AppLocalizations.of(context)!.subscriptionPlans,
                            icon: Icons.card_membership_rounded,
                            color: Colors.deepPurpleAccent,
                            onTap: () => context.push('/subscription-plans'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Business Insights ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Text(
                        AppLocalizations.of(context)!.businessInsights,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _NeonStatCard(
                            label: AppLocalizations.of(context)!.credits,
                            value: '${employer.credits}',
                            icon: Icons.toll_rounded,
                            color: const Color(0xFFFBBF24),
                            onTap: () => context.push('/buy-credits'),
                          ),
                          const SizedBox(width: 16),
                          _NeonStatCard(
                            label: AppLocalizations.of(context)!.activeJobs,
                            value: employerJobsAsync.when(
                              data: (jobs) => jobs.length.toString(),
                              loading: () => '..',
                              error: (_, __) => '0',
                            ),
                            icon: Icons.work_outline_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go('/employer/my-jobs'),
                          ),
                          const SizedBox(width: 16),
                          _NeonStatCard(
                            label: AppLocalizations.of(context)!.strength,
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
                            icon: Icons.analytics_outlined,
                            color: const Color(0xFF10B981),
                            onTap: () => context.push('/edit-profile'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Recent Feed ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.karigarFeed,
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 16),
                          // 🚀 Feed Filters
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                _buildFilterChip('All', FeedType.all, currentFilter),
                                _buildFilterChip('Jobs', FeedType.jobs, currentFilter),
                                _buildFilterChip('Community', FeedType.community, currentFilter),
                                _buildFilterChip('Events', FeedType.events, currentFilter),
                                _buildFilterChip('Work Profile', FeedType.availability, currentFilter),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  feedAsyncValue.when(
                    data: (_) {
                      if (filteredFeed.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.noRecentUpdates, style: GoogleFonts.plusJakartaSans(color: theme.colorScheme.onSurfaceVariant)),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PostCard(post: filteredFeed[index]),
                          childCount: filteredFeed.length > 10 ? 10 : filteredFeed.length,
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                    error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red)))),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, FeedType type, FeedType current) {
    final isSelected = type == current;
    return GestureDetector(
      onTap: () => ref.read(feedTypeFilterProvider.notifier).state = type,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NeonStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _NeonStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.05) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.25)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

