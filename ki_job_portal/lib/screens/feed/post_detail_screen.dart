import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/public_user_provider.dart';

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
          onPressed: () => context.pop(),
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
            onPressed: () {},
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
                          : [AppColors.primary.withOpacity(0.8), AppColors.primary],
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
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.work_outline_rounded, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      post['jobTitle'] ?? 'No Title',
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SALARY / RATE', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        post['jobSalary'] ?? 'Negotiable',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('LOCATION', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        post['location'] ?? 'Global',
                                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),
                      
                      // Description Header
                      Text(
                        'ABOUT THIS POST',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Main Content / Description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Text(
                          displayDescription,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontStyle: description.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Action Section
                      if (auth != null)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Action logic (Apply/Contact)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              isJobPost ? 'Apply for this Job' : (isAvailabilityPost ? 'Contact Worker' : 'Send Message'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
      ),
    );
  }
}
