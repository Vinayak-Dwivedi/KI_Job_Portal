import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/review_provider.dart';
import '../../providers/public_user_provider.dart';
import '../../core/theme/app_colors.dart';

class ReviewsListSheet extends ConsumerWidget {
  final String uid;
  const ReviewsListSheet({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(uid));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ratings & Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: reviewsAsync.when(
                data: (reviews) => reviews.isEmpty
                    ? _buildEmptyState(context, 'No reviews yet')
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor.withOpacity(0.1)),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return ReviewItemWidget(review: review);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error loading reviews: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Theme.of(context).disabledColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).disabledColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewItemWidget extends ConsumerWidget {
  final Map<String, dynamic> review;
  const ReviewItemWidget({super.key, required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    final reviewerId = review['reviewerId'] as String?;

    // Use live profile for latest name/photo
    final reviewerProfileAsync = reviewerId != null ? ref.watch(liveProfileProvider(reviewerId)) : const AsyncValue.data(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        reviewerProfileAsync.when(
          data: (profile) {
            final name = profile?['name'] ?? profile?['fullName'] ?? review['reviewerName'] ?? 'Anonymous';
            final photo = profile?['profilePhotoUrl'] ?? review['reviewerPhoto'];
            final role = profile?['role'] ?? 'worker';

            return GestureDetector(
              onTap: reviewerId != null ? () {
                Navigator.pop(context); // Close sheet
                context.push('/profile/$role/$reviewerId');
              } : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.cardColor,
                    backgroundImage: photo != null && photo.toString().isNotEmpty ? NetworkImage(photo) : null,
                    child: photo == null || photo.toString().isEmpty ? const Icon(Icons.person, size: 20) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.orange,
                              size: 14,
                            )),
                            const SizedBox(width: 8),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt.toDate()),
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 20),
                ],
              ),
            );
          },
          loading: () => const ShimmerPlaceholder(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              comment,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: Colors.white10),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 12, color: Colors.white10),
            const SizedBox(height: 4),
            Container(width: 60, height: 10, color: Colors.white10),
          ],
        ),
      ],
    );
  }
}
