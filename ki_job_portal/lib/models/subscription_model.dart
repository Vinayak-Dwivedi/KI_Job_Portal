import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionTier {
  static const free = 'free';
  static const pro = 'pro';
  static const elite = 'elite';
}

class SubscriptionModel {
  final String userId;
  final String currentTier; // 'free', 'pro', 'elite'
  final DateTime? validUntil;
  final int maxApplicationsPerDay;
  final int usedApplicationsToday;
  final DateTime? lastApplicationDate;

  SubscriptionModel({
    required this.userId,
    this.currentTier = SubscriptionTier.free,
    this.validUntil,
    this.maxApplicationsPerDay = 3,
    this.usedApplicationsToday = 0,
    this.lastApplicationDate,
  });

  bool get isActive {
    if (currentTier == SubscriptionTier.free) return true;
    if (validUntil == null) return false;
    return DateTime.now().isBefore(validUntil!);
  }

  bool get canApplyForJob {
    if (currentTier == SubscriptionTier.elite) return true; // Unlimited? Assuming Elite is unlimited or higher
    
    // Reset used counter if it's a new day
    if (lastApplicationDate != null) {
      final now = DateTime.now();
      if (now.day != lastApplicationDate!.day || 
          now.month != lastApplicationDate!.month || 
          now.year != lastApplicationDate!.year) {
        return true; 
      }
    }
    return usedApplicationsToday < maxApplicationsPerDay;
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
    return SubscriptionModel(
      userId: data['userId'] ?? '',
      currentTier: data['currentTier'] ?? SubscriptionTier.free,
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      maxApplicationsPerDay: data['maxApplicationsPerDay'] ?? 3,
      usedApplicationsToday: data['usedApplicationsToday'] ?? 0,
      lastApplicationDate: (data['lastApplicationDate'] as Timestamp?)?.toDate(),
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
    };
  }
}
