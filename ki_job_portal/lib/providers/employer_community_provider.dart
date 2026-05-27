import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

final employerHiredEmployeesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  return FirebaseFirestore.instance
      .collection('applications')
      .where('employerId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'hired')
      .snapshots()
      .map((snapshot) {
        final uniqueWorkers = <String, Map<String, dynamic>>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final workerId = data['workerId'] as String?;
          if (workerId != null) {
            uniqueWorkers.putIfAbsent(workerId, () => {
              'id': doc.id,
              ...data,
            });
          }
        }
        return uniqueWorkers.values.toList();
      });
});
