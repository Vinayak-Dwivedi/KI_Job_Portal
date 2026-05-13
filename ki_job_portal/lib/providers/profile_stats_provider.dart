import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyData {
  final String label; // e.g. "Jan", "Feb"
  final int month;
  final int year;
  final double value;

  MonthlyData({
    required this.label,
    required this.month,
    required this.year,
    required this.value,
  });
}

class RatingDistribution {
  final int star; // 1–5
  final int count;

  RatingDistribution({required this.star, required this.count});
}

class ProfileStats {
  final List<MonthlyData> earningsTrend; // Last 6 months credit activity
  final List<MonthlyData> jobActivity; // Jobs applied/posted per month
  final List<RatingDistribution> ratingBreakdown; // 1★–5★ counts
  final double averageRating;
  final int totalReviews;
  final int totalJobsCompleted;
  final int totalCreditsEarned;
  final int currentBalance;
  final int totalApprovedPosts;

  ProfileStats({
    required this.earningsTrend,
    required this.jobActivity,
    required this.ratingBreakdown,
    required this.averageRating,
    required this.totalReviews,
    required this.totalJobsCompleted,
    required this.totalCreditsEarned,
    required this.currentBalance,
    required this.totalApprovedPosts,
  });

  factory ProfileStats.empty() => ProfileStats(
        earningsTrend: [],
        jobActivity: [],
        ratingBreakdown: List.generate(
            5, (i) => RatingDistribution(star: 5 - i, count: 0)),
        averageRating: 0,
        totalReviews: 0,
        totalJobsCompleted: 0,
        totalCreditsEarned: 0,
        currentBalance: 0,
        totalApprovedPosts: 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final profileStatsProvider =
    FutureProvider.family<ProfileStats, String>((ref, uid) async {
  final firestore = FirebaseFirestore.instance;

  // ── 1. Earnings Trend (last 6 months) ──────────────────────────────────
  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

  List<MonthlyData> earningsTrend = [];
  int totalCreditsEarned = 0;

  try {
    final txSnap = await firestore
        .collection('contactCredits')
        .doc(uid)
        .collection('transactions')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
        .orderBy('createdAt')
        .get();

    // Group by month
    final Map<String, double> monthlyTotals = {};
    for (final doc in txSnap.docs) {
      final data = doc.data();
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      final key = '${date.year}-${date.month}';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final type = data['type'] ?? 'debit';

      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + amount;
      if (type == 'credit') totalCreditsEarned += amount.toInt();
    }

    // Build 6-month series
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month}';
      earningsTrend.add(MonthlyData(
        label: monthNames[d.month - 1],
        month: d.month,
        year: d.year,
        value: monthlyTotals[key] ?? 0,
      ));
    }
  } catch (e) {
    debugPrint("Error fetching earnings trend: $e");
      // If collection doesn't exist, leave empty
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        earningsTrend.add(MonthlyData(
          label: monthNames[d.month - 1],
          month: d.month,
          year: d.year,
          value: 0,
        ));
      }
    }

    // ── 2. Job Activity (last 6 months) ────────────────────────────────────
    List<MonthlyData> jobActivity = [];
    int totalJobsCompleted = 0;
    int totalApprovedPosts = 0;

    try {
      // Check posts created by this user (job posts or social posts)
      // Note: Some legacy posts might use 'userId' instead of 'uid'
      // Total posts (all time)
      final allPostsSnap = await firestore
          .collection('posts')
          .where('uid', isEqualTo: uid)
          .get();
      
      final postsDocs = allPostsSnap.docs.isNotEmpty 
          ? allPostsSnap.docs 
          : (await firestore.collection('posts').where('userId', isEqualTo: uid).get()).docs;

      final Map<String, double> monthlyJobs = {};
      for (final doc in postsDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;

        final date = ts.toDate();
        if (date.isAfter(sixMonthsAgo)) {
          final key = '${date.year}-${date.month}';
          monthlyJobs[key] = (monthlyJobs[key] ?? 0) + 1;
        }
      }
      
      totalApprovedPosts = postsDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Default to 'approved' for legacy posts that don't have a status field
        return (data['status'] ?? 'approved') == 'approved';
      }).length;

      totalJobsCompleted = postsDocs.length;

      // ── 2b. Add Applications to activity (for workers) ────────────────────
      final appsSnap = await firestore
          .collection('applications')
          .where('workerId', isEqualTo: uid)
          .get();

      for (final doc in appsSnap.docs) {
        final data = doc.data();
        final ts = (data['appliedAt'] ?? data['createdAt']) as Timestamp?;
        if (ts == null) continue;

        final date = ts.toDate();
        // Only count if within 6 months
        if (date.isBefore(sixMonthsAgo)) continue;

        final key = '${date.year}-${date.month}';
        monthlyJobs[key] = (monthlyJobs[key] ?? 0) + 1;
      }

      totalJobsCompleted += appsSnap.docs.length;

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month}';
      jobActivity.add(MonthlyData(
        label: monthNames[d.month - 1],
        month: d.month,
        year: d.year,
        value: monthlyJobs[key] ?? 0,
      ));
    }
  } catch (e) {
    debugPrint("Error fetching job activity: $e");
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        jobActivity.add(MonthlyData(
          label: monthNames[d.month - 1],
          month: d.month,
          year: d.year,
          value: 0,
        ));
      }
    }

  // ── 3. Rating Breakdown ────────────────────────────────────────────────
  List<RatingDistribution> ratingBreakdown =
      List.generate(5, (i) => RatingDistribution(star: 5 - i, count: 0));
  double averageRating = 0;
  int totalReviews = 0;

  try {
    final reviewsSnap = await firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: uid)
        .get();

    final reviewsDocs = reviewsSnap.docs.isNotEmpty 
        ? reviewsSnap.docs 
        : (await firestore.collection('reviews').where('targetId', isEqualTo: uid).get()).docs;

    if (reviewsDocs.isNotEmpty) {
      final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      totalReviews = reviewsDocs.length;
      debugPrint("Fetched $totalReviews reviews for $uid");
      double ratingSum = 0;

      for (final doc in reviewsDocs) {
        final r = (doc.data()['rating'] as num?)?.toDouble() ?? 0;
        debugPrint("Review rating: $r");
        if (r >= 1 && r <= 5) {
          counts[r.toInt()] = (counts[r.toInt()] ?? 0) + 1;
          ratingSum += r;
        }
      }

      averageRating = totalReviews > 0 ? ratingSum / totalReviews : 0;
      debugPrint("Calculated avg: $averageRating");
      ratingBreakdown = counts.entries
          .map((e) => RatingDistribution(star: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.star.compareTo(a.star));
    }
  } catch (e) {
    debugPrint("Error fetching reviews: $e");
  }

  // ── 4. Current Balance ──────────────────────────────────────────────────
  int currentBalance = 0;
  try {
    final userSnap = await firestore.collection('users').doc(uid).get();
    if (userSnap.exists) {
      currentBalance = (userSnap.data()?['credits'] as num?)?.toInt() ?? 0;
    }
  } catch (e) {
    debugPrint("Error fetching balance: $e");
  }

  return ProfileStats(
    earningsTrend: earningsTrend,
    jobActivity: jobActivity,
    ratingBreakdown: ratingBreakdown,
    averageRating: averageRating,
    totalReviews: totalReviews,
    totalJobsCompleted: totalJobsCompleted,
    totalCreditsEarned: totalCreditsEarned,
    currentBalance: currentBalance,
    totalApprovedPosts: totalApprovedPosts,
  );
});
