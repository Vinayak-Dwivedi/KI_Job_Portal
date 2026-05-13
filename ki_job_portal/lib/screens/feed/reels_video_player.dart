import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../core/services/post_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/feed/share_bottom_sheet.dart';

class ReelVideoPlayer extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;
  final String videoUrl;
  final bool isActive;

  const ReelVideoPlayer({
    super.key,
    required this.post,
    required this.videoUrl,
    required this.isActive,
  });

  @override
  ConsumerState<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends ConsumerState<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    _controller.setLooping(true);
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      if (widget.isActive) {
        _controller.play();
      }
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive && _isInitialized) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleLike(String postId, String uid, String likerName) async {
    if (_isLiking) return;
    setState(() => _isLiking = true);
    await PostService.toggleLike(postId, uid, likerName);
    setState(() => _isLiking = false);
  }

  void _sharePost(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final String postId = widget.post['id'] ?? '';
    final String uid = (widget.post['uid'] ?? '').toString().trim();
    final String name = widget.post['name'] ?? 'User';
    final String text = widget.post['text'] ?? '';
    String role = (widget.post['isAdmin'] == true) ? 'admin' : (widget.post['role'] ?? 'worker');
    if (role.isEmpty) role = 'worker';
    final String? profilePhotoUrl = widget.post['profilePhotoUrl'];
    final int likes = widget.post['likes'] ?? 0;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Play/Pause Indicator Overlay
          if (_isInitialized && !_controller.value.isPlaying)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 80),
              ),
            ),

          // Gradient for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // User Info & Description (Bottom Left)
          Positioned(
            bottom: 100,
            left: 16,
            right: 80, // Make room for right action bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile/$role/$uid'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                            ? NetworkImage(profilePhotoUrl)
                            : null,
                        child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Action Bar (Bottom Right)
          Positioned(
            bottom: 100,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Profile
                _buildActionIcon(
                  icon: Icons.person_search_rounded,
                  label: AppLocalizations.of(context)!.profile,
                  onTap: () => context.push('/profile/$role/$uid'),
                ),
                const SizedBox(height: 20),
                // Like
                StreamBuilder<bool>(
                  stream: auth != null
                      ? PostService.isPostLiked(postId, auth.uid)
                      : Stream.value(false),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return _buildActionIcon(
                      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isLiked ? Colors.redAccent : Colors.white,
                      label: '$likes',
                      onTap: () {
                        if (auth != null) {
                          String likerName = 'User';
                          final worker = ref.read(workerProvider);
                          final employer = ref.read(employerProvider);
                          if (worker != null && worker.uid == auth.uid) {
                            likerName = worker.name;
                          } else if (employer != null && employer.uid == auth.uid) {
                            likerName = employer.name;
                          }
                          _toggleLike(postId, auth.uid, likerName);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Share
                _buildActionIcon(
                  icon: Icons.share_rounded,
                  label: AppLocalizations.of(context)!.share,
                  onTap: () => _sharePost(context, widget.post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
