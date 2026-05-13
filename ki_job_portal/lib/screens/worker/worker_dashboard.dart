import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/worker_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banner_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/common/achievement_badge.dart';
import '../../core/utils/profile_utils.dart';
import '../../core/theme/app_colors.dart';
import '../common/notifications_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/feed/feed_filter_sheet.dart';


class WorkerHomeFeed extends ConsumerStatefulWidget {
  const WorkerHomeFeed({super.key});

  @override
  ConsumerState<WorkerHomeFeed> createState() => _WorkerHomeFeedState();
}

class _WorkerHomeFeedState extends ConsumerState<WorkerHomeFeed> {
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
      final currentProfile = ref.read(workerProvider);
      if (auth != null && currentProfile == null) {
        ref.read(workerProvider.notifier).loadProfile(auth.uid);
      }
      _checkHighlightedPost();
    });
  }

  void _checkHighlightedPost() {
    final postId = ref.read(highlightedPostIdProvider);
    if (postId != null) {
      // Small delay to ensure feed is loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final feed = ref.read(unifiedFeedProvider).value;
        if (feed != null) {
          final index = feed.indexWhere((p) => p['id'] == postId);
          if (index != -1) {
            // Estimate position: AppBar (~200) + Header sections (~600) + PostCards
            // This is a rough jump, better than nothing
            final targetOffset = 800.0 + (index * 450.0);
            _scrollController.animateTo(
              targetOffset,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOutCubic,
            );
            // Clear the highlight after scrolling
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

    final worker = ref.watch(workerProvider);
    final auth = ref.watch(authProvider);
    final feedAsyncValue = ref.watch(unifiedFeedProvider);
    final filteredFeed = ref.watch(filteredUnifiedFeedProvider);
    final currentFilter = ref.watch(feedTypeFilterProvider);
    final appliedJobs = ref.watch(workerAppliedJobsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlow(AppColors.primary.withOpacity(0.1), 300),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _buildGlow(const Color(0xFF10B981).withOpacity(0.05), 400),
          ),

          RefreshIndicator(
            onRefresh: () async {
              final auth = ref.read(authProvider);
              if (auth != null) {
                await ref.read(workerProvider.notifier).loadProfile(auth.uid);
              }
            },
            color: AppColors.primary,
            backgroundColor: theme.cardColor,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Modern Neon AppBar ──────────────────────────
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'KI',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
                                onPressed: () => context.push('/search'),
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                                  return Badge(
                                    label: unreadCount > 0 ? Text('$unreadCount') : null,
                                    isLabelVisible: unreadCount > 0,
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurfaceVariant, size: 24),
                                      onPressed: () => context.push('/notifications'),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
                                onPressed: () {
                                  debugPrint('Navigating to chats...');
                                  context.push('/chats');
                                },
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => context.push('/profile/worker/${auth?.uid}'),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white10,
                                  backgroundImage: (worker?.profilePhotoUrl != null && worker!.profilePhotoUrl!.isNotEmpty) 
                                      ? NetworkImage(worker.profilePhotoUrl!) 
                                      : null,
                                  child: (worker?.profilePhotoUrl == null) 
                                      ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 20) 
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Badges
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.namaste}, ${worker?.name.split(' ')[0] ?? AppLocalizations.of(context)!.karigar}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    if (worker?.isVerified ?? false)
                                      const AchievementBadge(type: BadgeType.verified),
                                    if (worker?.isElite ?? false)
                                      const AchievementBadge(type: BadgeType.elite),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.yourNextMasterworkIsWaiting,
                              style: GoogleFonts.plusJakartaSans(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
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

                      // Stats row (Neon Cards)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _NeonStatCard(
                                value: appliedJobs.when(
                                  data: (jobs) => jobs.length.toString(),
                                  loading: () => '..',
                                  error: (_, __) => '0',
                                ),
                                label: AppLocalizations.of(context)!.activeJobs,
                                color: AppColors.primary,
                                icon: Icons.work_outline_rounded,
                                onTap: () => context.push('/worker/jobs'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NeonStatCard(
                                value: '${worker?.credits ?? 0}',
                                label: AppLocalizations.of(context)!.credits,
                                color: const Color(0xFFFBBF24),
                                icon: Icons.toll_rounded,
                                onTap: () => context.push('/buy-credits'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NeonStatCard(
                                value: '${ProfileUtils.calculateStrength(
                                  name: worker?.name ?? "",
                                  phone: worker?.phone ?? "",
                                  email: worker?.email,
                                  bio: worker?.bio,
                                  location: worker?.location,
                                  skills: worker?.skills,
                                  isVerified: worker?.isVerified ?? false,
                                  isWorker: true,
                                ).toInt()}%',
                                label: AppLocalizations.of(context)!.strength,
                                color: const Color(0xFF10B981),
                                icon: Icons.analytics_outlined,
                                onTap: () => context.push('/edit-profile'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Promotional Banner
                      Consumer(
                        builder: (context, ref, child) {
                          final bannerAsync = ref.watch(activeBannerProvider);
                          return bannerAsync.when(
                            data: (banner) {
                              if (banner == null || !banner.isActive) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (banner.targetRoute != null && banner.targetRoute!.isNotEmpty) {
                                      context.push(banner.targetRoute!);
                                    } else if (banner.headline?.toLowerCase().contains('verify') ?? false) {
                                      context.push('/settings/verification');
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 7,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: banner.imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: theme.cardColor,
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: theme.cardColor,
                                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                            ),
                                          ),
                                          // Gradient overlay for text readability
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Text content
                                          Positioned(
                                            left: 16,
                                            right: 16,
                                            bottom: 14,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (banner.headline != null)
                                                  Text(banner.headline!, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                                if (banner.subhead != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(banner.subhead!, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),

                      // Feed Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.recommendedForYou,
                                      style: GoogleFonts.plusJakartaSans(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const FeedFilterSheet(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                AppLocalizations.of(context)!.viewAll,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),

                      ),
                    ],
                  ),
                ),

                feedAsyncValue.when(
                  data: (_) {
                    if (filteredFeed.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(AppLocalizations.of(context)!.noNewJobsAtTheMoment, style: GoogleFonts.plusJakartaSans(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PostCard(post: filteredFeed[index]),
                        childCount: filteredFeed.length,
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
        ],
      ),
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

class _NeonStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _NeonStatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.05) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.3)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
