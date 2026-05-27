import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/post_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../widgets/feed/post_image_grid.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface, size: 20),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final role = auth?.role ?? 'worker';
              context.go(role == 'employer' ? '/employer/dashboard' : '/worker/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_rounded, color: theme.colorScheme.onSurface, size: 20),
            ),
            onPressed: () {
              final String shareUrl = 'https://kijobportal.app/post/$postId';
              Share.share('Check out this post on KI Job Portal:\n$shareUrl');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: PostService.getPost(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final post = snapshot.data;
          if (post == null) {
            return Center(
              child: Text('Post not found', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
            );
          }

          final bool isAdminPost = post['isAdmin'] == true;
          final bool isJobPost = post['isJobPost'] == true;
          final bool isAvailabilityPost = post['isAvailabilityPost'] == true;
          final bool isEventPost = post['eventTitle'] != null && post['eventTitle'].toString().trim().isNotEmpty;
          final String description = post['text'] ?? post['description'] ?? '';
          final String displayDescription = description.trim().isEmpty 
              ? 'N/A - no descriptions added by the user' 
              : description;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header / Cover Image Area
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAdminPost 
                          ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                          : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Background elements
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Hero(
                              tag: 'post_avatar_${post['id'] ?? postId}',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                ),
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final String postUid = (post['uid'] ?? '').toString().trim();
                                    final liveProfile = ref.watch(liveProfileProvider(postUid));
                                    
                                    return liveProfile.when(
                                      data: (userData) {
                                        final photoUrl = userData?['profilePhotoUrl'] ?? post['profilePhotoUrl'] ?? '';
                                        return CircleAvatar(
                                          radius: 40,
                                          backgroundImage: photoUrl.isNotEmpty
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl.isEmpty
                                              ? const Icon(Icons.person, size: 40, color: Colors.white)
                                              : null,
                                        );
                                      },
                                      loading: () => const CircleAvatar(
                                        radius: 40,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      error: (_, __) => const CircleAvatar(
                                        radius: 40,
                                        child: Icon(Icons.person, size: 40, color: Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post['isShared'] == true) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: (post['sharedByUserPhotoUrl'] != null && post['sharedByUserPhotoUrl'].toString().isNotEmpty)
                                        ? NetworkImage(post['sharedByUserPhotoUrl'])
                                        : null,
                                    child: (post['sharedByUserPhotoUrl'] == null || post['sharedByUserPhotoUrl'].toString().isEmpty)
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${post['sharedByUserName'] ?? 'Someone'} shared this',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.repeat_rounded, color: theme.colorScheme.primary, size: 18),
                                ],
                              ),
                              if (post['shareCaption'] != null && post['shareCaption'].toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  post['shareCaption'],
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // User Info & Badges
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer(
                                  builder: (context, ref, child) {
                                    final String postUid = (post['uid'] ?? '').toString().trim();
                                    final liveProfile = ref.watch(liveProfileProvider(postUid));
                                    final currentName = liveProfile.asData?.value?['name'] ?? 
                                                        liveProfile.asData?.value?['fullName'] ?? 
                                                        post['name'] ?? 'Anonymous';
                                    return Text(
                                      currentName,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final String postUid = (post['uid'] ?? '').toString().trim();
                                    final liveProfile = ref.watch(liveProfileProvider(postUid));
                                    final currentRole = liveProfile.asData?.value?['role'] ?? 
                                                        post['role']?.toString().toUpperCase() ?? 'USER';
                                    return Text(
                                      currentRole.toString().toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (isAdminPost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Highlighted Info Card (Salary/Job Title)
                      if (isJobPost || isAvailabilityPost)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.work_outline_rounded, color: theme.colorScheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      post['jobTitle'] ?? 'No Title',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SALARY / RATE',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          post['jobSalary'] ?? 'Negotiable',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 40, color: theme.dividerColor.withOpacity(0.1)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LOCATION',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          () {
                                            final rawLoc = post['location'];
                                            final String location = rawLoc is Map
                                                ? (rawLoc['address'] ?? '')
                                                : (rawLoc?.toString() ?? '');
                                            final String? subLocation = rawLoc is Map
                                                ? (rawLoc['subLocation'] ?? post['subLocation'])
                                                : post['subLocation'];
                                            return (subLocation != null && subLocation.isNotEmpty) 
                                                ? '$location ($subLocation)' 
                                                : (location.isNotEmpty ? location : 'Global');
                                          }(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                      if (isEventPost)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.1),
                                Colors.blue.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: -40,
                                    right: -40,
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(28.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(30),
                                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'EXCLUSIVE EVENT',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: Colors.purple,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 10,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          post['eventTitle'] ?? 'Professional Gathering',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 32,
                                            height: 1.1,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: theme.scaffoldBackgroundColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildEventDetailItem(
                                                      icon: Icons.calendar_today_rounded,
                                                      label: 'DATE',
                                                      value: post['eventDate'] != null 
                                                          ? "${(post['eventDate'] as Timestamp).toDate().day} ${_getMonthName((post['eventDate'] as Timestamp).toDate().month)}, ${(post['eventDate'] as Timestamp).toDate().year}"
                                                          : 'To Be Announced',
                                                      theme: theme,
                                                    ),
                                                  ),
                                                  Container(width: 1, height: 40, color: Colors.white10),
                                                  Expanded(
                                                    child: _buildEventDetailItem(
                                                      icon: Icons.access_time_filled_rounded,
                                                      label: 'TIME',
                                                      value: post['eventTime'] ?? 'Schedule Pending',
                                                      theme: theme,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (post['eventLocation'] != null && post['eventLocation'].toString().isNotEmpty) ...[
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 16),
                                                  child: Divider(color: Colors.white10),
                                                ),
                                                _buildEventDetailItem(
                                                  icon: Icons.location_on_rounded,
                                                  label: 'VENUE',
                                                  value: post['eventLocation'],
                                                  theme: theme,
                                                  isFullWidth: true,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                      const SizedBox(height: 32),
                      
                      // Media Grid
                      _buildMediaGrid(post),

                      const SizedBox(height: 32),
                      
                      // Description Header with Icon
                      Row(
                        children: [
                          Icon(isEventPost ? Icons.info_outline_rounded : Icons.notes_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEventPost ? 'ABOUT THIS EVENT' : 'ABOUT THIS POST',
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Main Content / Description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          displayDescription,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.colorScheme.onSurface.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            fontStyle: description.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Action Section
                      if (auth != null)
                        Consumer(
                          builder: (context, ref, child) {
                            final String postUid = (post['uid'] ?? '').toString().trim();
                            final isUnlockedAsync = ref.watch(isContactUnlockedProvider(postUid));
                            final isUnlocked = isUnlockedAsync.value ?? false;
                            final isOwner = auth.uid == postUid;

                            return Row(
                              children: [
                                if (isJobPost) ...[
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: () => _showContactOptions(context, ref, auth, post),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: theme.colorScheme.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: Text(
                                          'CONTACT',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (isJobPost) {
                                          // Handle Job Application if needed
                                        } else {
                                          _handleContactAction(
                                            context, 
                                            ref, 
                                            auth, 
                                            post, 
                                            isUnlocked || isOwner
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isJobPost 
                                            ? 'APPLY FOR THIS JOB' 
                                            : (isAvailabilityPost 
                                                ? (isUnlocked || isOwner ? 'CONTACT OPTIONS' : 'CONTACT WORKER') 
                                                : 'SEND MESSAGE'),
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaGrid(Map<String, dynamic> post) {
    List<Map<String, dynamic>> media = [];
    if (post['media'] != null) {
      media = List<Map<String, dynamic>>.from(post['media']);
    } else if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty) {
      media = [
        {'url': post['imageUrl'], 'type': 'image'}
      ];
    }

    if (media.isEmpty) return const SizedBox.shrink();

    return PostMediaGrid(media: media);
  }

  // ── Contact Logic ────────────────────────────────────────────────────────

  void _handleContactAction(
    BuildContext context, 
    WidgetRef ref, 
    dynamic auth, 
    Map<String, dynamic> post, 
    bool isUnlocked
  ) async {
    final String postUid = (post['uid'] ?? '').toString().trim();
    if (isUnlocked) {
      _showContactOptions(context, ref, auth, post);
    } else {
      _handleUnlock(context, ref, auth, postUid);
    }
  }

  void _handleUnlock(BuildContext context, WidgetRef ref, dynamic auth, String targetUid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Contact Details'),
        content: const Text(
          'This will deduct 10 credits from your balance. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      await FirestoreService.unlockContactInfo(
        viewerUid: auth.uid,
        targetUid: targetUid,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact details unlocked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        final errorStr = e.toString().replaceAll('Exception: ', '');
        if (errorStr.contains('Insufficient credits')) {
          _showInsufficientCreditsDialog(context, errorStr);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorStr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInsufficientCreditsDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Required ⚡'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/worker/subscriptions?tab=1');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Top Up Now'),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(
    BuildContext context, 
    WidgetRef ref, 
    dynamic auth, 
    Map<String, dynamic> post
  ) async {
    final theme = Theme.of(context);
    final String postUid = (post['uid'] ?? '').toString().trim();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Fetch target user data for contact info
      final targetUserData = await ref.read(publicProfileProvider(postUid).future);
      
      if (context.mounted) Navigator.pop(context); // Close loading

      if (targetUserData == null) return;

      final String phone = targetUserData['phone'] ?? '';
      final String email = targetUserData['email'] ?? '';
      final String name = targetUserData['name'] ?? targetUserData['fullName'] ?? 'User';
      final String? photo = targetUserData['profilePhotoUrl'];

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                      child: (photo == null || photo.isEmpty) ? const Icon(Icons.person, size: 28) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Choose how to connect',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (phone.isNotEmpty)
                  _buildContactMethod(
                    context: context,
                    icon: Icons.phone_forwarded_rounded,
                    title: 'Call Now',
                    subtitle: phone,
                    color: Colors.green,
                    onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  ),
                if (email.isNotEmpty)
                  _buildContactMethod(
                    context: context,
                    icon: Icons.alternate_email_rounded,
                    title: 'Send Email',
                    subtitle: email,
                    color: Colors.blue,
                    onTap: () => launchUrl(Uri.parse('mailto:$email')),
                  ),
                _buildContactMethod(
                  context: context,
                  icon: Icons.chat_bubble_rounded,
                  title: 'Message',
                  subtitle: 'Start a chat on KI Job Portal',
                  color: theme.colorScheme.primary,
                  onTap: () async {
                    Navigator.pop(context);
                    _handleChatAction(context, ref, auth, postUid, targetUserData);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildContactMethod({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChatAction(
    BuildContext context, 
    WidgetRef ref, 
    dynamic auth, 
    String targetUid,
    Map<String, dynamic> targetUserData
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
      
      final chatId = await ChatService.getOrCreateChat(auth.uid, targetUid, targetUserData);
      
      if (chatId.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      final isChatUnlocked = chatDoc.data()?['isUnlocked'] ?? false;
      
      if (context.mounted) Navigator.pop(context); // Close loading

      if (isChatUnlocked) {
        if (context.mounted) {
          context.push('/chat/$chatId', extra: {
            'name': targetUserData['name'] ?? targetUserData['fullName'] ?? 'User',
            'photo': targetUserData['profilePhotoUrl'] ?? '',
          });
        }
      } else {
        if (context.mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unlock Messaging'),
              content: const Text(
                'Initiating a chat costs 10 credits. Do you want to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Unlock (10)'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
            
            final success = await ChatService.unlockChat(auth.uid, chatId);
            if (context.mounted) Navigator.pop(context); // Close loading
            
            if (success) {
              if (context.mounted) {
                context.push('/chat/$chatId', extra: {
                  'name': targetUserData['name'] ?? targetUserData['fullName'] ?? 'User',
                  'photo': targetUserData['profilePhotoUrl'] ?? '',
                });
              }
            } else {
              if (context.mounted) {
                _showInsufficientCreditsDialog(context, 'Insufficient credits to unlock messaging.');
              }
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildEventDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool isFullWidth = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple.withOpacity(0.6), size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
