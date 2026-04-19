import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/public_user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/invite_service.dart';
import '../../providers/post_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../providers/relationship_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  final String role;

  const PublicProfileScreen({super.key, required this.uid, required this.role});

  void _handleUnlock(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    if (auth == null) return;

    // Premium Confirmation Dialog
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
        targetUid: uid,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  try {
                    await InviteService.inviteWorker(
                      employerUid: auth.uid,
                      employerName:
                          employer?.companyName ??
                          employer?.contactPersonName ??
                          'Employer',
                      workerUid: workerUid,
                      jobId: job['id'],
                      jobTitle: job['jobTitle'] ?? 'Job',
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
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanUid = uid.trim();
    final profileAsync = ref.watch(publicProfileProvider(cleanUid));
    final isUnlockedAsync = ref.watch(isContactUnlockedProvider(cleanUid));
    final creditsAsync = ref.watch(userCreditsProvider);
    final userPostsAsync = ref.watch(userPostsProvider(cleanUid));
    final auth = ref.watch(authProvider);
    final isOwner = auth?.uid == uid;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
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
              (role == 'employer' ? data['companyName'] : 'User');
          final profilePhoto = data['profilePhotoUrl'] ?? '';
          final location = data['location'] is Map
              ? (data['location']['address'] ?? 'India')
              : (data['location'] ?? 'India');
          final bio =
              data['bio'] ?? data['about'] ?? 'No description provided.';
          final skills = List<String>.from(data['skills'] ?? []);
          final experience = data['experience'] ?? 0;
          final isVerified = data['isVerified'] ?? false;
          final phone = data['phone'] ?? '';
          final email = data['email'] ?? '';
          final String userType =
              role == 'admin' ? 'Official' : (data['businessType'] ??
              data['hirerSubType'] ??
              (role == 'worker' ? 'Professional' : 'Company'));

          return isUnlockedAsync.when(
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
                              colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
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
                            decoration: const BoxDecoration(
                              color: AppColors.darkSurface,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.darkSurfaceContainerHighest,
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
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        if (isVerified)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.verified,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '$userType • ${role.toUpperCase()}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isOwner && auth != null)
                                StreamBuilder<bool>(
                                  stream: ref
                                      .read(relationshipProvider)
                                      .isFollowing(uid),
                                  builder: (context, snapshot) {
                                    final following = snapshot.data ?? false;
                                    return Row(
                                      children: [
                                        // Follow/Unfollow
                                        ElevatedButton(
                                          onPressed: () {
                                            if (following) {
                                              ref
                                                  .read(relationshipProvider)
                                                  .unfollowUser(uid);
                                            } else {
                                              ref
                                                  .read(relationshipProvider)
                                                  .followUser(uid);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: following
                                                ? Colors.white24
                                                : AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            following ? 'Following' : 'Follow',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        // Invite to Apply (employer only, viewing a worker)
                                        if (auth.role == 'employer' &&
                                            role == 'worker') ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _showInviteSheet(
                                              context,
                                              ref,
                                              auth,
                                              uid,
                                            ),
                                            icon: const Icon(
                                              Icons.mail_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Invite',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.darkOnSurfaceVariant,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(
                                  color: AppColors.darkOnSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              if (role == 'worker') ...[
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.work_outline_rounded,
                                  color: AppColors.darkOnSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$experience Years exp',
                                  style: const TextStyle(
                                    color: AppColors.darkOnSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          /// ── SOCIAL STATS ───────────────────────
                          StreamBuilder<Map<String, int>>(
                            stream: ref
                                .read(relationshipProvider)
                                .getStats(uid),
                            builder: (context, snapshot) {
                              final stats =
                                  snapshot.data ??
                                  {'followers': 0, 'following': 0};
                              return Row(
                                children: [
                                  _buildStatItem(
                                    'Followers',
                                    stats['followers']!,
                                  ),
                                  const SizedBox(width: 24),
                                  _buildStatItem(
                                    'Following',
                                    stats['following']!,
                                  ),
                                ],
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
                          ),

                          const SizedBox(height: 32),

                          /// ── SKILLS ─────────────────────────────
                          if (skills.isNotEmpty) ...[
                            const Text(
                              'Skills',
                              style: TextStyle(
                                color: Colors.white,
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
                            style: const TextStyle(
                              color: AppColors.darkOnSurfaceVariant,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 32),

                          /// ── DOCUMENTS ──────────────────────────
                          _buildDocumentsSection(context, data),

                          const SizedBox(height: 32),

                          /// ── RECENT POSTS ───────────────────────
                          const Text(
                            'Posts & Activity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          userPostsAsync.when(
                            data: (posts) {
                              if (posts.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No posts yet',
                                      style: TextStyle(
                                        color: AppColors.darkOnSurfaceVariant,
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

  Widget _buildStatItem(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkOnSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    WidgetRef ref,
    bool isUnlocked,
    String phone,
    String email,
    AsyncValue creditsAsync,
  ) {
    if (isUnlocked) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.phone_android_rounded,
              phone.isNotEmpty ? phone : "Not provided",
            ),
            const Divider(
              height: 24,
              color: AppColors.darkSurfaceContainerHighest,
            ),
            _buildInfoRow(
              Icons.email_outlined,
              email.isNotEmpty ? email : "Not provided",
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSurfaceContainerHighest),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 40,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact Information Locked',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock to view mobile number and email',
            style: TextStyle(
              color: AppColors.darkOnSurfaceVariant,
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
          creditsAsync.when(
            data: (data) {
              final balance = data?['balance'] ?? 0;
              return Text(
                'Your Balance: $balance Credits',
                style: const TextStyle(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (__, ___) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
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
        const Text(
          'Documents & Certifications',
          style: TextStyle(
            color: Colors.white,
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
}
