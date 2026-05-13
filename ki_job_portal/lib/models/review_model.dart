import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String reviewerName;
  final String? reviewerPhoto;

  Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
    this.reviewerPhoto,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      reviewerPhoto: data['reviewerPhoto'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
    };
  }
}
