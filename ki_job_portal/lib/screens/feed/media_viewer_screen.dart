import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> media;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.media.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.media.length,
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        builder: (context, index) {
          final item = widget.media[index];
          final type = item['type'] ?? 'image';
          final url = item['url'] ?? '';

          if (type == 'video') {
            return PhotoViewGalleryPageOptions.customChild(
              child: _VideoViewer(url: url),
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: url),
            );
          } else {
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(url),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: url),
            );
          }
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final String url;
  const _VideoViewer({required this.url});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
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
        autoPlay: true,
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
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }
}
