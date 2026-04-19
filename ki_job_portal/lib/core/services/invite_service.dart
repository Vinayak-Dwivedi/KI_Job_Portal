import 'package:cloud_firestore/cloud_firestore.dart';

class InviteService {
  static final _db = FirebaseFirestore.instance;

  /// Employer invites a worker to apply for a specific job.
  static Future<void> inviteWorker({
    required String employerUid,
    required String employerName,
    required String workerUid,
    required String jobId,
    required String jobTitle,
  }) async {
    // Avoid duplicate invites for the same job
    final existing = await _db
        .collection('invitations')
        .where('employerUid', isEqualTo: employerUid)
        .where('workerUid', isEqualTo: workerUid)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already invited this worker for this job.');
    }

    await _db.collection('invitations').add({
      'employerUid': employerUid,
      'employerName': employerName,
      'workerUid': workerUid,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'status': 'pending', // pending | accepted | declined
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of invitations received by a worker.
  static Stream<List<Map<String, dynamic>>> getWorkerInvitations(String workerUid) {
    if (workerUid.isEmpty) return Stream.value([]);
    return _db
        .collection('invitations')
        .where('workerUid', isEqualTo: workerUid)
        // No orderBy here — avoids requiring a composite Firestore index.
        // We sort client-side below.
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'employerUid': data['employerUid'] ?? '',
              'employerName': data['employerName'] ?? 'Employer',
              'jobId': data['jobId'] ?? '',
              'jobTitle': data['jobTitle'] ?? 'Job',
              'status': data['status'] ?? 'pending',
              'createdAt': data['createdAt'],
            };
          }).toList();

          // Sort newest first (client-side)
          list.sort((a, b) {
            final aTs = a['createdAt'];
            final bTs = b['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as dynamic).compareTo(aTs as dynamic);
          });

          return list;
        });
  }

  /// Update the status of an invitation (accept or decline).
  static Future<void> respondToInvitation(String invitationId, String status) async {
    await _db
        .collection('invitations')
        .doc(invitationId)
        .update({'status': status, 'respondedAt': FieldValue.serverTimestamp()});
  }
}
