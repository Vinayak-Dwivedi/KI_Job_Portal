import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/post_provider.dart';
import '../../core/theme/app_colors.dart';
import 'reels_video_player.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  final String? initialPostId;
  const ReelsScreen({super.key, this.initialPostId});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsyncValue = ref.watch(reelsFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyState(context);
          }

          if (!_initialized) {
            _initialized = true;
            if (widget.initialPostId != null) {
              final index = posts.indexWhere((p) => p['id'] == widget.initialPostId);
              if (index != -1) {
                _currentIndex = index;
                _pageController = PageController(initialPage: index);
              }
            }
          }

          return Stack(
            children: [
              PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: posts.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final post = posts[index];
                  // Determine video url
                  String videoUrl = '';
                  if (post['media'] != null) {
                    final mediaList = List<Map<String, dynamic>>.from(post['media']);
                    final videoMedia = mediaList.firstWhere(
                      (m) {
                        if (m['type'] == 'video') return true;
                        final url = (m['url'] ?? '').toString().toLowerCase();
                        return ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => url.contains('.$ext?') || url.endsWith('.$ext'));
                      },
                      orElse: () => <String, dynamic>{},
                    );
                    videoUrl = videoMedia['url'] ?? '';
                  }
                  if (videoUrl.isEmpty && post['imageUrl'] != null) {
                    videoUrl = post['imageUrl'];
                  }

                  return ReelVideoPlayer(
                    post: post,
                    videoUrl: videoUrl,
                    isActive: _currentIndex == index,
                  );
                },
              ),
              // Custom Back Button Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text('Error loading videos', style: const TextStyle(color: Colors.white)),
              TextButton(
                onPressed: () => ref.refresh(reelsFeedProvider),
                child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 80),
          const SizedBox(height: 16),
          const Text(
            'No videos found',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
