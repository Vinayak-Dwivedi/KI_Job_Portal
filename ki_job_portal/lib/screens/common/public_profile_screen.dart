import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/public_user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../providers/worker_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/invite_service.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/review_service.dart';
import '../../providers/profile_stats_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/application_provider.dart';
import '../../widgets/profile/profile_charts.dart';
import '../../providers/relationship_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/profile/reviews_list_sheet.dart';
import '../../widgets/subscription/subscription_gate_widget.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String role;

  const PublicProfileScreen({super.key, required this.uid, required this.role});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logVisit();
    });
  }

  Future<void> _logVisit() async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null || currentUser.uid == widget.uid) return;

    // Get current user details to store in visitor record
    String? name;
    String? photo;
    
    if (currentUser.role == 'worker') {
      final worker = ref.read(workerProvider);
      name = worker?.name;
      photo = worker?.profilePhotoUrl;
    } else {
      final employer = ref.read(employerProvider);
      name = employer?.name;
      photo = employer?.profilePhotoUrl;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('visitors')
          .doc(currentUser.uid)
          .set({
        'uid': currentUser.uid,
        'name': name ?? 'A visitor',
        'photo': photo ?? '',
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging visit: $e');
    }
  }

  void _handleUnlock(BuildContext context, WidgetRef ref) async {
    final cleanUid = widget.uid.trim();
    final auth = ref.read(authProvider);
    if (auth == null) return;

    // Premium Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlock Contact Details'),
        content: const Text(
          'This will deduct 10 credits from your balance. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
        builder: (loadingContext) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      await FirestoreService.unlockContactInfo(
        viewerUid: auth.uid,
        targetUid: cleanUid,
      );

      ref.invalidate(isContactUnlockedProvider(cleanUid));
      ref.invalidate(userCreditsProvider);

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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Top Up Required ⚡'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              context.push('/subscription-plans');
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

  void _showInviteSheet(
    BuildContext context,
    WidgetRef ref,
    dynamic auth,
    String workerUid,
  ) async {
    final employer = ref.read(employerProvider);
    final jobsAsync = ref.read(employerJobsProvider(auth.uid));
    final jobs = jobsAsync.asData?.value ?? [];

    if (jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post a job first before sending invitations.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Filter only active jobs
    final activeJobs = jobs
        .where((j) => (j['hiringStatus'] ?? 'active') == 'active')
        .toList();
    if (activeJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active job posts to invite for.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite to Apply',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a job to invite this worker for:',
              style: TextStyle(
                color: AppColors.darkOnSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...activeJobs.map(
              (job) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  job['jobTitle']?.toString() ?? 'Job',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  job['location']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  
                  // 🔥 Show Message Customization Dialog
                  final messageController = TextEditingController(
                    text: 'Hi, we found your profile suitable for ${job['jobTitle']}. We\'d like to invite you to apply.',
                  );

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (msgCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Personalize Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Add a personal message to the candidate:',
                              style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: messageController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(msgCtx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final msg = messageController.text.trim();
                              Navigator.pop(msgCtx);
                              
                              try {
                                await InviteService.inviteWorker(
                                  employerUid: auth.uid,
                                  employerName: employer?.companyName ?? employer?.contactPersonName ?? 'Employer',
                                  workerUid: workerUid,
                                  jobId: job['id'],
                                  jobTitle: job['jobTitle'] ?? 'Job',
                                  message: msg,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Invitation sent successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: const Text('Send Invite'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUid = widget.uid.trim();
    final profileAsync = ref.watch(publicProfileProvider(cleanUid));
    final isContactUnlockedAsync = ref.watch(isContactUnlockedProvider(cleanUid));
    final creditsAsync = ref.watch(userCreditsProvider);
    final userPostsAsync = ref.watch(userPostsProvider(cleanUid));
    final auth = ref.watch(authProvider);
    final isOwner = auth?.uid == widget.uid;

    // ── Record Profile View handled in initState ──

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color ?? Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Theme.of(context).iconTheme.color ?? Colors.white),
            onPressed: () {
              final profileUrl = 'https://kijobportal.web.app/profile/${widget.role}/${widget.uid}';
              Share.share('Check out this profile on KI Job Portal: $profileUrl');
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: profileAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text(
                'Profile not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final name =
              data['name'] ??
              data['fullName'] ??
              (widget.role == 'employer' ? data['companyName'] : 'User');
          final profilePhoto = data['profilePhotoUrl'] ?? '';
          final String address = data['location'] is Map
              ? (data['location']['address'] ?? 'India')
              : (data['location'] ?? 'India');
          final String subLoc = data['location'] is Map
              ? (data['location']['subLocation'] ?? '')
              : (data['subLocation'] ?? '');
          final location = subLoc.isNotEmpty ? '$subLoc, $address' : address;
          final bio =
              data['bio'] ?? data['about'] ?? 'No description provided.';
          final skills = List<String>.from(data['skills'] ?? []);
          final experience = data['experience'] ?? 0;
          final isVerified = data['isVerified'] ?? false;
          final phone = data['phone'] ?? '';
          final email = data['email'] ?? '';
          final String userType =
              widget.role == 'admin' ? 'Official' : (data['businessType'] ??
              data['hirerSubType'] ??
              (widget.role == 'worker' ? 'Professional' : 'Company'));

          return isContactUnlockedAsync.when(
            data: (isUnlocked) {
              final showContact = isUnlocked || isOwner;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ── HEADER ──────────────────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFF59E0B),
                                Color(0xFFEA580C),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -50,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).cardColor,
                              backgroundImage: profilePhoto.isNotEmpty
                                  ? NetworkImage(profilePhoto)
                                  : null,
                              child: profilePhoto.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white60,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    /// ── BASIC INFO ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isVerified)
                                          Icon(
                                            Icons.verified,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final statsAsync = ref.watch(profileStatsProvider(cleanUid));
                                        return statsAsync.when(
                                          data: (stats) => stats.averageRating > 0 ? Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${stats.averageRating.toStringAsFixed(1)} (${stats.totalReviews} reviews)',
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ) : const SizedBox.shrink(),
                                          loading: () => const SizedBox.shrink(),
                                          error: (_, __) => const SizedBox.shrink(),
                                        );
                                      },
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$userType • ${widget.role.toUpperCase()}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isOwner && auth != null)
                                StreamBuilder<bool>(
                                  stream: ref
                                      .read(relationshipProvider)
                                      .isFollowing(widget.uid),
                                  builder: (context, snapshot) {
                                    final following = snapshot.data ?? false;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Follow/Unfollow
                                        ElevatedButton(
                                          onPressed: () {
                                            if (following) {
                                              ref
                                                  .read(relationshipProvider)
                                                  .unfollowUser(widget.uid);
                                            } else {
                                              ref
                                                  .read(relationshipProvider)
                                                  .followUser(widget.uid);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: following
                                                ? Theme.of(context).dividerColor.withOpacity(0.1)
                                                : AppColors.primary,
                                            foregroundColor: following 
                                                ? Theme.of(context).textTheme.bodyMedium?.color
                                                : Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            minimumSize: const Size(80, 32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            following ? 'Following' : 'Follow',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (auth.role == 'employer' &&
                                            widget.role == 'worker') ...[
                                          const SizedBox(height: 4),
                                          ElevatedButton.icon(
                                            onPressed: () => _showInviteSheet(
                                              context,
                                              ref,
                                              auth,
                                              widget.uid,
                                            ),
                                            icon: const Icon(
                                              Icons.mail_rounded,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Invite',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              minimumSize: const Size(80, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 🌟 Prominent Rate Button
                    Consumer(builder: (context, ref, _) {
                      final canRateAsync = ref.watch(canRateProvider(cleanUid));
                      final canRate = canRateAsync.value ?? false;
                      
                      if (auth?.uid == cleanUid) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleRatingTap(context, ref, auth?.uid, cleanUid, widget.role),
                            icon: Icon(Icons.star_rounded, size: 20, color: canRate ? Colors.white : Theme.of(context).disabledColor),
                            label: Text(
                              canRate ? 'LEAVE A RATING' : 'RATING LOCKED', 
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800, 
                                letterSpacing: 1,
                                color: canRate ? Colors.white : Theme.of(context).disabledColor
                              )
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canRate ? AppColors.primary : Theme.of(context).cardColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: canRate ? Colors.transparent : Theme.of(context).dividerColor),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.role == 'worker') ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.work_outline_rounded,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$experience Years exp',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          /// ── SOCIAL STATS ───────────────────────
                          Consumer(
                            builder: (context, ref, child) {
                              final statsAsync = ref.watch(profileStatsProvider(cleanUid));

                              return statsAsync.when(
                                data: (stats) {
                                  return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatItem('Posts', stats.totalApprovedPosts),
                                          _buildDivider(),
                                          StreamBuilder<int>(
                                            stream: ref.watch(relationshipProvider).getFollowerCount(cleanUid),
                                            builder: (context, snapshot) {
                                              return GestureDetector(
                                                onTap: () => _showUserListSheet(
                                                  context, 
                                                  ref, 
                                                  'Followers', 
                                                  ref.read(relationshipProvider).getFollowers(cleanUid)
                                                ),
                                                child: _buildStatItem('Followers', snapshot.data ?? 0),
                                              );
                                            }
                                          ),
                                          _buildDivider(),
                                          StreamBuilder<int>(
                                            stream: ref.watch(relationshipProvider).getFollowingCount(cleanUid),
                                            builder: (context, snapshot) {
                                              return GestureDetector(
                                                onTap: () => _showUserListSheet(
                                                  context, 
                                                  ref, 
                                                  'Following', 
                                                  ref.read(relationshipProvider).getFollowing(cleanUid)
                                                ),
                                                child: _buildStatItem('Following', snapshot.data ?? 0),
                                              );
                                            }
                                          ),
                                          _buildDivider(),
                                          GestureDetector(
                                            onTap: () => _showReviewsSheet(context, cleanUid),
                                            child: _buildStatItem('Rating', stats.averageRating.toInt(), isRating: true, avg: stats.averageRating),
                                          ),
                                        ],
                                      ),
                                  );
                                },
                                loading: () => const SizedBox(height: 40),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          /// ── CONTACT INFO (LOCKED/UNLOCKED) ─────
                          _buildContactSection(
                            context,
                            ref,
                            showContact,
                            phone,
                            email,
                            creditsAsync,
                            auth,
                          ),

                          const SizedBox(height: 32),

                          /// ── SKILLS ─────────────────────────────
                          if (skills.isNotEmpty) ...[
                            Text(
                              'Skills',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .map(
                                    (s) => Chip(
                                      label: Text(
                                        s,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      backgroundColor:
                                          AppColors.darkSurfaceContainerHighest,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 32),
                          ],

                          Text(
                            bio,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 32),

                          /// ── PORTFOLIO ──────────────────────────
                          _buildPortfolioSection(context, data),

                          const SizedBox(height: 32),

                          /// ── DOCUMENTS ──────────────────────────
                          _buildDocumentsSection(context, data),

                          const SizedBox(height: 32),

                          /// ── ANALYTICS & CHARTS ────────────────────
                          Text(
                            'Analytics & Performance',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ProfileCharts(uid: cleanUid, isOwner: auth?.uid == cleanUid),

                          const SizedBox(height: 32),

                          /// ── RECENT POSTS ───────────────────────
                          Text(
                            'Posts & Activity',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          userPostsAsync.when(
                            data: (posts) {
                              if (posts.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No posts yet',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
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
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, __) => Center(
                              child: Text(
                                'Error loading posts: $e',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, {bool isRating = false, double? avg}) {
    return Builder(builder: (context) {
      final textColor = Theme.of(context).colorScheme.onSurface;
      final subColor = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7);

      return Column(
        children: [
          Text(
            isRating && avg != null ? avg.toStringAsFixed(1) : value.toString(),
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: subColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContactSection(
    BuildContext context,
    WidgetRef ref,
    bool isUnlocked,
    String phone,
    String email,
    AsyncValue creditsAsync,
    dynamic auth,
  ) {
    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.contact_emergency_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'Contact Details',
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildContactItem(Icons.phone_iphone_rounded, phone.isNotEmpty ? phone : 'Not provided', context),
            const SizedBox(height: 16),
            _buildContactItem(Icons.mail_outline_rounded, email.isNotEmpty ? email : 'Not provided', context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.call_rounded,
                    label: 'CALL',
                    color: const Color(0xFF10B981),
                    onPressed: phone.isNotEmpty ? () => launchUrl(Uri.parse('tel:$phone')) : () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.message_rounded,
                    label: 'MESSAGE',
                    color: AppColors.primary,
                    onPressed: () async {
                      if (auth == null) return;
                      final profileData = ref.read(publicProfileProvider(widget.uid)).value;
                      if (profileData == null) return;
                      
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (loadingContext) => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                        
                        final chatId = await ChatService.getOrCreateChat(auth.uid, widget.uid, profileData);
                        if (context.mounted) Navigator.pop(context); // Close loading
                        
                        if (chatId.isNotEmpty) {
                          if (context.mounted) {
                            context.push('/chat/$chatId', extra: {
                              'name': profileData['name'] ?? profileData['fullName'] ?? 'User',
                              'photo': profileData['profilePhotoUrl'] ?? '',
                            });
                          }
                        }
                      } catch (e) {
                        debugPrint("Error opening chat: $e");
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 40,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Contact Information Locked',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock to view mobile number and email',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleUnlock(context, ref),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: const Text('Unlock with 10 Credits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

        ],
      ),
    );
  }

  Widget _buildPortfolioSection(BuildContext context, Map<String, dynamic> data) {
    final portfolio = data['portfolio'] as List?;
    if (portfolio == null || portfolio.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Portfolio',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: portfolio.length,
          itemBuilder: (context, index) {
            final item = portfolio[index] as Map;
            final url = item['url'] ?? '';
            final type = item['type'] ?? 'image';

            return GestureDetector(
              onTap: () {
                // Navigate to media viewer
                context.push('/media-viewer', extra: {
                  'media': portfolio.map((e) => {'url': e['url'], 'type': e['type']}).toList(),
                  'initialIndex': index,
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: type == 'image' ? DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ) : null,
                  color: AppColors.darkSurfaceContainerHighest,
                ),
                child: type == 'video' ? const Center(
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
                ) : null,
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildDocumentsSection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final docsList = data['documents'] as List?;
    if (docsList == null || docsList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents & Certifications',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ...docsList.map((docMap) {
          final name = docMap['name'] ?? 'Document';
          final url = docMap['url'] ?? '';
          final type = docMap['type'] ?? 'PDF';
          final timestamp = docMap['timestamp'] != null
              ? (docMap['timestamp'] as dynamic).toDate() as DateTime
              : DateTime.now();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkSurfaceContainerHighest),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type.toString().toLowerCase() == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded on ${timestamp.day}/${timestamp.month}/${timestamp.year}',
                        style: const TextStyle(
                          color: AppColors.darkOnSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  color: AppColors.primary,
                  onPressed: () async {
                    if (url.isNotEmpty) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _handleRatingTap(BuildContext context, WidgetRef ref, String? viewerUid, String targetUid, String targetRole) async {
    if (viewerUid == null) return;
    if (viewerUid == targetUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot rate yourself.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final canRate = await ref.read(canRateProvider(targetUid).future);
    if (canRate) {
      _showRatingDialog(context, ref, viewerUid);
    } else {
      final reviewerRole = ref.read(workerProvider) != null ? 'worker' : 'employer';
      final isSameRole = reviewerRole.toLowerCase() == targetRole.toLowerCase();

      String message = 'You must hire this user to leave a rating.';
      if (isSameRole) {
        message = 'You have already endorsed this colleague. Hire them for a new job to rate again.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primary.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, String? reviewerId) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate this User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How was your experience?',
                style: TextStyle(color: AppColors.darkOnSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = index + 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.orange,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(sbContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ReviewService.submitReview(
                  revieweeId: widget.uid,
                  rating: selectedRating,
                  comment: commentController.text.trim(),
                  reviewerId: reviewerId,
                );
                if (sbContext.mounted) {
                  Navigator.pop(sbContext);
                  if (success) {
                    ref.invalidate(profileStatsProvider(widget.uid.trim()));
                    ref.invalidate(canRateProvider(widget.uid.trim()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildContactItem(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  void _showUserListSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    Stream<List<String>> userIdsStream,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded, color: Theme.of(context).iconTheme.color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: userIdsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final uids = snapshot.data ?? [];
                  if (uids.isEmpty) {
                    return Center(
                      child: Text(
                        'No $title yet',
                        style: TextStyle(color: Theme.of(context).disabledColor),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: uids.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                    itemBuilder: (context, index) {
                      return Consumer(
                        builder: (context, ref, child) {
                          final userProfile = ref.watch(liveProfileProvider(uids[index]));
                          return userProfile.when(
                            data: (userData) {
                              if (userData == null) return const SizedBox.shrink();
                              final name = userData['name'] ?? userData['fullName'] ?? 'User';
                              final photo = userData['profilePhotoUrl'] ?? '';
                              final userRole = userData['role'] ?? 'worker';
                              final userType = userRole == 'admin' ? 'Official' : (userData['businessType'] ?? userData['hirerSubType'] ?? (userRole == 'worker' ? 'Professional' : 'Company'));

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  userType,
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/profile/$userRole/${uids[index]}');
                                },
                              );
                            },
                            loading: () => const ListTile(title: Text('Loading...')),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewsSheet(BuildContext context, String targetUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReviewsListSheet(uid: targetUid),
    );
  }
}
