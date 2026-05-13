import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/pdf_export_service.dart';
import '../../screens/admin/admin_promotions_screen.dart';
import '../../screens/admin/admin_plans_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () {
              // Sign out logic
              context.go('/splash');
            },
          )
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(analyticsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildStatCardsRow(context, 'Total Users', '${stats.totalUsers}', Icons.people, const Color(0xFF3B82F6), 'Workers: ${stats.totalWorkers} | Employers: ${stats.totalEmployers}'),
                const SizedBox(height: 16),
                _buildStatCardsRow(context, 'Pending Posts', '${stats.pendingPosts}', Icons.pending_actions, const Color(0xFFF59E0B), 'Awaiting Review'),
                const SizedBox(height: 16),
                _buildStatCardsRow(context, 'Total Jobs', '${stats.totalJobs}', Icons.work, const Color(0xFF10B981), 'Active Job Listings'),
                const SizedBox(height: 16),
                _buildStatCardsRow(context, 'Total Revenue', '₹${stats.totalRevenue}', Icons.attach_money, const Color(0xFF6366F1), 'Razorpay Payments Test'),
                
                const SizedBox(height: 48),
                const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                
                _buildActionCard(context, 'Moderate Reports & Posts', Icons.gavel, () => context.push('/admin/posts')),
                const SizedBox(height: 12),
                _buildActionCard(context, 'Manage & Ban Users', Icons.group_remove, () => context.push('/admin/users')),
                const SizedBox(height: 12),
                _buildActionCard(context, 'Manage Promotions (Ads/Plans)', Icons.campaign, () => context.push('/admin/promotions')),
                const SizedBox(height: 12),
                _buildActionCard(context, 'Manage Plans & Credit Packs', Icons.subscriptions, () => context.push('/admin/plans')),
                const SizedBox(height: 12),
                _buildActionCard(context, 'Export Analytics Report (PDF)', Icons.picture_as_pdf, () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
                  await PdfExportService.exportAnalyticsReport(stats);
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load stats: $e')),
      ),
    );
  }

  Widget _buildStatCardsRow(BuildContext context, String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D4ED8)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
