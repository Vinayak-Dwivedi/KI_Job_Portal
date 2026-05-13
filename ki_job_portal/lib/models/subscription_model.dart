import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_plan_model.dart';

class SubscriptionTier {
  static const free = 'free';
  static const pro = 'pro';
  static const elite = 'elite';
}

class SubscriptionModel {
  final String userId;
  final String currentTier;
  final DateTime? validUntil;

  // ── Legacy daily limit (kept for backward compat) ─────────────────────────
  final int maxApplicationsPerDay;
  final int usedApplicationsToday;
  final DateTime? lastApplicationDate;

  // ── Limit type ────────────────────────────────────────────────────────────
  /// 'credits' or 'limits' — copied from the plan at purchase time
  final String limitType;

  // ── Period-based quotas (used when limitType == 'limits') ─────────────────
  final int? maxContactUnlocks;
  final int usedContactUnlocks;
  final int? maxJobApplications;
  final int usedJobApplications;
  final int? maxHires;
  final int usedHires;

  SubscriptionModel({
    required this.userId,
    this.currentTier = SubscriptionTier.free,
    this.validUntil,
    this.maxApplicationsPerDay = 3,
    this.usedApplicationsToday = 0,
    this.lastApplicationDate,
    this.limitType = kLimitTypeLimits,
    this.maxContactUnlocks,
    this.usedContactUnlocks = 0,
    this.maxJobApplications,
    this.usedJobApplications = 0,
    this.maxHires,
    this.usedHires = 0,
  });

  bool get isActive {
    if (currentTier == SubscriptionTier.free) return true;
    if (validUntil == null) return false;
    return DateTime.now().isBefore(validUntil!);
  }

  bool get canApplyForJob {
    if (!isActive) return false;
    if (limitType == kLimitTypeCredits) return true; // Credits mode — no application limit
    if (maxJobApplications == null) return true; // null = unlimited
    return usedJobApplications < maxJobApplications!;
  }

  bool get canUnlockContact {
    if (!isActive) return false;
    if (limitType == kLimitTypeCredits) return true;
    if (maxContactUnlocks == null) return true;
    return usedContactUnlocks < maxContactUnlocks!;
  }

  bool get canHireWorker {
    if (!isActive) return false;
    if (limitType == kLimitTypeCredits) return true;
    if (maxHires == null) return true;
    return usedHires < maxHires!;
  }

  int get contactUnlocksRemaining {
    if (maxContactUnlocks == null) return 999999;
    return (maxContactUnlocks! - usedContactUnlocks).clamp(0, maxContactUnlocks!);
  }

  int get jobApplicationsRemaining {
    if (maxJobApplications == null) return 999999;
    return (maxJobApplications! - usedJobApplications).clamp(0, maxJobApplications!);
  }

  int get hiresRemaining {
    if (maxHires == null) return 999999;
    return (maxHires! - usedHires).clamp(0, maxHires!);
  }

  int get daysRemaining {
    if (validUntil == null) return 0;
    final diff = validUntil!.difference(DateTime.now());
    return diff.inDays;
  }

  String get validityString {
    if (validUntil == null) return "Expired";
    final days = daysRemaining;
    if (days < 0) return "Expired";
    if (days == 0) return "Expires today!";
    return "$days days remaining";
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
    return SubscriptionModel(
      userId: data['userId'] ?? '',
      currentTier: data['currentTier'] ?? SubscriptionTier.free,
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      maxApplicationsPerDay: data['maxApplicationsPerDay'] ?? 3,
      usedApplicationsToday: data['usedApplicationsToday'] ?? 0,
      lastApplicationDate: (data['lastApplicationDate'] as Timestamp?)?.toDate(),
      limitType: data['limitType'] ?? kLimitTypeLimits,
      maxContactUnlocks: data['maxContactUnlocks'] as int?,
      usedContactUnlocks: data['usedContactUnlocks'] ?? 0,
      maxJobApplications: data['maxJobApplications'] as int?,
      usedJobApplications: data['usedJobApplications'] ?? 0,
      maxHires: data['maxHires'] as int?,
      usedHires: data['usedHires'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentTier': currentTier,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'maxApplicationsPerDay': maxApplicationsPerDay,
      'usedApplicationsToday': usedApplicationsToday,
      'lastApplicationDate': lastApplicationDate != null ? Timestamp.fromDate(lastApplicationDate!) : null,
      'limitType': limitType,
      if (maxContactUnlocks != null) 'maxContactUnlocks': maxContactUnlocks,
      'usedContactUnlocks': usedContactUnlocks,
      if (maxJobApplications != null) 'maxJobApplications': maxJobApplications,
      'usedJobApplications': usedJobApplications,
      if (maxHires != null) 'maxHires': maxHires,
      'usedHires': usedHires,
    };
  }
}
