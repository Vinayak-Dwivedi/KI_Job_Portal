import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/invite_provider.dart';
import '../../core/services/post_service.dart';
import '../../core/services/invite_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/feed/post_card.dart';


class WorkerJobsScreen extends ConsumerStatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  ConsumerState<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends ConsumerState<WorkerJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = ref.watch(workerProvider);
    final pendingInvites = ref.watch(pendingInvitesCountProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Premium App Bar ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MY CAREER',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5)),
                        SizedBox(height: 4),
                        Text('Job Applications',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE5E7EB),
                                letterSpacing: -0.5)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search_rounded, color: Color(0xFFE5E7EB)),
                          tooltip: 'Search Jobs',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF2563EB), width: 1.5)),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF1E293B),
                            backgroundImage: worker?.localImageFile != null
                                ? FileImage(worker!.localImageFile!)
                                : null,
                            child: worker?.localImageFile == null
                                ? const Icon(Icons.person,
                                    color: Color(0xFFE5E7EB), size: 20)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Modern Tab Bar ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12),
                    tabs: [
                      const Tab(text: 'New'),
                      const Tab(text: 'Applied'),
                      const Tab(text: 'Saved'),
                      Tab(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Text('Invites'),
                            if (pendingInvites > 0)
                              Positioned(
                                top: -6,
                                right: -14,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '$pendingInvites',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Job Filters ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(jobFilterProvider.notifier).updateFilter((s) => s.copyWith(searchQuery: val)),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search jobs, companies...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewJobsTab(),
                _buildAppliedTab(),
                _buildSavedTab(),
                _buildInvitesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _JobFilterSheet(),
    );
  }

  Widget _buildNewJobsTab() {
    final jobsAsyncValue = ref.watch(jobFeedProvider);

    return jobsAsyncValue.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return _buildPlaceholderTab(
              'No new jobs available.', Icons.search_off_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            return PostCard(post: jobs[index])
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildAppliedTab() {
    final jobsAsync = ref.watch(workerAppliedJobsProvider);

    return jobsAsync.when(
      data: (jobs) => ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _SuccessRateCard()
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          Text('MY APPLICATIONS',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          if (jobs.isEmpty)
            _buildSmallPlaceholder(
                'No applications yet.', Icons.history_rounded)
          else
            ...jobs.map((job) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(post: job)
                      .animate()
                      .fadeIn()
                      .slideX(begin: 0.1, end: 0),
                )),
          const SizedBox(height: 32),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSavedTab() {
    final savedAsync = ref.watch(savedJobsProvider);
    final auth = ref.read(authProvider);

    return savedAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return _buildPlaceholderTab(
              'No saved jobs yet.\nBookmark posts to view them here.',
              Icons.bookmark_border_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Stack(
              children: [
                PostCard(post: job)
                    .animate()
                    .fadeIn(delay: (index * 80).ms)
                    .slideY(begin: 0.05, end: 0),
                // Unsave button in top right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      if (auth != null) {
                        await PostService.unsaveJob(auth.uid, job['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job removed from saved.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bookmark_remove_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildInvitesTab() {
    final invitesAsync = ref.watch(workerInvitationsProvider);
    final theme = Theme.of(context);

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return _buildPlaceholderTab(
              'No invitations yet.\nEmployers can invite you to apply for jobs.',
              Icons.mail_outline_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final inv = invites[index];
            final status = inv['status']?.toString() ?? 'pending';
            final isPending = status == 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPending
                      ? AppColors.primary.withOpacity(0.3)
                      : theme.dividerColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mail_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv['jobTitle']?.toString() ?? 'Job Invite',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                                'From: ${inv['employerName']?.toString() ?? 'Employer'}',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'accepted'
                              ? Colors.green.withOpacity(0.1)
                              : status == 'declined'
                                  ? Colors.red.withOpacity(0.1)
                                  : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: status == 'accepted'
                                ? Colors.green
                                : status == 'declined'
                                    ? Colors.red
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (inv['message'] != null && inv['message'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        inv['message'],
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _respondInvite(inv['id'], 'declined'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Decline',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _respondInvite(inv['id'], 'accepted');
                              context.push('/job/${inv['jobId']}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Accept & View',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could not load invitations',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString().replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respondInvite(String inviteId, String status) async {
    try {
      await InviteService.respondToInvitation(inviteId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted'
                ? 'Invitation accepted!'
                : 'Invitation declined.'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSmallPlaceholder(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(icon,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor, shape: BoxShape.circle),
            child: Icon(icon,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
                size: 48),
          ),
          const SizedBox(height: 20),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn();
  }
}


class _SuccessRateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              right: -30,
              bottom: -30,
              child: Icon(Icons.trending_up_rounded,
                  color: Colors.white.withOpacity(0.1), size: 160)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Text('MATCH SCORE',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('85.4%',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Top 12% in Bengaluru',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              const Text(
                  'Your profile responsiveness is improving your visibility to top employers.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobFilterSheet extends ConsumerWidget {
  const _JobFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(jobFilterProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Filter Jobs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          
          _filterLabel('Location'),
          const SizedBox(height: 12),
          _buildFilterField(
            initialValue: filter.location,
            hint: 'City, State or Area',
            onChanged: (val) => ref.read(jobFilterProvider.notifier).updateFilter((s) => s.copyWith(location: val)),
            theme: theme,
          ),
          
          const SizedBox(height: 24),
          _filterLabel('Category'),
          const SizedBox(height: 12),
          _buildFilterField(
            initialValue: filter.category,
            hint: 'E.g. Electrician, Delivery...',
            onChanged: (val) => ref.read(jobFilterProvider.notifier).updateFilter((s) => s.copyWith(category: val)),
            theme: theme,
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Show Results', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(jobFilterProvider.notifier).setFilter(JobFilter());
                Navigator.pop(context);
              },
              child: const Text('Reset All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)));
  }

  Widget _buildFilterField({String? initialValue, required String hint, required Function(String) onChanged, required ThemeData theme}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        onChanged: onChanged,
        controller: TextEditingController(text: initialValue)..selection = TextSelection.collapsed(offset: initialValue?.length ?? 0),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
