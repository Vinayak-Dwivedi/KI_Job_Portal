import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/post_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';

class ShareBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;
  const ShareBottomSheet({super.key, required this.post});

  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSharing = false;

  void _handleShare(String privacy) async {
    final user = ref.read(authProvider);
    final worker = ref.read(workerProvider);
    final employer = ref.read(employerProvider);
    
    String name = 'User';
    String? photo;
    
    if (user?.role == 'worker') {
      name = worker?.name ?? 'Worker';
      photo = worker?.profilePhotoUrl;
    } else if (user?.role == 'employer') {
      name = employer?.contactPersonName ?? 'Employer';
      photo = employer?.profilePhotoUrl;
    }

    if (user == null) return;

    setState(() => _isSharing = true);
    try {
      await PostService.sharePost(
        originalPostId: widget.post['id'],
        sharerUid: user.uid,
        sharerName: name,
        sharerPhotoUrl: photo,
        shareCaption: _captionController.text.trim(),
        privacy: privacy,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post shared successfully to $privacy feed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Share Post',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _captionController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ShareOptionTile(
            icon: Icons.public_rounded,
            title: 'Share Publicly',
            subtitle: 'Visible to everyone on the feed',
            onTap: () => _handleShare('public'),
            isLoading: _isSharing,
          ),
          _ShareOptionTile(
            icon: Icons.people_rounded,
            title: 'Share to Connections',
            subtitle: 'Visible only to your followers',
            onTap: () => _handleShare('connections'),
            isLoading: _isSharing,
          ),
          _ShareOptionTile(
            icon: Icons.send_rounded,
            title: 'Send as Direct Message',
            subtitle: 'Share privately with someone',
            onTap: () {
              // TODO: Implement direct share
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Direct share coming soon!')),
              );
            },
            isLoading: false,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLoading ? null : onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
      trailing: isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
