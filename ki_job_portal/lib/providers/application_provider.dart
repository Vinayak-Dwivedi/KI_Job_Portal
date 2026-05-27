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
    final numbersOnly = salaryStr.replaceAll(RegExp(r'[^0-9]'), '');
    final salaryVal = int.tryParse(numbersOnly) ?? 0;
    
    if (salaryVal > 30000) {
      cost = 15;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final postRef = FirebaseFirestore.instance.collection('posts').doc(jobId);
    final appsRef = FirebaseFirestore.instance.collection('applications').doc();
    final subAppsRef = postRef.collection('applications').doc(user.uid);
    final txRef = FirebaseFirestore.instance.collection('contactCredits').doc(user.uid).collection('transactions').doc();
    final employerNotifRef = FirebaseFirestore.instance.collection('users').doc(employerId).collection('notifications').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception('User not found.');

      final balance = int.tryParse(userSnap.data()?['credits']?.toString() ?? '0') ?? 0;
      if (balance < cost) {
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
      transaction.update(userRef, {'credits': FieldValue.increment(-cost)});

      // 2. Log Transaction
      transaction.set(txRef, {
        'title': 'Job Application',
        'description': 'Applied for ${post['jobTitle'] ?? 'Job'}',
        'amount': -cost,
        'type': 'debit',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Create Applications
      transaction.set(appsRef, applicationData);
      transaction.set(subAppsRef, {
        ...applicationData,
        'applicationId': appsRef.id,
        'uid': user.uid,
      });

      // 4. Update Job Post
      transaction.update(postRef, {'applicantCount': FieldValue.increment(1)});

      // 5. Notify Employer
      transaction.set(employerNotifRef, {
        'title': 'New Job Application',
        'body': '$workerName has applied for your job "${post['jobTitle'] ?? 'Job'}".',
        'type': 'application',
        'jobId': jobId,
        'actorUid': user.uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // 5. Update Local State
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

  Stream<String> getApplicationStatus(String jobId) {
    final user = _ref.read(authProvider);
    if (user == null) return Stream.value('none');

    return FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('workerId', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 'none';
          return snapshot.docs.first.data()['status'] ?? 'pending';
        });
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
