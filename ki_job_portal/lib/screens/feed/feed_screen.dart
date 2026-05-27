import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/feed/feed_filter_sheet.dart';
import '../../providers/public_user_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  final String? targetPostId;
  const FeedScreen({super.key, this.targetPostId});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String? _highlightedPostId;
  bool _hasScrolledToTarget = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    if (widget.targetPostId != null) {
      _highlightedPostId = widget.targetPostId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getTabKey() {
    switch (_tabController.index) {
      case 1: return 'trending';
      case 2: return 'network';
      default: return 'latest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabKey = _getTabKey();
    final feedAsyncValue = ref.watch(feedProvider(tabKey));
    final filteredPosts = ref.watch(filteredCommunityFeedProvider(tabKey));
    final theme = Theme.of(context);

    
    final auth = ref.watch(authProvider);
    final worker = ref.watch(workerProvider);
    final employer = ref.watch(employerProvider);

    String? userPhoto;
    if (auth?.role == 'worker') userPhoto = worker?.profilePhotoUrl;
    if (auth?.role == 'employer') userPhoto = employer?.profilePhotoUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.communityFeed, 
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface, size: 26),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: theme.colorScheme.onSurface, size: 26),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const FeedFilterSheet(),
            ),
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabLatest),
            Tab(text: AppLocalizations.of(context)!.tabTrending),
            Tab(text: AppLocalizations.of(context)!.tabNetwork),
          ],

        ),
      ),
      body: feedAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyState(theme);
          }

          if (widget.targetPostId != null && !_hasScrolledToTarget) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final index = posts.indexWhere((p) => p['id'] == widget.targetPostId);
              if (index != null && index != -1) {
                // index + 2 because of CreatePostArea and FeaturedWorkers
                _scrollController.animateTo(
                  (index + 2) * 400.0, // Rough estimate of post height, index based scroll is better with keys but this is a start
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                );
                setState(() => _hasScrolledToTarget = true);
                
                // Clear highlight after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _highlightedPostId = null);
                });
              }
            });
          }

          List<Widget> feedItems = [];
          feedItems.add(_buildCreatePostArea(context, theme, userPhoto));
          feedItems.add(_buildFeaturedWorkers(theme));
          
          for (int i = 0; i < filteredPosts.length; i++) {
            final post = filteredPosts[i];
            final isHighlighted = post['id'] == _highlightedPostId;
            
            feedItems.add(
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  border: isHighlighted 
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                ),
                child: PostCard(post: post),
              )
            );
            
            if (i == 1) {
              feedItems.add(_buildSuggestedProfilesCarousel(theme, 'Suggested Employers', suggestedEmployersProvider));
            }
            if (i == 4) {
              feedItems.add(_buildSuggestedProfilesCarousel(theme, 'Suggested Workers', suggestedWorkersProvider));
            }
            if (i == 7) {
              feedItems.add(_buildSuggestedProfilesCarousel(theme, 'People You May Know', peopleYouMayKnowProvider));
            }
          }

          return RefreshIndicator(
            backgroundColor: theme.cardColor,
            color: AppColors.primary,
            onRefresh: () async => ref.refresh(feedProvider(tabKey).future),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8),
              itemCount: feedItems.length,
              itemBuilder: (context, index) => feedItems[index],
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('${AppLocalizations.of(context)!.errorLoadingFeed}$err', style: const TextStyle(color: AppColors.error)),
              TextButton(
                onPressed: () => ref.refresh(feedProvider(tabKey)),
                child: Text(AppLocalizations.of(context)!.retry, style: const TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, color: theme.colorScheme.surfaceVariant, size: 80),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noPostsYet,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.beFirstToShare,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/feed/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(AppLocalizations.of(context)!.startConversation, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => PostCard(
          post: const {
            'name': 'Loading Name',
            'text': 'This is a sample loading text to show the skeleton effect in the feed screen.',
            'location': 'Loading Location',
            'role': 'worker',
            'likes': 0,
            'comments': 0,
          },
        ),
      ),
    );
  }

  Widget _buildCreatePostArea(BuildContext context, ThemeData theme, String? userPhoto) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.symmetric(
          horizontal: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: userPhoto != null && userPhoto.isNotEmpty 
                  ? NetworkImage(userPhoto) 
                  : const NetworkImage('https://ui-avatars.com/api/?name=User&background=F59E0B&color=fff'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/feed/create'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Text(AppLocalizations.of(context)!.shareProfessionalUpdates, 
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPostAction(Icons.image_outlined, AppLocalizations.of(context)!.postPhoto, Colors.blue, theme),
              _buildPostAction(Icons.videocam_outlined, AppLocalizations.of(context)!.postVideo, Colors.green, theme),
              _buildPostAction(Icons.event_note_outlined, AppLocalizations.of(context)!.postEvent, Colors.orange, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color color, ThemeData theme) {
    return GestureDetector(
      onTap: () => context.push('/feed/create'),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFeaturedWorkers(ThemeData theme) {
    final featuredAsync = ref.watch(featuredWorkersProvider);
    
    return featuredAsync.when(
      data: (workers) {
        if (workers.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.featuredKarigars,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 208,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => context.push('/profile/worker/${worker.uid}'),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: worker.profilePhotoUrl != null && worker.profilePhotoUrl!.isNotEmpty
                                ? NetworkImage(worker.profilePhotoUrl!)
                                : null,
                              child: worker.profilePhotoUrl == null || worker.profilePhotoUrl!.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              worker.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              worker.skills.isNotEmpty ? worker.skills.first : 'Worker',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestedProfilesCarousel(ThemeData theme, String title, dynamic provider) {
    final AsyncValue<List<Map<String, dynamic>>> suggestedAsync = ref.watch(provider);
    
    return suggestedAsync.when(
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final String name = user['name'] ?? user['companyName'] ?? user['contactName'] ?? 'User';
                  final String role = user['role'] ?? 'user';
                  final String? photoUrl = user['profilePhotoUrl'];
                  final String displayRole = (role == 'worker' && user['skills'] != null && (user['skills'] as List).isNotEmpty)
                      ? (user['skills'] as List).first.toString()
                      : role.toUpperCase();
                  
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => context.push('/profile/$role/${user['id']}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                                : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              displayRole,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Connect',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
