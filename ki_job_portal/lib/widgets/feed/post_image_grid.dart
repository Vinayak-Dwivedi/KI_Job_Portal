import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PostMediaGrid extends StatelessWidget {
  final List<Map<String, dynamic>> media;

  const PostMediaGrid({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildGrid(context),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    switch (media.length) {
      case 1:
        return _mediaWidget(context, media[0], 0, height: 260);
      case 2:
        return Row(
          children: [
            Expanded(child: _mediaWidget(context, media[0], 0, height: 180)),
            const SizedBox(width: 4),
            Expanded(child: _mediaWidget(context, media[1], 1, height: 180)),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(child: _mediaWidget(context, media[0], 0, height: 220)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  _mediaWidget(context, media[1], 1, height: 108),
                  const SizedBox(height: 4),
                  _mediaWidget(context, media[2], 2, height: 108),
                ],
              ),
            ),
          ],
        );
      default:
        // 4 or more
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _mediaWidget(context, media[0], 0, height: 140)),
                const SizedBox(width: 4),
                Expanded(child: _mediaWidget(context, media[1], 1, height: 140)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _mediaWidget(context, media[2], 2, height: 140)),
                const SizedBox(width: 4),
                Expanded(child: _mediaWidget(context, media[3], 3, height: 140)),
              ],
            ),
          ],
        );
    }
  }

  Widget _mediaWidget(BuildContext context, Map<String, dynamic> item, int index, {required double height}) {
    final String url = item['url'] ?? '';
    String type = item['type'] ?? 'image';

    // Fallback for incorrectly categorized legacy videos
    if (type == 'image' && ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => url.toLowerCase().contains('.$ext?'))) {
      type = 'video';
    } else if (type == 'image' && ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => url.toLowerCase().endsWith('.$ext'))) {
      type = 'video';
    }

    if (type == 'video') {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: FeedVideoPlayer(url: url),
      );
    }

    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    // Only open gallery for images.
    final images = media.where((m) => m['type'] != 'video').toList();
    if (images.isEmpty) return;
    
    // Find the new index of the tapped image among only the images
    final currentUrl = media[initialIndex]['url'];
    int parsedInitialIndex = images.indexWhere((m) => m['url'] == currentUrl);
    if (parsedInitialIndex == -1) parsedInitialIndex = 0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(images[index]['url']),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]['url']),
              );
            },
            pageController: PageController(initialPage: parsedInitialIndex),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final String url;
  const FeedVideoPlayer({super.key, required this.url});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _videoPlayerController.initialize();
    
    if (mounted) {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.amber,
          handleColor: Colors.amber,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade400,
        ),
        aspectRatio: _videoPlayerController.value.aspectRatio,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Chewie(
          controller: _chewieController!,
        ),
      );
    } else {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
