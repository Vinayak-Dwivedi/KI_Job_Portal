import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/analytics_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider = FutureProvider.autoDispose<PlatformStats>((ref) async {
  return AnalyticsService.getStats();
});

class AnalyticsService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<PlatformStats> getStats() async {
    // In a production app, do NOT count large collections this way without aggregation queries.
    // For demo/prototype purposes, we use count() queries which are optimized in Firestore.
    try {
      final workersQuery = await _firestore.collection('users').where('role', isEqualTo: 'worker').count().get();
      final employersQuery = await _firestore.collection('users').where('role', isEqualTo: 'employer').count().get();
      final jobsQuery = await _firestore.collection('jobs').count().get();
      final postsQuery = await _firestore.collection('posts').where('status', isEqualTo: 'pending').count().get();

      return PlatformStats(
        totalUsers: (workersQuery.count ?? 0) + (employersQuery.count ?? 0),
        totalWorkers: workersQuery.count ?? 0,
        totalEmployers: employersQuery.count ?? 0,
        totalJobs: jobsQuery.count ?? 0,
        pendingPosts: postsQuery.count ?? 0,
        totalRevenue: 59800, // Mock revenue data
      );
    } catch (e) {
      return PlatformStats.empty();
    }
  }
}
