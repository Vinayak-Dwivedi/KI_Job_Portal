class PlatformStats {
  final int totalUsers;
  final int totalWorkers;
  final int totalEmployers;
  final int totalJobs;
  final int pendingPosts;
  final int totalRevenue;

  PlatformStats({
    this.totalUsers = 0,
    this.totalWorkers = 0,
    this.totalEmployers = 0,
    this.totalJobs = 0,
    this.pendingPosts = 0,
    this.totalRevenue = 0,
  });

  factory PlatformStats.empty() => PlatformStats();
}
