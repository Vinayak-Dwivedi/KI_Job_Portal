import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines how a subscription plan controls usage.
/// - 'limits': user gets fixed quotas (contacts, applications, hires) per period
/// - 'credits': user gets a credits balance to spend freely
const String kLimitTypeCredits = 'credits';
const String kLimitTypeLimits = 'limits';

class SubscriptionPlan {
  final String id;
  final String name;
  final int price;
  final int durationDays;

  // ── Limit type toggle ──────────────────────────────────────────────────────
  /// 'credits' or 'limits' — admin chooses which model governs this plan
  final String limitType;

  // ── Credits mode fields (used when limitType == 'credits') ─────────────────
  /// Credits granted to the user's unified balance when this plan is purchased
  final int credits;

  // ── Limits mode fields (used when limitType == 'limits') ──────────────────
  /// Max contact unlocks per subscription period. null = unlimited.
  final int? maxContactUnlocks;
  /// Max job applications per subscription period. null = unlimited.
  final int? maxJobApplications;
  /// Max worker hires per subscription period. null = unlimited.
  final int? maxHires;

  // ── Legacy / shared ────────────────────────────────────────────────────────
  final int maxApplicationsPerDay; // kept for backward compat
  final List<String> features;
  final String color;
  final String description;

  // ── Admin-controlled badge ──────────────────────────────────────────────────
  /// Custom label the admin sets, e.g. "Most Popular", "Best Value", null = no badge
  final String? badgeLabel;
  /// Hex color for badge background, e.g. "#F43F5E". Defaults to red if not set.
  final String? badgeColor;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.limitType = kLimitTypeLimits,
    this.credits = 0,
    this.maxContactUnlocks,
    this.maxJobApplications,
    this.maxHires,
    this.maxApplicationsPerDay = 0,
    required this.features,
    this.color = '#1D4ED8',
    this.description = '',
    this.badgeLabel,
    this.badgeColor,
  });

  bool get isPopular => badgeLabel != null && badgeLabel!.isNotEmpty;

  factory SubscriptionPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlan(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Plan',
      price: data['price'] ?? 0,
      durationDays: data['durationDays'] ?? 30,
      limitType: data['limitType'] ?? kLimitTypeLimits,
      credits: data['credits'] ?? 0,
      maxContactUnlocks: data['maxContactUnlocks'] as int?,
      maxJobApplications: data['maxJobApplications'] as int?,
      maxHires: data['maxHires'] as int?,
      maxApplicationsPerDay: data['maxApplicationsPerDay'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
      color: data['color'] ?? '#1D4ED8',
      description: data['description'] ?? '',
      badgeLabel: data['badgeLabel'] as String?,
      badgeColor: data['badgeColor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'limitType': limitType,
      'credits': credits,
      if (maxContactUnlocks != null) 'maxContactUnlocks': maxContactUnlocks,
      if (maxJobApplications != null) 'maxJobApplications': maxJobApplications,
      if (maxHires != null) 'maxHires': maxHires,
      'maxApplicationsPerDay': maxApplicationsPerDay,
      'features': features,
      'color': color,
      'description': description,
      'badgeLabel': badgeLabel,
      'badgeColor': badgeColor,
    };
  }
}
