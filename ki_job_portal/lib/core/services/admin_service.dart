import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  // Manage Posts
  static Future<void> updatePostStatus(String postId, String status) async {
    await _firestore.collection('posts').doc(postId).update({'status': status});
    
    if (status == 'approved') {
      try {
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        final postData = postDoc.data();
        if (postData != null) {
          final uid = postData['uid'];
          final title = postData['jobTitle'] ?? postData['text'] ?? 'Your post';
          final truncatedTitle = title.length > 40 ? '${title.substring(0, 40)}...' : title;

          await _firestore.collection('users').doc(uid).collection('notifications').add({
            'title': 'Post Approved! ✅',
            'body': 'Your post "$truncatedTitle" is now live! Tap to view it.',
            'type': 'post_approved',
            'postId': postId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print("Error sending approval notification: $e");
      }
    }
  }

  static Future<void> approveEdit(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postData = postDoc.data();
    
    if (postData != null && postData['hasPendingEdit'] == true && postData['pendingEdit'] != null) {
      final pendingEdit = Map<String, dynamic>.from(postData['pendingEdit']);
      pendingEdit.remove('submittedAt'); // don't need this in root

      await _firestore.collection('posts').doc(postId).update({
        ...pendingEdit,
        'hasPendingEdit': FieldValue.delete(),
        'pendingEdit': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Optional: Notify user that their edit was approved
      try {
        final uid = postData['uid'];
        await _firestore.collection('users').doc(uid).collection('notifications').add({
          'title': 'Edit Approved! ✅',
          'body': 'Your recent post edit has been approved and is now live.',
          'type': 'post_approved',
          'postId': postId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error sending edit approval notification: $e");
      }
    }
  }

  static Future<void> rejectEdit(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'hasPendingEdit': FieldValue.delete(),
      'pendingEdit': FieldValue.delete(),
    });
  }

  /// Notify all admin users that a post edit is pending their review.
  static Future<void> notifyAdminsOfPendingEdit(String postId, String posterName) async {
    try {
      final adminSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final batch = _firestore.batch();
      for (final doc in adminSnap.docs) {
        final notifRef = _firestore
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': '✏️ Post Edit Pending Review',
          'body': '$posterName edited a post. Tap to review it.',
          'type': 'post_approved',   // reuses the existing approved-post navigation logic
          'postId': postId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error notifying admins of pending edit: \$e');
    }
  }

  static Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Manage Users
  static Future<void> banUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isBanned': true});
    
    // Also delete or unpublish their posts
    final userPosts = await _firestore.collection('posts').where('authorId', isEqualTo: uid).get();
    final batch = _firestore.batch();
    for (var doc in userPosts.docs) {
      batch.update(doc.reference, {'status': 'rejected'});
    }
    await batch.commit();
  }

  static Future<void> unbanUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'isBanned': false});
  }
}
