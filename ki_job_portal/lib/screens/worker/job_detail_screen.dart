import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/demo_data.dart';
import '../../core/services/post_service.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;

  void _handleApply() async {
    setState(() => _isApplying = true);
    
    // Simulate application process
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isApplying = false;
        _hasApplied = true;
      });
      
      // Auto-dismiss or show success
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: PostService.getPost(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  const Text('Job not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            );
          }

          final job = snapshot.data!;
          final String title = job['jobTitle'] ?? job['title'] ?? 'Job Post';
          final String salary = job['jobSalary'] ?? 'Negotiable';
          final String experience = job['jobExperience'] ?? 'Not specified';
          final String skills = job['jobSkills'] ?? '';
          final List<String> skillsList = skills.isNotEmpty 
              ? skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : [];
          final String description = job['text'] ?? job['description'] ?? 'No description provided.';
          final String employerName = job['name'] ?? job['employerName'] ?? 'Employer';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Modern AppBar ───────────────────────────
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        employerName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: Container(color: Theme.of(context).colorScheme.primary),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),

                  // ── Job Header ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.business_rounded, color: Theme.of(context).colorScheme.primary, size: 36),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 14),
                                        const SizedBox(width: 4),
                                        Text(job['location']?.toString() ?? 'Global', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Detailed Info Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _InfoTile(
                                label: 'WAGE', 
                                value: salary, 
                                icon: Icons.payments_rounded, 
                                color: Colors.green
                              ),
                              _InfoTile(
                                label: 'EXPERIENCE', 
                                value: experience, 
                                icon: Icons.star_rounded, 
                                color: Colors.blue
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
                          Text('Job Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
                          ),

                          if (skillsList.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text('Required Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skillsList.map((skill) => _SkillChip(skill)).toList(),
                            ),
                          ],

                          const SizedBox(height: 120), // Bottom padding for FAB
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom Navigation Bar ───────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.bookmark_border_rounded, color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            // TODO: Add bookmark logic
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _hasApplied || _isApplying ? null : _handleApply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasApplied ? const Color(0xFF10B981) : Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isApplying 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Text(
                                  _hasApplied ? 'Applied Successfully' : 'Apply Now',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Success Overlay ─────────────────────────
              if (_hasApplied)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.network(
                          'https://assets10.lottiefiles.com/packages/lf20_awS8Y6.json', // Checkmark animation
                          width: 200,
                          height: 200,
                          repeat: false,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Application Sent!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The employer has been notified.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),
            ],
          );
        },
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Text(
        skill,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
