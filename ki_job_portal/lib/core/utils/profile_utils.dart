class ProfileUtils {
  static double calculateStrength({
    required String name,
    required String phone,
    String? email,
    String? bio,
    String? location,
    List<dynamic>? skills,
    String? businessType,
    bool isVerified = false,
    bool isWorker = true,
  }) {
    double score = 0;

    // 1. Core Profile (30%)
    if (name.isNotEmpty) score += 10;
    if (phone.isNotEmpty) score += 10;
    if (email != null && email.isNotEmpty) score += 10;

    // 2. Identity & About (30%)
    if (bio != null && bio.isNotEmpty) score += 15;
    if (location != null && location.isNotEmpty) score += 15;

    // 3. Expertise (20%)
    if (isWorker) {
      if (skills != null && skills.isNotEmpty) score += 20;
    } else {
      if (businessType != null && businessType.isNotEmpty) score += 20;
    }

    // 4. Verification (20%) - Final boost for 100%
    if (isVerified) {
      score += 20;
    }

    return score.clamp(0, 100);
  }
}
