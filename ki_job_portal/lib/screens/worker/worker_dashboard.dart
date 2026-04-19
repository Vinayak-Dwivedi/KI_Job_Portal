import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/worker_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banner_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/utils/profile_utils.dart';
import '../../core/theme/app_colors.dart';

class WorkerHomeFeed extends ConsumerStatefulWidget {
  const WorkerHomeFeed({super.key});

  @override
  ConsumerState<WorkerHomeFeed> createState() => _WorkerHomeFeedState();
}

class _WorkerHomeFeedState extends ConsumerState<WorkerHomeFeed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final currentProfile = ref.read(workerProvider);
      if (auth != null && currentProfile == null) {
        ref.read(workerProvider.notifier).loadProfile(auth.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final worker = ref.watch(workerProvider);
    final auth = ref.watch(authProvider);
    final feedAsyncValue = ref.watch(unifiedFeedProvider);
    final appliedJobs = ref.watch(workerAppliedJobsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.outline, width: 1.5),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFBBF24), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('KI Job Portal', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: AppColors.primary, size: 26),
                    onPressed: () => context.push('/search'),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final announcementsAsync = ref.watch(systemAnnouncementsProvider);
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2563EB), size: 26),
                            onPressed: () => context.push('/announcements'),
                          ),
                          announcementsAsync.when(
                            data: (list) => list.isNotEmpty 
                              ? Positioned(
                                  right: 8,
                                  top: 8,
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
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => context.push('/public-profile/${auth?.uid}/worker'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.outline,
                        backgroundImage: (worker?.profilePhotoUrl != null && worker!.profilePhotoUrl!.isNotEmpty) 
                            ? NetworkImage(worker.profilePhotoUrl!) 
                            : (worker?.localImageFile != null ? FileImage(worker!.localImageFile!) : null),
                        child: (worker?.profilePhotoUrl == null && worker?.localImageFile == null) 
                            ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 18) 
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = ref.read(authProvider);
          if (auth != null) {
            await ref.read(workerProvider.notifier).loadProfile(auth.uid);
          }
        },
        color: const Color(0xFF2563EB),
        backgroundColor: theme.cardColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, ${worker?.name.split(' ')[0] ?? 'Karigar'}',
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready for your next masterpiece?',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: appliedJobs.when(
                          data: (jobs) => jobs.length.toString().padLeft(2, '0'),
                          loading: () => '..',
                          error: (_, __) => '00',
                        ),
                        label: 'ACTIVE\nJOBS',
                        color: const Color(0xFF60A5FA),
                        theme: theme,
                        onTap: () => context.push('/profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${worker?.credits ?? 50}',
                        label: 'CREDITS\nLEFT',
                        color: const Color(0xFFFBBF24),
                        theme: theme,
                        onTap: () => context.push('/subscription'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
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
                        label: 'PROFILE\nSTRENGTH',
                        color: const Color(0xFF34D399),
                        theme: theme,
                        onTap: () => context.push('/edit-profile'),
                      ),
                    ),
                  ],
                ),
              ),

              Consumer(
                builder: (context, ref, child) {
                  final bannerAsync = ref.watch(activeBannerProvider);
                  return bannerAsync.when(
                    data: (banner) {
                      if (banner == null || !banner.isActive) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 120,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const SizedBox.shrink(),
                              ),
                              if (banner.headline != null || banner.subhead != null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (banner.headline != null && banner.headline!.isNotEmpty)
                                          Text(banner.headline!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                        if (banner.subhead != null && banner.subhead!.isNotEmpty)
                                          Text(banner.subhead!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),

              // Recommended Horizontal row (Optional Filter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended Jobs', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                    const Text('View All', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _FilterChip(label: 'All Trades', isSelected: true, theme: theme),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Plumbing', theme: theme),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Electrical', theme: theme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Unified Feed
              feedAsyncValue.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No updates available.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    );
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
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ThemeData theme;
  const _FilterChip({required this.label, this.isSelected = false, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final ThemeData theme;
  final VoidCallback? onTap;
  const _StatCard({required this.value, required this.label, required this.color, required this.theme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
