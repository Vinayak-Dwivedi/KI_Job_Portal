import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';
import 'admin_service.dart';

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
    String? subLocation,
    String? companyName,
    DateTime? eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventSubLocation,
    String? eventTitle,
    String visibility = 'public',
    bool? isFeatured,
    String? category,
    String? jobCategory,
    String? duration,
    String? workersNeeded,
    String? jobType,
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

    final postRef = await _firestore.collection('posts').add({
      'uid': uid,
      'userId': uid, // Write both to be compliant with rules checking either!
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
      if (jobSkills != null) 'skills': jobSkills, // Copy skills for search matches
      if (subLocation != null) 'subLocation': subLocation,
      if (companyName != null) 'companyName': companyName,
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate),
      if (eventTime != null) 'eventTime': eventTime,
      if (eventLocation != null) 'eventLocation': eventLocation,
      if (eventSubLocation != null) 'eventSubLocation': eventSubLocation,
      if (eventTitle != null) 'eventTitle': eventTitle,
      'visibility': visibility,
      'status': isAdmin ? 'approved' : 'pending',
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isFeatured': isFeatured ?? false,
      if (isFeatured == true) 'featuredUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      if (category != null) 'category': category,
      if (category != null || jobCategory != null) 'jobCategory': jobCategory ?? category,
      if (duration != null) 'duration': duration,
      if (workersNeeded != null) 'workersNeeded': workersNeeded,
      if (jobType != null) 'jobType': jobType,
    });

    // 🔔 Notify Followers
    if (!isAdmin) {
      _notifyFollowers(uid, name, postRef.id);
    }
  }

  static Future<void> _notifyFollowers(String authorUid, String authorName, String postId) async {
    try {
      final followersSnap = await _firestore
          .collection('users')
          .doc(authorUid)
          .collection('followers')
          .get();

      if (followersSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in followersSnap.docs) {
        final followerUid = doc.id;
        final notificationRef = _firestore
            .collection('users')
            .doc(followerUid)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'title': 'New post from $authorName',
          'body': '$authorName just shared a new update. Check it out!',
          'type': 'social',
          'postId': postId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error notifying followers: $e");
    }
  }


  // 🔥 Update Post
  static Future<void> updatePost(String postId, Map<String, dynamic> data, {bool isAdmin = false, List<Map<String, dynamic>>? newMediaFiles}) async {
    List<Map<String, String>> newUploadedMedia = [];
    
    // Upload any newly added media files
    if (newMediaFiles != null && newMediaFiles.isNotEmpty) {
      for (var mediaFile in newMediaFiles) {
        final uploaded = await uploadMediaFile(mediaFile['file'], mediaFile['type']);
        newUploadedMedia.add(uploaded);
      }
    }

    // Append newly uploaded media to the existing media list
    if (newUploadedMedia.isNotEmpty) {
      final existingMedia = (data['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      data['media'] = [
        ...existingMedia,
        ...newUploadedMedia,
      ];
    }

    // Recalculate imageUrl for legacy fallback
    final allMedia = data['media'] as List?;
    if (allMedia != null && allMedia.isNotEmpty) {
      final allMediaTyped = allMedia.cast<Map<String, dynamic>>();
      final firstImage = allMediaTyped.where((m) => m['type'] == 'image').isNotEmpty
          ? allMediaTyped.firstWhere((m) => m['type'] == 'image')
          : null;
      data['imageUrl'] = firstImage != null ? firstImage['url'] : allMediaTyped.first['url'];
    }

    if (isAdmin) {
      await _firestore.collection('posts').doc(postId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Store edit for admin review
      await _firestore.collection('posts').doc(postId).update({
        'pendingEdit': {
          ...data,
          'submittedAt': FieldValue.serverTimestamp(),
        },
        'hasPendingEdit': true,
      });

      // 🔔 Notify all admins that this post has a pending edit
      try {
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        final posterName = postDoc.data()?['name'] ?? 'A user';
        AdminService.notifyAdminsOfPendingEdit(postId, posterName);
      } catch (e) {
        debugPrint('Could not notify admins of pending edit: \$e');
      }
    }
  }

  // 🔥 Delete Post
  static Future<void> deletePost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (doc.exists && doc.data()?['isShared'] == true) {
      final originalPostId = doc.data()?['originalPostId'];
      if (originalPostId != null) {
        // Decrement the shares counter on the original post
        await _firestore.collection('posts').doc(originalPostId).update({
          'shares': FieldValue.increment(-1),
        });
      }
    }
    await doc.reference.delete();
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
  static Future<void> toggleLike(String postId, String uid, String likerName) async {
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

        final postUid = postDoc.data()?['uid'];
        if (postUid != null && postUid != uid) {
          final notifRef = _firestore.collection('users').doc(postUid).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': '$likerName liked your post',
            'body': 'Your post is getting some love! Click to see the post.',
            'type': 'post_like',
            'postId': postId,
            'actorUid': uid,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  static Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    return _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      
      transaction.set(commentRef, {
        ...commentData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'comments': FieldValue.increment(1)});

      if (postDoc.exists) {
        final postUid = postDoc.data()?['uid'];
        final commenterUid = commentData['uid'];
        final commenterName = commentData['name'] ?? 'Someone';
        
        if (postUid != null && postUid != commenterUid) {
          final notifRef = _firestore.collection('users').doc(postUid).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': '$commenterName commented on your post',
            'body': 'Check out what they said about your post!',
            'type': 'post_comment',
            'postId': postId,
            'actorUid': commenterUid,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  static Future<void> notifyShare(String originalPostId, String uid, String sharerName, String newPostId) async {
    final postRef = _firestore.collection('posts').doc(originalPostId);
    final postDoc = await postRef.get();
    if (!postDoc.exists) return;

    final postUid = postDoc.data()?['uid'];
    if (postUid != null && postUid != uid) {
      final notifRef = _firestore.collection('users').doc(postUid).collection('notifications').doc();
      await notifRef.set({
        'title': '$sharerName shared your post',
        'body': 'Your post is reaching more people! Click to see the post.',
        'type': 'post_share',
        'postId': newPostId,
        'actorUid': uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> sharePost({
    required String originalPostId,
    required String sharerUid,
    required String sharerName,
    String? sharerPhotoUrl,
    String? shareCaption,
    String privacy = 'public',
  }) async {
    final originalPost = await getPost(originalPostId);
    if (originalPost == null) throw Exception('Original post not found');

    // Prevent duplicate repost spam (check if user already shared this post in last 24h)
    final recentShare = await _firestore
        .collection('posts')
        .where('sharedByUserId', isEqualTo: sharerUid)
        .where('originalPostId', isEqualTo: originalPostId)
        .get();

    final isRecentlyShared = recentShare.docs.any((doc) {
      final createdAt = doc.data()['createdAt'] as Timestamp?;
      if (createdAt == null) return false;
      return createdAt.toDate().isAfter(DateTime.now().subtract(const Duration(days: 1)));
    });

    if (isRecentlyShared) {
      throw Exception('You have already shared this post recently.');
    }

    final newPostRef = await _firestore.collection('posts').add({
      ...originalPost,
      'postId': '', // New ID will be generated
      'id': '',
      'isShared': true,
      'sharedByUserId': sharerUid,
      'sharedByUserName': sharerName,
      'sharedByUserPhotoUrl': sharerPhotoUrl,
      'shareCaption': shareCaption,
      'originalPostId': originalPostId,
      'originalPostAuthorId': originalPost['uid'],
      'originalPostAuthorName': originalPost['name'],
      'originalCreatedAt': originalPost['createdAt'],
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'shares': (originalPost['shares'] ?? 0) + 1,
      'privacy': privacy,
      'status': 'approved', // Shared posts are auto-approved for now
    });

    // Increment shares counter on the original post
    await _firestore.collection('posts').doc(originalPostId).update({
      'shares': FieldValue.increment(1),
    });

    await notifyShare(originalPostId, sharerUid, sharerName, newPostRef.id);
  }

  static Future<void> unsharePost({
    required String originalPostId,
    required String sharerUid,
  }) async {
    // Find the shared post
    final sharedPostQuery = await _firestore
        .collection('posts')
        .where('sharedByUserId', isEqualTo: sharerUid)
        .where('originalPostId', isEqualTo: originalPostId)
        .where('isShared', isEqualTo: true)
        .get();

    if (sharedPostQuery.docs.isEmpty) {
      return; // Not shared
    }

    final batch = _firestore.batch();
    
    // Get original post to find the owner
    final originalPostDoc = await _firestore.collection('posts').doc(originalPostId).get();
    String? postOwnerUid;
    if (originalPostDoc.exists) {
      postOwnerUid = originalPostDoc.data()?['uid'];
    }
    
    // Delete all shared instances (should usually be just 1, but just in case)
    for (var doc in sharedPostQuery.docs) {
      final sharedPostId = doc.id;
      batch.delete(doc.reference);
      
      // Also delete the share notification for this shared post
      if (postOwnerUid != null) {
        final notifQuery = await _firestore
            .collection('users')
            .doc(postOwnerUid)
            .collection('notifications')
            .where('type', isEqualTo: 'post_share')
            .where('postId', isEqualTo: sharedPostId)
            .where('actorUid', isEqualTo: sharerUid)
            .get();
        for (var notifDoc in notifQuery.docs) {
          batch.delete(notifDoc.reference);
        }
      }
    }

    // Decrement shares counter on the original post
    batch.update(_firestore.collection('posts').doc(originalPostId), {
      'shares': FieldValue.increment(-sharedPostQuery.docs.length),
    });

    await batch.commit();
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
  // 📋 JOB APPLICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> applyToJob(String postId, String workerUid, Map<String, dynamic> workerData) async {
    final canApply = await SubscriptionService.deductApplication(workerUid);
    if (!canApply) {
      throw Exception('Daily application limit reached for your plan. Upgrade for more.');
    }
    
    // Get post details for employer ID and title
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (!postDoc.exists) throw Exception('Job post not found.');
    final postData = postDoc.data()!;
    final employerId = postData['uid'] ?? '';
    final jobTitle = postData['jobTitle'] ?? postData['title'] ?? 'Job';

    // Get worker details from their profile to ensure complete info
    final userSnap = await _firestore.collection('users').doc(workerUid).get();
    final userData = userSnap.exists ? userSnap.data()! : {};
    final workerName = workerData['name'] ?? userData['name'] ?? 'Worker';
    final workerPhone = workerData['phone'] ?? userData['phone'] ?? '';
    final workerImageUrl = workerData['profilePhotoUrl'] ?? userData['profilePhotoUrl'] ?? '';

    final appsRef = _firestore.collection('applications').doc();

    final applicationData = {
      'jobId': postId,
      'employerId': employerId,
      'workerId': workerUid,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'workerImageUrl': workerImageUrl,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
    };

    // 1. Create sub-collection application doc
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('applications')
        .doc(workerUid)
        .set({
      ...workerData,
      'uid': workerUid,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create top-level application doc for search and status sync
    await appsRef.set(applicationData);

    // 3. Update applicantCount
    await _firestore.collection('posts').doc(postId).update({
      'applicantCount': FieldValue.increment(1),
    });

    // 4. Notify Employer
    if (employerId.isNotEmpty) {
      final employerNotifRef = _firestore
          .collection('users')
          .doc(employerId)
          .collection('notifications')
          .doc();
      
      await employerNotifRef.set({
        'title': 'New Job Application',
        'body': '$workerName has applied for your job "$jobTitle".',
        'type': 'application',
        'jobId': postId,
        'actorUid': workerUid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> updateApplicationStatus(String postId, String workerUid, String newStatus) async {
    // 1. Update sub-collection
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('applications')
        .doc(workerUid)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update top-level collection (Sync)
    try {
      final appsQuery = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: postId)
          .where('workerId', isEqualTo: workerUid)
          .limit(1)
          .get();

      if (appsQuery.docs.isNotEmpty) {
        await appsQuery.docs.first.reference.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error syncing application status: $e");
    }

    // 3. Send Notification to Worker
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data()!;
        final jobTitle = postData['jobTitle'] ?? postData['title'] ?? 'Job';
        final employerName = postData['employerName'] ?? postData['name'] ?? 'Employer';
        final employerUid = postData['uid'] ?? '';

        String title = 'Application Update';
        String body = 'Your application status has been updated.';
        if (newStatus == 'shortlisted') {
          title = 'Shortlisted! 🎉';
          body = 'Congratulations! $employerName has shortlisted you for "$jobTitle".';
        } else if (newStatus == 'hired') {
          title = 'Hired! 🌟';
          body = 'Fantastic news! You have been hired by $employerName for "$jobTitle".';
        } else if (newStatus == 'rejected') {
          title = 'Application Update';
          body = 'Thank you for applying. $employerName has updated your application status for "$jobTitle".';
        } else if (newStatus == 'pending') {
          title = 'Application Under Review';
          body = 'Your application for "$jobTitle" is under review again.';
        }

        final workerNotifRef = _firestore
            .collection('users')
            .doc(workerUid)
            .collection('notifications')
            .doc();

        await workerNotifRef.set({
          'title': title,
          'body': body,
          'type': 'application',
          'jobId': postId,
          'actorUid': employerUid,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error sending application status notification: $e");
    }
  }

  static Stream<List<Map<String, dynamic>>> getApplicants(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  static Stream<bool> hasUserApplied(String postId, String workerUid) {
    if (workerUid.isEmpty) return Stream.value(false);
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('applications')
        .doc(workerUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ⚡ FEATURED POSTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Deducts 50 credits from the employer and marks the post as featured for 7 days.
  static Future<void> featurePost(String postId, String employerUid) async {
    const int featureCost = 80;
    final userRef = _firestore.collection('users').doc(employerUid);
    final postRef = _firestore.collection('posts').doc(postId);
    final txRef = _firestore.collection('contactCredits').doc(employerUid).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception('User not found.');

      final balance =
          int.tryParse(userSnap.data()!['credits']?.toString() ?? '0') ?? 0;
      if (balance < featureCost) {
        throw Exception(
            'Insufficient credits. You need $featureCost credits to boost a post.');
      }

      final featuredUntil = DateTime.now().add(const Duration(days: 1));
      transaction.update(userRef, {'credits': FieldValue.increment(-featureCost)});
      transaction.update(postRef, {
        'isFeatured': true,
        'featuredUntil': Timestamp.fromDate(featuredUntil),
      });

      // Log transaction
      transaction.set(txRef, {
        'title': 'Job Boost',
        'description': 'Featured job post for 1 day',
        'amount': -featureCost,
        'type': 'debit',
        'createdAt': FieldValue.serverTimestamp(),
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

  // ─────────────────────────────────────────────────────────────────────────
  // ⭐ REVIEWS & RATINGS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> addReview({
    required String jobId,
    required String reviewerId,
    required String revieweeId,
    required double rating,
    required String comment,
    required String reviewerName,
    String? reviewerPhoto,
  }) async {
    await _firestore.collection('reviews').add({
      'jobId': jobId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Optionally update reviewee's average rating here
  }

  static Stream<List<Map<String, dynamic>>> getReviewsForUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList()..sort((a, b) {
              final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bTime.compareTo(aTime);
            }));
  }

  static Stream<List<Map<String, dynamic>>> getReviewsForJob(String jobId) {
    return _firestore
        .collection('reviews')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
