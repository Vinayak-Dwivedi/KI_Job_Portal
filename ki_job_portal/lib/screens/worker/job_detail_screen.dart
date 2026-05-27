import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/demo_data.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/rating_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/application_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isApplying = false;

  void _handleApply(String jobId, String uid, String name, String? photo) async {
    setState(() => _isApplying = true);
    try {
      await PostService.applyToJob(jobId, uid, {
        'name': name,
        'profilePhotoUrl': photo ?? '',
      });
      
      if (mounted) {
        setState(() => _isApplying = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRatingDialog(String employerId, String reviewerName, String? reviewerPhoto) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        title: 'Rate the Employer',
        onSubmit: (rating, comment) async {
          final auth = ref.read(authProvider);
          if (auth == null) return;

          await PostService.addReview(
            jobId: widget.jobId,
            revieweeId: employerId,
            reviewerId: auth.uid,
            reviewerName: reviewerName,
            reviewerPhoto: reviewerPhoto,
            rating: rating,
            comment: comment,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final worker = ref.watch(workerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: PostService.getPost(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Job not found', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/worker/dashboard');
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final job = snapshot.data!;
          final String title = job['jobTitle'] ?? job['title'] ?? 'Job Post';
          final String description = job['jobDescription'] ?? job['description'] ?? 'No description provided.';
          final String salary = job['jobSalary'] ?? 'Negotiable';
          final String experience = job['experience'] ?? 'Not specified';
          final String employerName = job['employerName'] ?? 'Employer';
          final String employerId = job['uid'] ?? '';
          
          final String skills = job['skills']?.toString() ?? '';
          final List<String> skillsList = skills.isNotEmpty 
              ? skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : [];

          return StreamBuilder<bool>(
            stream: PostService.hasUserApplied(widget.jobId, auth?.uid ?? ''),
            builder: (context, applySnap) {
              final bool hasApplied = applySnap.data ?? false;

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 160,
                        pinned: true,
                        backgroundColor: AppColors.darkSurface,
                        title: Text(
                          employerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, 
                            fontSize: 18, 
                            color: Colors.white
                          ),
                        ),
                        centerTitle: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.darkSurface, Color(0xFF1E242F)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Center(
                              child: Opacity(
                                opacity: 0.1,
                                child: Icon(Icons.business_rounded, size: 120, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/worker/dashboard');
                            }
                          },
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (hasApplied) ...[
                                StreamBuilder<String>(
                                  stream: ref.watch(applicationProvider).getApplicationStatus(widget.jobId),
                                  builder: (context, statusSnap) {
                                    final status = statusSnap.data ?? 'pending';
                                    return _ApplicationStatusCard(status: status);
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],
                              Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                    ),
                                    child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 36),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.w800, 
                                            color: Colors.white, 
                                            letterSpacing: -0.5
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, color: Colors.white54, size: 14),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                () {
                                                  final rawLoc = job['location'];
                                                  final String location = rawLoc is Map
                                                      ? (rawLoc['address'] ?? '')
                                                      : (rawLoc?.toString() ?? '');
                                                  final String? subLocation = rawLoc is Map
                                                      ? (rawLoc['subLocation'] ?? job['subLocation'])
                                                      : job['subLocation'];
                                                  return (subLocation != null && subLocation.isNotEmpty) 
                                                      ? '$location ($subLocation)' 
                                                      : (location.isNotEmpty ? location : 'Global');
                                                }(),
                                                style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _InfoTile(
                                    label: 'WAGE', 
                                    value: salary, 
                                    icon: Icons.payments_rounded, 
                                    color: Colors.teal
                                  ),
                                  _InfoTile(
                                    label: 'EXPERIENCE', 
                                    value: experience, 
                                    icon: Icons.star_rounded, 
                                    color: AppColors.primary
                                  ),
                                  const _InfoTile(
                                    label: 'STATUS', 
                                    value: 'Active', 
                                    icon: Icons.bolt_rounded, 
                                    color: Colors.orange
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
                              Text(
                                'Job Description', 
                                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description,
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white70, height: 1.6),
                              ),

                              if (skillsList.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                Text(
                                  'Required Skills', 
                                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skillsList.map((skill) => _SkillChip(skill)).toList(),
                                ),
                              ],

                              const SizedBox(height: 40),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 32),
                              
                              // ── Reviews Section ──────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Employer Reviews', 
                                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)
                                  ),
                                  if (hasApplied) 
                                    TextButton.icon(
                                      onPressed: () => _showRatingDialog(employerId, worker?.name ?? 'Anonymous', worker?.profilePhotoUrl),
                                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                                      label: const Text('Add Review'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: PostService.getReviewsForUser(employerId),
                                builder: (context, reviewSnap) {
                                  if (!reviewSnap.hasData || reviewSnap.data!.isEmpty) {
                                    return Text(
                                      'No reviews yet. Be the first to rate!',
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white38),
                                    );
                                  }
                                  
                                  return Column(
                                    children: reviewSnap.data!.map((review) => _ReviewCard(review: review)).toList(),
                                  );
                                },
                              ),

                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceContainer,
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white70),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: hasApplied || _isApplying || auth == null || job['hiringStatus'] == 'paused' || job['hiringStatus'] == 'filled' 
                                    ? null 
                                    : () => _handleApply(widget.jobId, auth.uid, worker?.name ?? 'Karigar', worker?.profilePhotoUrl),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasApplied ? const Color(0xFF10B981) : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isApplying 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      hasApplied 
                                          ? 'Already Applied' 
                                          : job['hiringStatus'] == 'paused' 
                                              ? 'Hiring Paused'
                                              : job['hiringStatus'] == 'filled'
                                                  ? 'Position Filled'
                                                  : 'Apply Now',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review['reviewerPhoto'] != null ? NetworkImage(review['reviewerPhoto']) : null,
                child: review['reviewerPhoto'] == null ? const Icon(Icons.person, size: 18, color: AppColors.primary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewerName'] ?? 'Anonymous',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (review['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: index < (review['rating'] ?? 0) ? Colors.amber : Colors.white24,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                'Today', 
                style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12)
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label, 
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;
  const _SkillChip(this.skill);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        skill,
        style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  final String status;
  const _ApplicationStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String description;

    switch (status.toLowerCase()) {
      case 'shortlisted':
        statusColor = Colors.blue;
        statusText = 'Shortlisted';
        statusIcon = Icons.star_rounded;
        description = 'Your application caught the employer\'s attention!';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Not Selected';
        statusIcon = Icons.cancel_rounded;
        description = 'The employer decided to go with another candidate.';
        break;
      case 'hired':
        statusColor = Colors.green;
        statusText = 'Hired!';
        statusIcon = Icons.celebration_rounded;
        description = 'Congratulations! You\'ve been hired for this job.';
        break;
      case 'viewed':
        statusColor = Colors.orange;
        statusText = 'Application Viewed';
        statusIcon = Icons.remove_red_eye_rounded;
        description = 'The employer has reviewed your profile.';
        break;
      default:
        statusColor = AppColors.primary;
        statusText = 'Application Pending';
        statusIcon = Icons.hourglass_top_rounded;
        description = 'Your application is waiting for review.';
    }

    final isPositive = ['shortlisted', 'hired'].contains(status.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28)
                    .animate(target: isPositive ? 1 : 0)
                    .shimmer(duration: 1200.ms, color: Colors.white)
                    .shake(delay: 500.ms),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatusTimeline(currentStatus: status.toLowerCase()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'id': 'pending', 'label': 'Applied', 'icon': Icons.check_circle_outline},
      {'id': 'viewed', 'label': 'Viewed', 'icon': Icons.remove_red_eye_outlined},
      {'id': 'shortlisted', 'label': 'Shortlisted', 'icon': Icons.star_outline},
      {'id': 'hired', 'label': 'Hired', 'icon': Icons.celebration_outlined},
    ];

    int currentIndex = stages.indexWhere((s) => s['id'] == currentStatus);
    if (currentStatus == 'rejected') currentIndex = 1; // Show as viewed but failed

    return Row(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = index <= currentIndex && currentStatus != 'rejected';
        final isCurrent = index == currentIndex;
        final isRejected = currentStatus == 'rejected' && index == 2; // Show rejection at shortlisted stage
        
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (index <= currentIndex ? Colors.green : Colors.white10))),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : (isCurrent ? Colors.amber : Colors.white10),
                      shape: BoxShape.circle,
                      border: isCurrent ? Border.all(color: Colors.white30, width: 2) : null,
                      boxShadow: isCurrent ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10)] : null,
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: index == stages.length - 1 ? Colors.transparent : (index < currentIndex ? Colors.green : Colors.white10))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stage['label'].toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: isCompleted || isCurrent ? Colors.white : Colors.white24,
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
