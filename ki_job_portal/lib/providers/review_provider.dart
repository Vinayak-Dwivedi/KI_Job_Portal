import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/review_service.dart';
import '../core/services/post_service.dart';
import 'auth_provider.dart';

final canRateProvider = FutureProvider.family<bool, String>((ref, targetUid) async {
  final user = ref.watch(authProvider);
  if (user == null) return false;
  
  return ReviewService.canRate(targetUid, currentUid: user.uid);
});

final userReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
  return PostService.getReviewsForUser(uid);
});
