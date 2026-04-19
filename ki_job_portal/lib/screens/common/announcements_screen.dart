import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/post_provider.dart';
import '../../core/theme/app_colors.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(systemAnnouncementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('System Announcements', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No announcements yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: announcements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = announcements[index];
              final String title = item['title'];
              final String message = item['message'];
              final Timestamp? createdAt = item['createdAt'];
              final String? postId = item['postId'];
              final String type = item['type'] ?? 'general';
              
              String timeStr = 'Some time ago';
              if (createdAt != null) {
                timeStr = timeago.format(createdAt.toDate());
              }

              Color iconColor = AppColors.primary;
              IconData iconData = Icons.notifications_active_rounded;
              
              if (type == 'success') {
                iconColor = Colors.green;
                iconData = Icons.check_circle_rounded;
              } else if (type == 'warning') {
                iconColor = Colors.orange;
                iconData = Icons.warning_rounded;
              } else if (type == 'error') {
                iconColor = Colors.red;
                iconData = Icons.error_rounded;
              }

              return InkWell(
                onTap: postId != null ? () => context.push('/feed/post/$postId') : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: iconColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(iconData, color: iconColor, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  type.toUpperCase(),
                                  style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.5),
                      ),
                      if (postId != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'View Post',
                              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
