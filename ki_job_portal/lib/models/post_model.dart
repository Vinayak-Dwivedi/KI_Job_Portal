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
  final String privacy;            // "public" | "connections"
  final bool isShared;
  final String? sharedByUserId;
  final String? sharedByUserName;
  final String? sharedByUserPhotoUrl;
  final String? originalPostId;
  final String? originalPostAuthorId;
  final String? originalPostAuthorName;
  final String? shareCaption;
  final DateTime? originalCreatedAt;

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
    this.privacy = 'public',
    this.isShared = false,
    this.sharedByUserId,
    this.sharedByUserName,
    this.sharedByUserPhotoUrl,
    this.originalPostId,
    this.originalPostAuthorId,
    this.originalPostAuthorName,
    this.shareCaption,
    this.originalCreatedAt,
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
    imageUrls: _parseMediaUrls(data), 
    status: data['status'] ?? 'approved', 
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
    privacy: data['privacy'] ?? 'public',
    isShared: data['isShared'] ?? false,
    sharedByUserId: data['sharedByUserId'],
    sharedByUserName: data['sharedByUserName'],
    sharedByUserPhotoUrl: data['sharedByUserPhotoUrl'],
    originalPostId: data['originalPostId'],
    originalPostAuthorId: data['originalPostAuthorId'],
    originalPostAuthorName: data['originalPostAuthorName'],
    shareCaption: data['shareCaption'],
    originalCreatedAt: (data['originalCreatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userRole': userRole,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'isUserVerified': isUserVerified,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'likeCount': likeCount,
      'isJobPost': isJobPost,
      'jobTitle': jobTitle,
      'jobSalary': jobSalary,
      'location': location,
      'companyName': companyName,
      'isAvailabilityPost': isAvailabilityPost,
      'media': media,
      'privacy': privacy,
      'isShared': isShared,
      'sharedByUserId': sharedByUserId,
      'sharedByUserName': sharedByUserName,
      'sharedByUserPhotoUrl': sharedByUserPhotoUrl,
      'originalPostId': originalPostId,
      'originalPostAuthorId': originalPostAuthorId,
      'originalPostAuthorName': originalPostAuthorName,
      'shareCaption': shareCaption,
      'originalCreatedAt': originalCreatedAt != null ? Timestamp.fromDate(originalCreatedAt!) : null,
    };
  }

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

