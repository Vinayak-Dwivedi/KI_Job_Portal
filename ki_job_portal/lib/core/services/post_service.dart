import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class PostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = _storageInstance();

  static FirebaseStorage _storageInstance() {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      // Fallback for environments where storage might not be initialized correctly
      return FirebaseStorage.instance;
    }
  }

  static Future<Map<String, String>> uploadMediaFile(File file, String explicitType) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    final ref = _storage
        .ref()
        .child('posts/${DateTime.now().millisecondsSinceEpoch}.$extension');

    final metadata = SettableMetadata(contentType: explicitType == 'video' ? 'video/$extension' : 'image/$extension');
    await ref.putFile(file, metadata);
    final url = await ref.getDownloadURL();
    return {'url': url, 'type': explicitType};
  }

  // 🔥 Create Post (Unified Schema)
  static Future<void> createPost({
    required String uid,
    required String name,
    required String role,
    required String text,
    List<Map<String, dynamic>>? mediaFiles,
    String? location,
    String? profilePhotoUrl,
    required bool isVerified,
    bool isJobPost = false,
    bool isAvailabilityPost = false,
    bool isAdmin = false,
    String? jobTitle,
    String? jobSalary,
    String? jobExperience,
    String? jobSkills,
    String? companyName,
    DateTime? eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventTitle,
    String visibility = 'public',
  }) async {
    List<Map<String, String>> media = [];
    String? firstImageUrl;

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      for (int i = 0; i < mediaFiles.length && i < 4; i++) { // Limit max 4
        final uploaded = await uploadMediaFile(mediaFiles[i]['file'], mediaFiles[i]['type']);
        media.add(uploaded);
        if (firstImageUrl == null && uploaded['type'] == 'image') {
          firstImageUrl = uploaded['url']; 
        }
      }
    }

    await _firestore.collection('posts').add({
      'uid': uid,
      'name': name,
      'role': role,
      'text': text,
      'media': media,
      'imageUrl': firstImageUrl ?? (media.isNotEmpty ? media.first['url'] : null), // For legacy fallback
      'location': location ?? "",
      'profilePhotoUrl': profilePhotoUrl ?? "",
      'isVerified': isVerified,
      'isJobPost': isJobPost,
      'isAvailabilityPost': isAvailabilityPost,
      'isAdmin': isAdmin,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (jobSalary != null) 'jobSalary': jobSalary,
      if (jobExperience != null) 'jobExperience': jobExperience,
      if (jobSkills != null) 'jobSkills': jobSkills,
      if (companyName != null) 'companyName': companyName,
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate),
      if (eventTime != null) 'eventTime': eventTime,
      if (eventLocation != null) 'eventLocation': eventLocation,
      if (eventTitle != null) 'eventTitle': eventTitle,
      'visibility': visibility,
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  // 🔥 Get Single Post
  static Future<Map<String, dynamic>?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint("Error fetching post: $e");
      return null;
    }
  }

  // 🔥 Social Interactions
  static Future<void> toggleLike(String postId, String uid) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    return _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  static Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    return _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        ...commentData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'comments': FieldValue.increment(1)});
    });
  }

  static Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Stream<bool> isPostLiked(String postId, String uid) {
    if (uid.isEmpty) return Stream.value(false);
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🔖 SAVED JOBS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> saveJob(String uid, String postId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .doc(postId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> unsaveJob(String uid, String postId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .doc(postId)
        .delete();
  }

  static Stream<bool> isJobSaved(String uid, String postId) {
    if (uid.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Stream<List<String>> getSavedJobIds(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 📋 JOB STATUS (active / paused / filled)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateJobStatus(String postId, String status) async {
    await _firestore.collection('posts').doc(postId).update({
      'hiringStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ⚡ FEATURED POSTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Deducts 50 credits from the employer and marks the post as featured for 7 days.
  static Future<void> featurePost(String postId, String employerUid) async {
    const int featureCost = 50;
    final credRef = _firestore.collection('contactCredits').doc(employerUid);
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final credSnap = await transaction.get(credRef);
      if (!credSnap.exists) throw Exception('Credit document not found.');

      final balance =
          int.tryParse(credSnap.data()!['balance']?.toString() ?? '0') ?? 0;
      if (balance < featureCost) {
        throw Exception(
            'Insufficient credits. You need $featureCost credits to boost a post.');
      }

      final featuredUntil = DateTime.now().add(const Duration(days: 7));
      transaction
          .update(credRef, {'balance': FieldValue.increment(-featureCost)});
      transaction.update(postRef, {
        'isFeatured': true,
        'featuredUntil': Timestamp.fromDate(featuredUntil),
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 🛡️ MODERATION (Report, Block, Hide)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> reportPost(String postId, String reporterId, String postUid, String reason) async {
    await _firestore.collection('reports').add({
      'postId': postId,
      'postUid': postUid,
      'reporterId': reporterId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> blockUser(String currentUid, String blockUid) async {
    await _firestore.collection('users').doc(currentUid).update({
      'blockedUsers': FieldValue.arrayUnion([blockUid])
    });
  }

  static Future<void> unblockUser(String currentUid, String blockUid) async {
    await _firestore.collection('users').doc(currentUid).update({
      'blockedUsers': FieldValue.arrayRemove([blockUid])
    });
  }

  static Future<void> hidePost(String currentUid, String postId) async {
    await _firestore.collection('users').doc(currentUid).update({
      'hiddenPosts': FieldValue.arrayUnion([postId])
    });
  }
}