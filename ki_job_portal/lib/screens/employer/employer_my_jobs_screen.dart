import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';

class EmployerMyJobsScreen extends ConsumerWidget {
  const EmployerMyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
            child: Text('Not signed in',
                style: TextStyle(color: theme.colorScheme.onSurface))),
      );
    }

    final myJobsAsyncValue = ref.watch(employerJobsProvider(user.uid));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Job Posts',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: myJobsAsyncValue.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: theme.cardColor, shape: BoxShape.circle),
                    child: Icon(Icons.assignment_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Text('Your job posts will appear here.',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'You haven\'t posted any jobs yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _EmployerJobCard(job: jobs[index], theme: theme)
                  .animate()
                  .fadeIn(delay: (index * 80).ms)
                  .slideY(begin: 0.05, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _EmployerJobCard extends ConsumerWidget {
  final Map<String, dynamic> job;
  final ThemeData theme;
  const _EmployerJobCard({required this.job, required this.theme});

  Future<void> _changeStatus(
      BuildContext context, String postId, String newStatus) async {
    try {
      await PostService.updateJobStatus(postId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Job marked as ${newStatus.toUpperCase()}.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _boostPost(
      BuildContext context, WidgetRef ref, String postId) async {
    final auth = ref.read(authProvider);
    if (auth == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Boost this Job Post?'),
        content: const Text(
            'This will deduct 50 credits and feature your job at the top of the feed for 7 days.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Boost — 50 Credits'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await PostService.featurePost(postId, auth.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job is now featured for 7 days!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String postId = job['id']?.toString() ?? '';
    final bool isVerified = job['isVerified'] == true;
    final bool isFeatured = job['isFeatured'] == true;
    final String title = job['jobTitle']?.toString() ?? 'Job Posting';
    final String company = job['companyName']?.toString() ?? 'Unknown Company';
    final String location = job['location']?.toString() ?? '';
    final String salary = job['jobSalary']?.toString() ?? 'Negotiable';
    final String hiringStatus = job['hiringStatus']?.toString() ?? 'active';
    final createdAt = job['createdAt'];
    final featuredUntil = job['featuredUntil'];

    String postedTime = 'Just now';
    if (createdAt is Timestamp) {
      postedTime = timeago.format(createdAt.toDate());
    }

    String? featuredUntilStr;
    if (featuredUntil is Timestamp) {
      final d = featuredUntil.toDate();
      featuredUntilStr = 'Featured until ${d.day}/${d.month}/${d.year}';
    }

    String profileUrl = job['profilePhotoUrl']?.toString() ?? '';

    // Status color
    Color statusColor;
    switch (hiringStatus) {
      case 'paused':
        statusColor = Colors.orange;
        break;
      case 'filled':
        statusColor = Colors.green;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFeatured
              ? Colors.amber.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured
                ? Colors.amber.withOpacity(0.15)
                : Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Banner
          if (isFeatured)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    featuredUntilStr ?? 'FEATURED',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                theme.colorScheme.primary.withOpacity(0.2)),
                        image: profileUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profileUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileUrl.isEmpty
                          ? Icon(Icons.business_rounded,
                              color: theme.colorScheme.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text('$company • $location',
                                    style: TextStyle(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.verified_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 14),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        hiringStatus.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SALARY RATE',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(salary,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.green[600],
                                letterSpacing: -0.5)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('POSTED',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(postedTime,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/job/$postId'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('VIEW APPLICANTS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Boost Button
                    if (!isFeatured)
                      _ActionIcon(
                        icon: Icons.bolt_rounded,
                        color: Colors.amber,
                        tooltip: 'Boost — 50 Credits',
                        onTap: () => _boostPost(context, ref, postId),
                      ),

                    const SizedBox(width: 8),

                    // Status Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        if (hiringStatus != 'active')
                          const PopupMenuItem(
                              value: 'active',
                              child: Row(children: [
                                Icon(Icons.play_arrow_rounded,
                                    color: Colors.green),
                                SizedBox(width: 8),
                                Text('Reopen Hiring')
                              ])),
                        if (hiringStatus != 'paused')
                          const PopupMenuItem(
                              value: 'paused',
                              child: Row(children: [
                                Icon(Icons.pause_rounded,
                                    color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Pause Hiring')
                              ])),
                        if (hiringStatus != 'filled')
                          const PopupMenuItem(
                              value: 'filled',
                              child: Row(children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Mark as Filled')
                              ])),
                      ],
                      onSelected: (val) =>
                          _changeStatus(context, postId, val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
