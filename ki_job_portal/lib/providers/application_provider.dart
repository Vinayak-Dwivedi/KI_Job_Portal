import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import 'worker_provider.dart';

final applicationProvider = Provider((ref) => ApplicationService(ref));

class ApplicationService {
  final Ref _ref;
  ApplicationService(this._ref);

  Future<void> applyToJob({
    required Map<String, dynamic> post,
    required String workerName,
    required String workerPhone,
    String? workerImageUrl,
  }) async {
    final user = _ref.read(authProvider);
    if (user == null) throw Exception('User not logged in');

    final jobId = post['id'];
    final employerId = post['uid'];
    
    // Calculate cost based on salary
    int cost = 10;
    final salaryStr = post['jobSalary']?.toString() ?? '';
    // Extract numbers from salary string (e.g., "₹35000" -> 35000)
    final numbersOnly = salaryStr.replaceAll(RegExp(r'[^0-9]'), '');
    final salaryVal = int.tryParse(numbersOnly) ?? 0;
    
    if (salaryVal > 30000) {
      cost = 15;
    }

    final worker = _ref.read(workerProvider);
    if (worker == null || worker.credits < cost) {
      throw Exception('Insufficient credits. This application requires $cost credits.');
    }

    final applicationData = {
      'jobId': jobId,
      'employerId': employerId,
      'workerId': user.uid,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'workerImageUrl': workerImageUrl,
      'status': 'pending',
      'cost': cost,
      'appliedAt': FieldValue.serverTimestamp(),
    };

    // 1. Deduct Credits
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'credits': FieldValue.increment(-cost),
    });

    // 2. Create Application
    await FirebaseFirestore.instance.collection('applications').add(applicationData);
    
    // 3. Update Job Post
    await FirebaseFirestore.instance.collection('posts').doc(jobId).update({
      'applicantCount': FieldValue.increment(1),
    });

    // 4. Update Local State
    _ref.read(workerProvider.notifier).loadProfile(user.uid);
  }

  Stream<bool> hasApplied(String jobId) {
    final user = _ref.watch(authProvider);
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('workerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}

final userApplicationsProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('applications')
      .where('workerId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});
