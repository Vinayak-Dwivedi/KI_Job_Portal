import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userRole;
  final String userName;
  final String? userPhotoUrl;
  final bool isUserVerified;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String status;             // "pending" | "approved" | "rejected"
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final int likeCount;
  final bool isJobPost;
  final String? jobTitle;
  final String? jobSalary;
  final String? location;
  final String? companyName;
  final bool isAvailabilityPost;
  final List<Map<String, dynamic>> media;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userRole,
    required this.userName,
    this.userPhotoUrl,
    required this.isUserVerified,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.approvedAt,
    required this.likeCount,
    this.isJobPost = false,
    this.jobTitle,
    this.jobSalary,
    this.location,
    this.companyName,
    this.isAvailabilityPost = false,
    this.media = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> data) => PostModel(
    postId: data['postId'] ?? data['id'] ?? '',
    userId: data['userId'] ?? data['uid'] ?? '',
    userRole: data['userRole'] ?? data['role'] ?? '',
    userName: data['userName'] ?? data['name'] ?? '',
    userPhotoUrl: data['userPhotoUrl'] ?? data['profilePhotoUrl'],
    isUserVerified: data['isUserVerified'] ?? data['isVerified'] ?? false,
    title: data['title'] ?? '',
    description: data['description'] ?? data['text'] ?? '',
    imageUrls: _parseMediaUrls(data), // Still populate it for any legacy usages
    status: data['status'] ?? 'approved', // Defaulting to approved for now if missing
    rejectionReason: data['rejectionReason'],
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    likeCount: data['likeCount'] ?? data['likes'] ?? 0,
    isJobPost: data['isJobPost'] ?? false,
    jobTitle: data['jobTitle'],
    jobSalary: data['jobSalary'],
    location: data['location'],
    companyName: data['companyName'],
    isAvailabilityPost: data['isAvailabilityPost'] ?? false,
    media: _parseMediaObjects(data),
  );

  static List<String> _parseMediaUrls(Map<String, dynamic> data) {
    if (data['media'] != null) {
      return List<String>.from((data['media'] as List).map((m) => m['url'].toString()));
    }
    return data['imageUrl'] != null ? [data['imageUrl']] : List<String>.from(data['imageUrls'] ?? []);
  }

  static List<Map<String, dynamic>> _parseMediaObjects(Map<String, dynamic> data) {
    if (data['media'] != null) {
      return List<Map<String, dynamic>>.from(data['media']);
    }
    // Fallback for old data
    final urls = data['imageUrl'] != null ? [data['imageUrl']] : List<String>.from(data['imageUrls'] ?? []);
    return urls.map((url) => {'url': url, 'type': 'image'}).toList();
  }
}

