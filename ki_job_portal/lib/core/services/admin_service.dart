import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  // Manage Posts
  static Future<void> updatePostStatus(String postId, String status) async {
    await _firestore.collection('posts').doc(postId).update({'status': status});
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
