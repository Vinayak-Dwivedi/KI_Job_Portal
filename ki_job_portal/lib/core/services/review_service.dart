import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if the current user can rate another user
  /// Requirement: Must have an unlocked chat with them
  static Future<bool> canRate(String targetUid, {String? currentUid}) async {
    final effectiveUid = currentUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUid == null || effectiveUid == targetUid) return false;

    try {
      // 1. Fetch roles to determine logic
      final usersColl = _db.collection('users');
      final reviewerDoc = await usersColl.doc(effectiveUid).get();
      final revieweeDoc = await usersColl.doc(targetUid).get();
      
      final reviewerRole = reviewerDoc.data()?['role']?.toString().toLowerCase();
      final revieweeRole = revieweeDoc.data()?['role']?.toString().toLowerCase();
      final isSameRole = (reviewerRole != null && revieweeRole != null && reviewerRole == revieweeRole);

      // 2. Logic for Same-Role (Worker-Worker or Employer-Employer)
      if (isSameRole) {
        final existingReview = await _db.collection('reviews')
            .where('reviewerId', isEqualTo: effectiveUid)
            .where('revieweeId', isEqualTo: targetUid)
            .limit(1)
            .get();
        return existingReview.docs.isEmpty;
      }

      // 3. Logic for Cross-Role (Worker-Employer)
      // Find all completed/hired jobs between these two users
      final appsSnap1 = await _db.collection('applications')
          .where('workerId', isEqualTo: targetUid)
          .where('employerId', isEqualTo: effectiveUid)
          .get();
      final appsSnap2 = await _db.collection('applications')
          .where('workerId', isEqualTo: effectiveUid)
          .where('employerId', isEqualTo: targetUid)
          .get();
      final invitesSnap1 = await _db.collection('invitations')
          .where('workerUid', isEqualTo: targetUid)
          .where('employerUid', isEqualTo: effectiveUid)
          .get();
      final invitesSnap2 = await _db.collection('invitations')
          .where('workerUid', isEqualTo: effectiveUid)
          .where('employerUid', isEqualTo: targetUid)
          .get();

      final allJobDocs = [
        ...appsSnap1.docs, ...appsSnap2.docs,
        ...invitesSnap1.docs, ...invitesSnap2.docs
      ];

      final completedJobs = allJobDocs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'hired' || status == 'accepted' || status == 'completed';
      }).toList();

      if (completedJobs.isEmpty) return false;

      // For each completed job, check if a review already exists
      for (var job in completedJobs) {
        final reviewSnap = await _db.collection('reviews')
            .where('reviewerId', isEqualTo: effectiveUid)
            .where('revieweeId', isEqualTo: targetUid)
            .where('jobId', isEqualTo: job.id)
            .limit(1)
            .get();
        
        if (reviewSnap.docs.isEmpty) {
          // Found at least one job that hasn't been rated yet!
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint("Error checking rate permission: $e");
      return false;
    }
  }

  /// Submit a rating/review
  static Future<bool> submitReview({
    required String revieweeId,
    required double rating,
    String? comment,
    String? reviewerId,
    String? jobId,
  }) async {
    final effectiveReviewerId = reviewerId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveReviewerId == null) return false;

    try {
      String? finalJobId = jobId;

      // If no jobId provided, try to find one unrated job (for cross-role)
      if (finalJobId == null) {
        final canRate = await ReviewService.canRate(revieweeId, currentUid: effectiveReviewerId);
        if (!canRate) return false;
        
        // Find the first unrated job
        final appsSnap1 = await _db.collection('applications').where('workerId', isEqualTo: revieweeId).where('employerId', isEqualTo: effectiveReviewerId).get();
        final appsSnap2 = await _db.collection('applications').where('workerId', isEqualTo: effectiveReviewerId).where('employerId', isEqualTo: revieweeId).get();
        final invitesSnap1 = await _db.collection('invitations').where('workerUid', isEqualTo: revieweeId).where('employerUid', isEqualTo: effectiveReviewerId).get();
        final invitesSnap2 = await _db.collection('invitations').where('workerUid', isEqualTo: effectiveReviewerId).where('employerUid', isEqualTo: revieweeId).get();

        final allJobDocs = [...appsSnap1.docs, ...appsSnap2.docs, ...invitesSnap1.docs, ...invitesSnap2.docs];
        for (var job in allJobDocs) {
          final status = job.data()['status'] as String?;
          if (status == 'hired' || status == 'accepted' || status == 'completed') {
             final rSnap = await _db.collection('reviews').where('jobId', isEqualTo: job.id).get();
             if (rSnap.docs.isEmpty) {
               finalJobId = job.id;
               break;
             }
          }
        }
      }

      // Fetch reviewer details for the review document
      String reviewerName = 'Anonymous';
      String? reviewerPhoto;
      
      final reviewerDoc = await _db.collection('users').doc(effectiveReviewerId).get();
      if (reviewerDoc.exists) {
        final rData = reviewerDoc.data();
        reviewerName = rData?['name'] ?? rData?['fullName'] ?? 'Anonymous';
        reviewerPhoto = rData?['profilePhotoUrl'];
      }

      final reviewData = {
        'reviewerId': effectiveReviewerId,
        'reviewerName': reviewerName,
        'reviewerPhoto': reviewerPhoto,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment ?? '',
        'jobId': finalJobId ?? 'endorsement', // 'endorsement' for same-role
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('reviews').add(reviewData);

      // Update aggregate rating on user doc (Simplified: in production use Cloud Functions)
      await _updateUserAggregateRating(revieweeId);

      return true;
    } catch (e) {
      debugPrint("Error submitting review: $e");
      return false;
    }
  }

  static Future<void> _updateUserAggregateRating(String uid) async {
    try {
      final reviewsSnap = await _db
          .collection('reviews')
          .where('revieweeId', isEqualTo: uid)
          .get();

      if (reviewsSnap.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviewsSnap.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      final avgRating = totalRating / reviewsSnap.docs.length;
      
      await _db.collection('users').doc(uid).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'reviewCount': reviewsSnap.docs.length,
      });
    } catch (e) {
      debugPrint("Error updating aggregate rating: $e");
    }
  }
}
