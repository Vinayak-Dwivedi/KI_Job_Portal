import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/post_service.dart';
import '../../providers/application_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';
import 'package:ki_job_portal/core/theme/app_colors.dart';

import '../../widgets/feed/share_bottom_sheet.dart';
import '../../widgets/feed/comment_bottom_sheet.dart';
import '../../widgets/feed/likers_bottom_sheet.dart';
import '../../widgets/feed/post_image_grid.dart';
import '../../widgets/feed/parsed_text.dart';
import '../../core/services/chat_service.dart';

class PostCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLiking = false;
  bool _isExpanded = false;
  String? _translatedText;      // null = not translated yet
  bool _showTranslated = false; // toggle between original and translated
  bool _isTranslating = false;  // show loader while fetching

  Future<void> _translatePost(String text, String targetLang) async {
    if (_translatedText != null) {
      // Already fetched — just toggle visibility
      setState(() => _showTranslated = !_showTranslated);
      return;
    }
    setState(() => _isTranslating = true);
    final result = await TranslationService.translate(
      text: text,
      targetLang: targetLang,
      sourceLang: 'en',
    );
    if (mounted) {
      setState(() {
        _translatedText = result;
        _showTranslated = true;
        _isTranslating = false;
      });
    }
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

  void _showComments(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(postId: postId),
    );
  }

  void _showLikers(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LikersBottomSheet(postId: postId),
    );
  }

  void _applyToJob(
    BuildContext context,
    Map<String, dynamic> post,
    String workerName,
    String workerPhone,
    String? imageUrl,
  ) async {
    // 1. Calculate cost (same logic as in service)
    int cost = 10;
    final salaryStr = post['jobSalary']?.toString() ?? '';
    final numbersOnly = salaryStr.replaceAll(RegExp(r'[^0-9]'), '');
    final salaryVal = int.tryParse(numbersOnly) ?? 0;
    if (salaryVal > 30000) cost = 15;

    // 2. Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply for this Job?'),
        content: Text('This application will deduct $cost credits from your balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('Apply — $cost Credits'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(applicationProvider).applyToJob(
            post: post,
            workerName: workerName,
            workerPhone: workerPhone,
            workerImageUrl: imageUrl,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorStr = e.toString().replaceAll('Exception: ', '');
        if (errorStr.contains('Insufficient credits')) {
          _showInsufficientCreditsDialog(context, errorStr);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to apply: $errorStr'), backgroundColor: Colors.red),
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
            child: const Text('Top Up Now'),
          ),
        ],
      ),
    );
  }

  void _showPostOptionsPanel(
    BuildContext context,
    String postId,
    String postUid,
    bool isWorkerPost,
    bool isJobPost,
  ) {
    final auth = ref.read(authProvider);
    final trueOwnerUid = widget.post['isShared'] == true 
        ? widget.post['sharedByUserId'] 
        : postUid;
        
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth?.uid == trueOwnerUid || auth?.role == 'admin') ...[
              if (widget.post['isShared'] != true) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/feed/create', extra: widget.post);
                  },
                ),
              ],
              ListTile(
                leading: Icon(widget.post['isShared'] == true ? Icons.remove_circle_outline_rounded : Icons.delete_outline_rounded, color: Colors.red),
                title: Text(widget.post['isShared'] == true ? 'Unshare Post' : 'Delete Post', style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, postId);
                },
              ),
              if (widget.post['isFeatured'] != true && widget.post['isShared'] != true)
                ListTile(
                  leading: const Icon(Icons.bolt_rounded, color: Colors.amber),
                  title: const Text('Boost Post (80 Credits)'),
                  onTap: () {
                    Navigator.pop(context);
                    _boostPost(context, postId, postUid);
                  },
                ),
              const Divider(),
            ],
            if (isWorkerPost && auth?.role == 'employer')
              ListTile(
                leading: const Icon(Icons.contact_phone_outlined, color: Colors.blue),
                title: const Text('Contact Worker'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile/worker/$postUid');
                },
              ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded),
              title: const Text('Bookmark Post'),
              onTap: () async {
                Navigator.pop(context);
                if (auth != null) {
                  await PostService.saveJob(auth.uid, postId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post bookmarked.')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, postId, postUid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: Colors.red),
              title: const Text(
                'Block User',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                final auth = ref.read(authProvider);
                if (auth != null) {
                  PostService.blockUser(auth.uid, postUid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked.'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide Post'),
              onTap: () {
                Navigator.pop(context);
                final auth = ref.read(authProvider);
                if (auth != null) {
                  PostService.hidePost(auth.uid, postId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post hidden.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _boostPost(BuildContext context, String postId, String postUid) async {
    final auth = ref.read(authProvider);
    if (auth == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Boost this Post?'),
        content: const Text('Boosting this post will cost 80 credits and make it featured for 24 hours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Boost — 80 Credits'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PostService.featurePost(postId, auth.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post boosted successfully! 🚀'), backgroundColor: Colors.green),
          );
          // Refresh the user's profile if we are on the profile screen
          if (auth.role == 'worker') {
            ref.read(workerProvider.notifier).loadProfile(auth.uid);
          } else {
            ref.read(employerProvider.notifier).loadProfile(auth.uid);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String postId) {
    final isShared = widget.post['isShared'] == true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isShared ? 'Unshare Post?' : 'Delete Post?'),
        content: Text(isShared ? 'This will remove the shared post from your profile.' : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PostService.deletePost(postId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isShared ? 'Post unshared.' : 'Post deleted.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isShared ? 'Unshare' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, String postId, String postUid) {
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Why are you reporting this?',
          ),
          onChanged: (val) => reason = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final auth = ref.read(authProvider);
              if (auth != null && reason.trim().isNotEmpty) {
                PostService.reportPost(
                  postId,
                  auth.uid,
                  postUid,
                  reason.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported. Thank you.')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final String postId = post['id'] ?? '';

    /// 🔥 SAFE FALLBACKS
    final String uid = (post['uid'] ?? post['userId'] ?? '').toString().trim();
    final String name = post['name'] ?? 'Unknown User';
    String role = (post['isAdmin'] == true) ? 'admin' : (post['role'] ?? 'worker');
    if (role.isEmpty) role = 'worker';
    final String text = post['text'] ?? '';
    final String? imageUrl = post['imageUrl'];
    List<Map<String, dynamic>> media = [];
    if (post['media'] != null) {
      media = List<Map<String, dynamic>>.from(post['media']);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      media = [
        {'url': imageUrl, 'type': 'image'},
      ];
    }
    final String? profilePhotoUrl = post['profilePhotoUrl'];
    final bool isVerified = post['isVerified'] ?? false;
    final String location = post['location'] ?? '';
    final String? subLocation = post['subLocation'];
    final String locationDisplay = (subLocation != null && subLocation.isNotEmpty) 
        ? '$location ($subLocation)' 
        : location;
    final int likes = post['likes'] ?? 0;
    final int comments = post['comments'] ?? 0;
    final int shares = post['shares'] ?? 0;
    final bool isJobPost = post['isJobPost'] == true;
    final bool isAvailabilityPost = post['isAvailabilityPost'] == true || (role == 'worker' && post['jobTitle'] != null && post['jobTitle'].toString().trim().isNotEmpty && post['jobTitle'] != 'Job Posting');
    final String jobTitle = post['jobTitle'] ?? (isJobPost ? 'Job Posting' : 'Work Profile');
    final String jobSalary = post['jobSalary'] ?? (isJobPost ? 'Negotiable' : 'Market Rate');
    final String status = post['status'] ?? 'approved';
    final dynamic createdAt = post['createdAt'];

    final String? eventTitle = post['eventTitle'];
    final bool isEventPost = eventTitle != null && eventTitle.toString().trim().isNotEmpty;
    final dynamic eventDateRaw = post['eventDate'];
    final String? eventTime = post['eventTime'];
    final String? eventLocation = post['eventLocation'];
    
    DateTime? eventDate;
    if (eventDateRaw is Timestamp) {
      eventDate = eventDateRaw.toDate();
    }

    String timeStr = 'Just now';
    if (createdAt is Timestamp) {
      try {
        final date = createdAt.toDate();
        timeStr = timeago.format(date);
      } catch (e) {
        timeStr = 'Just now';
      }
    }

    final bool isAdminPost = post['isAdmin'] == true || role == 'admin';
    final bool isFeatured = post['isFeatured'] == true;
    final bool isShared = post['isShared'] == true;
    final String? shareCaption = post['shareCaption'];
    final String? sharedByUserName = post['sharedByUserName'];
    final String? sharedByUserPhotoUrl = post['sharedByUserPhotoUrl'];
    final String? sharedByUserId = post['sharedByUserId'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isAdminPost
            ? (theme.brightness == Brightness.dark
                  ? const Color(0xFF1E1B4B).withOpacity(0.5)
                  : const Color(0xFFEEF2FF))
            : theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFeatured
              ? Colors.amber.withOpacity(0.5)
              : isAdminPost
              ? const Color(0xFFFBBF24).withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: (isFeatured || isAdminPost) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured
                ? Colors.amber.withOpacity(0.15)
                : isAdminPost
                ? const Color(0xFFFBBF24).withOpacity(0.15)
                : Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.3 : 0.05,
                  ),
            blurRadius: (isFeatured || isAdminPost) ? 20 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == 'pending')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border(bottom: BorderSide(color: Colors.orange.withOpacity(0.3))),
                ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 14),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'PENDING APPROVAL - Only visible to you',
                            style: TextStyle(
                              color: Colors.orange, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 0.5
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              )
            else if (post['hasPendingEdit'] == true && auth?.uid == uid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.3))),
                ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 14),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'PENDING EDIT - Awaiting admin approval',
                            style: TextStyle(
                              color: Colors.blue, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 0.5
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              ),
            if (isAdminPost)
              GestureDetector(
                onTap: () => context.push('/feed/post/$postId'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VERIFIED INSTITUTIONAL UPDATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Featured ribbon
            if (isFeatured && !isAdminPost)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.amber.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'FEATURED POST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            if (isShared) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: (sharedByUserPhotoUrl != null && sharedByUserPhotoUrl.isNotEmpty)
                          ? NetworkImage(sharedByUserPhotoUrl)
                          : null,
                      child: (sharedByUserPhotoUrl == null || sharedByUserPhotoUrl.isEmpty)
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$sharedByUserName shared this',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(Icons.repeat_rounded, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
              if (shareCaption != null && shareCaption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    shareCaption!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Divider(indent: 16, endIndent: 16, height: 24),
            ],
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/$role/$uid'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final liveProfile = ref.watch(liveProfileProvider(uid));
                          return liveProfile.when(
                            data: (data) {
                              final currentPhoto = data?['profilePhotoUrl'] ?? profilePhotoUrl;
                              return CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.surfaceVariant,
                                backgroundImage: (currentPhoto != null && currentPhoto.isNotEmpty)
                                    ? NetworkImage(currentPhoto)
                                    : null,
                                child: (currentPhoto == null || currentPhoto.isEmpty)
                                    ? Icon(
                                        Icons.person,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        size: 22,
                                      )
                                    : null,
                              );
                            },
                            loading: () => CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (_, __) => CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/profile/$role/$uid'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final liveProfile = ref.watch(liveProfileProvider(uid));
                                    final currentName = liveProfile.asData?.value?['name'] ?? 
                                                        liveProfile.asData?.value?['fullName'] ?? 
                                                        name;
                                    return Text(
                                      currentName,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    );
                                  },
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                              ],
                              if (post['isAdmin'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Flexible prevents the timestamp from causing a Row overflow
                              Flexible(
                                child: Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.post['applicationStatus'] != null)
                              _buildStatusBadge(widget.post['applicationStatus']),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  _showPostOptionsPanel(
                                    context, 
                                    postId, 
                                    uid, 
                                    role == 'worker', 
                                    isJobPost
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 JOB DETAILS (IF APPLICABLE)
            if (isJobPost) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: GestureDetector(
                  onTap: () => context.push('/job/$postId'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.08),
                          theme.colorScheme.primary.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.work_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jobTitle,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (locationDisplay.isNotEmpty)
                                    Text(
                                      locationDisplay,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    color: Colors.green[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      jobSalary,
                                      style: TextStyle(
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'FT/PT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (isAvailabilityPost) ...[
              /// 🔹 WORKER AVAILABILITY (Looking for Work)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: GestureDetector(
                  onTap: () => context.push('/feed/post/$postId'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.08),
                          Colors.blue.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jobTitle, // Used for worker position
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (locationDisplay.isNotEmpty)
                                    Text(
                                      locationDisplay,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.available,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.request_quote_rounded,
                              color: Colors.blue[600],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "${AppLocalizations.of(context)!.asks}$jobSalary",
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (auth?.role == 'employer') ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    context.push('/profile/$role/$uid'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.hireMe,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (isEventPost) ...[
              /// 🔹 EVENT DETAILS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: GestureDetector(
                  onTap: () => context.push('/feed/post/$postId'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.08),
                          Colors.purple.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eventTitle!,
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (eventLocation != null && eventLocation.isNotEmpty)
                                    Text(
                                      eventLocation,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (eventDate != null) ...[
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.purple[400],
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${eventDate.day}/${eventDate.month}/${eventDate.year}",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (eventTime != null && eventTime.isNotEmpty) ...[
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.purple[400],
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eventTime,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            /// 🔹 CONTENT TEXT
            if (isJobPost)
              // Job posts → tap to read full description (don't show inline)
              GestureDetector(
                onTap: () => context.push('/job/$postId'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.tapToReadFullDescription,
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isAvailabilityPost)
              // Availability posts → tap to see full profile/details
              GestureDetector(
                onTap: () => context.push('/profile/$role/$uid'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.tapToViewFullProfile,
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Builder(
                  builder: (context) {
                    final locale = Localizations.localeOf(context);
                    final isHindi = locale.languageCode == 'hi';
                    final displayText = (isHindi && _showTranslated && _translatedText != null)
                        ? _translatedText!
                        : text;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParsedText(
                          text: displayText,
                          maxLines: _isExpanded ? null : 4,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (text.length > 200)
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _isExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        // ── Translate Button (Hindi mode only) ──
                        if (isHindi) ...
                          [
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _isTranslating ? null : () => _translatePost(text, 'hi'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isTranslating)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.translate_rounded, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isTranslating
                                        ? 'अनुवाद हो रहा है...'
                                        : (_showTranslated ? 'मूल दिखाएं' : 'हिंदी में अनुवाद करें'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    );
                  },
                ),
              ),

            /// 🔹 MEDIA GRID
            if (media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: PostMediaGrid(media: media, postId: postId),
              ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatIcon(
                    Icons.favorite_rounded,
                    "$likes",
                    Colors.redAccent,
                    theme,
                    () => _showLikers(context, postId),
                  ),
                  const SizedBox(width: 12),
                  if (auth != null && auth.uid != uid) ...[
                    Flexible(
                      child: _buildStatIcon(
                        Icons.send_rounded,
                        "",
                        Colors.blue,
                        theme,
                        () async {
                          final chatId = await ChatService.getOrCreateChat(auth.uid, uid, {
                            'name': name,
                            'profilePhotoUrl': profilePhotoUrl,
                          });
                          if (context.mounted && chatId.isNotEmpty) {
                            context.push('/chat/$chatId', extra: {
                              'name': name,
                              'photo': profilePhotoUrl,
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatIcon(
                      Icons.repeat_rounded,
                      "$shares",
                      theme.colorScheme.primary,
                      theme,
                      () => _sharePost(context, post),
                    ),
                  ],
                  const Spacer(),
                  // Like toggle
                  StreamBuilder<bool>(
                    stream: auth != null
                        ? PostService.isPostLiked(postId, auth.uid)
                        : Stream.value(false),
                    builder: (context, snapshot) {
                      final isLiked = snapshot.data ?? false;
                      return IconButton(
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: isLiked
                                  ? Colors.redAccent
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () {
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
                          )
                          .animate(target: isLiked ? 1 : 0)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.1, 1.1),
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                          );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.ios_share_rounded, // Use a more descriptive icon for system share
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      final String shareUrl = "https://kijobportal.com/post/$postId"; // Mock URL or deep link
                      Share.share(
                        'Check out this post on KI Job Portal by $name: \n\n"$text"\n\n$shareUrl',
                        subject: 'Professional Update from KI Job Portal',
                      );
                    },
                  ),
                ],
              ),
            ),

            if (auth != null && auth.uid != uid) ...[
              if (isJobPost && auth.role == 'worker') ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _showContactOptions(context, ref, auth, post),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.contact_phone_rounded, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.contactBtn,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: StreamBuilder<bool>(
                          stream: ref.read(applicationProvider).hasApplied(postId),
                          builder: (context, snapshot) {
                            final hasApplied = snapshot.data ?? false;
                            final worker = ref.watch(workerProvider);
                            return AnimatedContainer(
                              duration: 300.ms,
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: hasApplied || post['hiringStatus'] == 'paused' || post['hiringStatus'] == 'filled'
                                    ? null
                                    : () => _applyToJob(
                                        context,
                                        post,
                                        worker?.name ?? 'Karigar',
                                        auth.phone ?? '',
                                        worker?.profilePhotoUrl,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasApplied
                                      ? Colors.green[600]
                                      : theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.green[600]
                                      ?.withOpacity(0.15),
                                  disabledForegroundColor: Colors.green[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: hasApplied ? 0 : 4,
                                  shadowColor: theme.colorScheme.primary.withOpacity(
                                    0.4,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasApplied
                                            ? Icons.check_circle_rounded
                                            : Icons.bolt_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hasApplied
                                            ? AppLocalizations.of(context)!.alreadyApplied
                                            : post['hiringStatus'] == 'paused'
                                                ? 'Hiring Paused'
                                                : post['hiringStatus'] == 'filled'
                                                    ? 'Position Filled'
                                                    : AppLocalizations.of(context)!.applyForThisJob,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
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
                    ],
                  ),
                ),
              ] else if (isAvailabilityPost && auth.role == 'employer') ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _showContactOptions(context, ref, auth, post),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.contact_phone_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.contactBtn,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (!isJobPost) ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _showContactOptions(context, ref, auth, post),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.contact_phone_rounded, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.contactBtn,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'shortlisted':
        color = Colors.blue;
        icon = Icons.star_rounded;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      case 'hired':
        color = Colors.green;
        icon = Icons.celebration_rounded;
        break;
      case 'viewed':
        color = Colors.orange;
        icon = Icons.remove_red_eye_rounded;
        break;
      default:
        color = AppColors.primary;
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(
    IconData icon,
    String value,
    Color color,
    ThemeData theme,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Fetch target user data for contact info
      final targetUserData = await ref.read(publicProfileProvider(postUid).future);
      
      if (context.mounted) {
        // Use rootNavigator: true to ensure we pop the dialog
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (targetUserData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact information not available for this user.')),
          );
        }
        return;
      }

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
                            AppLocalizations.of(context)!.chooseHowToConnect,
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
                    title: AppLocalizations.of(context)!.callNow,
                    subtitle: phone,
                    color: Colors.green,
                    onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  ),
                if (email.isNotEmpty)
                  _buildContactMethod(
                    context: context,
                    icon: Icons.alternate_email_rounded,
                    title: AppLocalizations.of(context)!.sendEmail,
                    subtitle: email,
                    color: Colors.blue,
                    onTap: () => launchUrl(Uri.parse('mailto:$email')),
                  ),
                _buildContactMethod(
                  context: context,
                  icon: Icons.chat_bubble_rounded,
                  title: AppLocalizations.of(context)!.message,
                  subtitle: AppLocalizations.of(context)!.startChat,
                  color: theme.colorScheme.primary,
                  onTap: () async {
                    Navigator.pop(context);
                    final chatId = await ChatService.getOrCreateChat(auth.uid, postUid, targetUserData);
                    if (context.mounted && chatId.isNotEmpty) {
                      context.push('/chat/$chatId', extra: {
                        'name': name,
                        'photo': targetUserData['profilePhotoUrl'] ?? '',
                      });
                    }
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
}
