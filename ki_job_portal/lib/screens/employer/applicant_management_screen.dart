import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/review_provider.dart';

class ApplicantManagementScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ApplicantManagementScreen({super.key, required this.jobId});

  @override
  ConsumerState<ApplicantManagementScreen> createState() => _ApplicantManagementScreenState();
}

class _ApplicantManagementScreenState extends ConsumerState<ApplicantManagementScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Applicants', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PostService.getApplicants(widget.jobId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var applicants = snapshot.data ?? [];
                
                if (_selectedFilter != 'all') {
                  applicants = applicants.where((a) => a['status'] == _selectedFilter).toList();
                }

                if (applicants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all' ? 'No applicants yet' : 'No $_selectedFilter applicants', 
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: applicants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];
                    return _ApplicantCard(applicant: applicant, jobId: widget.jobId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'pending', 'label': 'Pending'},
      {'id': 'shortlisted', 'label': 'Shortlisted'},
      {'id': 'hired', 'label': 'Hired'},
      {'id': 'rejected', 'label': 'Rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedFilter = f['id']!),
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white60,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.white10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  final Map<String, dynamic> applicant;
  final String jobId;
  const _ApplicantCard({required this.applicant, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String name = applicant['name'] ?? 'Worker';
    final String photo = applicant['profilePhotoUrl'] ?? '';
    final String status = applicant['status'] ?? 'pending';
    final String uid = applicant['uid'] ?? '';
    final appliedAt = applicant['appliedAt'];

    Color statusColor = Colors.grey;
    if (status == 'shortlisted') statusColor = Colors.blue;
    if (status == 'hired') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/worker/$uid'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      if (appliedAt != null)
                        Text(
                          'Applied ${timeago.format(appliedAt.toDate())}',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/profile/worker/$uid'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('VIEW PROFILE'),
                ),
              ),
              const SizedBox(width: 12),
              if (status == 'pending') ...[
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  onPressed: () => PostService.updateApplicationStatus(jobId, uid, 'rejected'),
                ),
                IconButton(
                  tooltip: 'Shortlist',
                  icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.blue),
                  onPressed: () => PostService.updateApplicationStatus(jobId, uid, 'shortlisted'),
                ),
                IconButton(
                  tooltip: 'Hire Worker',
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.green),
                  onPressed: () => _showHireConfirmation(context, ref, name, jobId, uid),
                ),
              ],
              if (status != 'pending')
                TextButton(
                  onPressed: () => PostService.updateApplicationStatus(jobId, uid, 'pending'),
                  child: const Text('RESET'),
                ),
            ],
          ),
        ],
      ),
    );
  }
  void _showHireConfirmation(BuildContext context, WidgetRef ref, String name, String jobId, String workerUid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hire $name?'),
        content: const Text('This will mark the worker as hired. You can now leave a rating for each other.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await PostService.updateApplicationStatus(jobId, workerUid, 'hired');
              ref.invalidate(canRateProvider(workerUid));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('CONFIRM HIRE'),
          ),
        ],
      ),
    );
  }
}
