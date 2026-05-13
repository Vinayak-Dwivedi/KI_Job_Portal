import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createJob({
    required String uid,
    required String title,
    required String category,
    required String description,
    required String wage,
    required String duration,
    required String workersNeeded,
    required String location,
  }) async {
    await _firestore.collection('jobs').add({
      'uid': uid,
      'title': title,
      'category': category,
      'description': description,
      'wage': wage,
      'duration': duration,
      'workersNeeded': workersNeeded,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }
}
