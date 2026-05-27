import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/post_service.dart';
import 'auth_provider.dart';
import 'application_provider.dart';
import 'dart:async';

enum FeedType { all, jobs, community, events, availability }

class FeedTypeFilterNotifier extends Notifier<FeedType> {
  @override
  FeedType build() => FeedType.all;
  set state(FeedType val) => super.state = val;
}

final feedTypeFilterProvider = NotifierProvider<FeedTypeFilterNotifier, FeedType>(FeedTypeFilterNotifier.new);

class HighlightedPostIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  set state(String? val) => super.state = val;
}

final highlightedPostIdProvider = NotifierProvider<HighlightedPostIdNotifier, String?>(HighlightedPostIdNotifier.new);

class JobFilter {
  final String? location;
  final String? category;
  final String? salary;
  final String? searchQuery;

  JobFilter({this.location, this.category, this.salary, this.searchQuery});

  JobFilter copyWith({
    String? location,
    String? category,
    String? salary,
    String? searchQuery,
  }) {
    return JobFilter(
      location: location ?? this.location,
      category: category ?? this.category,
      salary: salary ?? this.salary,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class JobFilterNotifier extends Notifier<JobFilter> {
  @override
  JobFilter build() => JobFilter();

  void updateFilter(JobFilter Function(JobFilter) update) {
    state = update(state);
  }
  
  void setFilter(JobFilter newFilter) {
    state = newFilter;
  }
}

final jobFilterProvider = NotifierProvider<JobFilterNotifier, JobFilter>(() => JobFilterNotifier());

class FeedFilterModel {
  final String searchQuery;
  final bool onlyJobs;
  final bool onlyMedia;

  FeedFilterModel({
    this.searchQuery = '',
    this.onlyJobs = false,
    this.onlyMedia = false,
  });

  FeedFilterModel copyWith({
    String? searchQuery,
    bool? onlyJobs,
    bool? onlyMedia,
  }) {
    return FeedFilterModel(
      searchQuery: searchQuery ?? this.searchQuery,
      onlyJobs: onlyJobs ?? this.onlyJobs,
      onlyMedia: onlyMedia ?? this.onlyMedia,
    );
  }
}

class UnifiedFeedFilterNotifier extends Notifier<FeedFilterModel> {
  @override
  FeedFilterModel build() => FeedFilterModel();
  
  void updateFilter({String? searchQuery, bool? onlyJobs, bool? onlyMedia}) {
    state = state.copyWith(
      searchQuery: searchQuery,
      onlyJobs: onlyJobs,
      onlyMedia: onlyMedia,
    );
  }

  void reset() => state = FeedFilterModel();
}

final unifiedFeedFilterProvider = NotifierProvider<UnifiedFeedFilterNotifier, FeedFilterModel>(UnifiedFeedFilterNotifier.new);


final currentUserDocProvider = StreamProvider.autoDispose((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value(null);
  return FirebaseFirestore.instance.collection('users').doc(auth.uid).snapshots();
});

bool _canViewPost(DocumentSnapshot doc, List<String> blockedUids, List<String> hiddenPostIds, String? currentUid, String? currentRole) {
  final data = doc.data() as Map<String, dynamic>?;
  if (data == null) return false;

  final uid = data['uid'] as String?;
  final visibility = data['visibility'] as String? ?? 'public';
  final status = data['status'] as String? ?? 'approved';
  
  if (blockedUids.contains(uid) || hiddenPostIds.contains(doc.id)) return false;

  // Moderation check: only show approved posts, OR if it's the owner's post
  if (status != 'approved' && uid != currentUid) return false;
  
  if (uid != currentUid) {
     // Visibility check removed to allow workers and employers to discover each other
     // if (visibility == 'employers' && currentRole != 'employer') return false;
     // if (visibility == 'workers' && currentRole != 'worker') return false;
  }

  // If someone else shared my post, don't show the shared version in my feed to avoid duplicate clutter
  if (data['isShared'] == true && uid == currentUid && data['sharedByUserId'] != currentUid) {
    return false;
  }

  return true;
}

final followingListProvider = StreamProvider((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(<String>[]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('following')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toList());
});

final feedProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, tab) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;
  final followingUids = ref.watch(followingListProvider).value ?? [];

  Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance.collection('posts');
  
  // Trending uses likes, Network will be filtered in memory or by UID if possible
  if (tab == 'trending') {
    baseQuery = baseQuery.orderBy('likes', descending: true);
  } else {
    baseQuery = baseQuery.orderBy('createdAt', descending: true);
  }

  return baseQuery.snapshots().map((snapshot) {
    var posts = snapshot.docs
        .where((doc) => _canViewPost(doc, blockedUids, hiddenPostIds, currentUid, currentRole))
        .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'media': data['media'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isFeatured': data['isFeatured'] ?? false,
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'shares': data['shares'] ?? 0,
            'eventDate': data['eventDate'],
            'eventTime': data['eventTime'],
            'eventLocation': data['eventLocation'],
            'eventTitle': data['eventTitle'],
            'visibility': data['visibility'] ?? 'public',
            'status': data['status'] ?? 'approved',
            'hasPendingEdit': data['hasPendingEdit'] ?? false,
            'isShared': data['isShared'] ?? false,
            'sharedByUserId': data['sharedByUserId'],
            'sharedByUserName': data['sharedByUserName'],
            'sharedByUserPhotoUrl': data['sharedByUserPhotoUrl'],
            'shareCaption': data['shareCaption'],
            'originalPostId': data['originalPostId'],
            'originalPostAuthorId': data['originalPostAuthorId'],
            'originalPostAuthorName': data['originalPostAuthorName'],
            'originalCreatedAt': data['originalCreatedAt'],
            'createdAt': data['createdAt'],
          };
        }).toList();

    // Priority sort by isFeatured
    posts.sort((a, b) {
      final aFeatured = a['isFeatured'] == true ? 1 : 0;
      final bFeatured = b['isFeatured'] == true ? 1 : 0;
      if (aFeatured != bFeatured) return bFeatured - aFeatured;
      
      if (tab == 'trending') {
        final aLikes = a['likes'] as int? ?? 0;
        final bLikes = b['likes'] as int? ?? 0;
        return bLikes.compareTo(aLikes);
      } else {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      }
    });

    if (tab == 'network') {
      posts = posts.where((p) => followingUids.contains(p['uid']) || p['uid'] == currentUid).toList();
    }
    
    return posts;
  });
});

final filteredCommunityFeedProvider = Provider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, tab) {
  final feedAsync = ref.watch(feedProvider(tab));
  final feed = feedAsync.value ?? [];
  final advancedFilter = ref.watch(unifiedFeedFilterProvider);

  var result = feed;

  if (advancedFilter.onlyJobs) {
    result = result.where((p) => p['isJobPost'] == true).toList();
  }

  if (advancedFilter.onlyMedia) {
    result = result.where((p) => 
      (p['media'] != null && (p['media'] as List).isNotEmpty) || 
      (p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty)
    ).toList();
  }

  if (advancedFilter.searchQuery.isNotEmpty) {
    final q = advancedFilter.searchQuery.toLowerCase();
    result = result.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final text = (p['text'] ?? '').toString().toLowerCase();
      return name.contains(q) || text.contains(q);
    }).toList();
  }

  return result;
});


final pendingPostsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where(Filter.or(
        Filter('status', isEqualTo: 'pending'),
        Filter('hasPendingEdit', isEqualTo: true),
      ))
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'media': data['media'],
            'createdAt': data['createdAt'],
            'status': data['status'],
            'hasPendingEdit': data['hasPendingEdit'] ?? false,
            'pendingEdit': data['pendingEdit'],
          };
        }).toList();
        
        docs.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
        });

        return docs;
      });
});

final jobFeedProvider = StreamProvider.autoDispose((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;
  final filter = ref.watch(jobFilterProvider);

  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('posts')
      .where('isJobPost', isEqualTo: true);

  // Note: Firestore doesn't support multiple inequality filters easily without composite indexes.
  // We'll do some filtering in-memory for location/category if needed, but basic ones can be here.
  
  return query.snapshots().map((snapshot) {
    var docs = snapshot.docs
        .where((doc) => _canViewPost(doc, blockedUids, hiddenPostIds, currentUid, currentRole))
        .map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': true,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'jobExperience': data['jobExperience'] ?? data['experience'] ?? '',
            'jobSkills': data['jobSkills'] ?? data['skills'] ?? '',
            'skills': data['skills'] ?? data['jobSkills'] ?? '',
            'jobCategory': data['jobCategory'] ?? data['category'] ?? '',
            'category': data['category'] ?? data['jobCategory'] ?? '',
            'jobType': data['jobType'] ?? '',
            'subLocation': data['subLocation'] ?? '',
            'duration': data['duration'] ?? '',
            'workersNeeded': data['workersNeeded'] ?? '',
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isShared': data['isShared'] ?? false,
            'sharedByUserId': data['sharedByUserId'],
            'sharedByUserName': data['sharedByUserName'],
            'sharedByUserPhotoUrl': data['sharedByUserPhotoUrl'],
            'shareCaption': data['shareCaption'],
            'originalPostId': data['originalPostId'],
            'originalPostAuthorId': data['originalPostAuthorId'],
            'originalPostAuthorName': data['originalPostAuthorName'],
            'originalCreatedAt': data['originalCreatedAt'],
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        }).toList();

    // Apply Filters in-memory for flexibility
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      docs = docs.where((j) => 
        (j['jobTitle'] as String).toLowerCase().contains(q) || 
        (j['text'] as String).toLowerCase().contains(q) ||
        (j['companyName'] as String).toLowerCase().contains(q)
      ).toList();
    }

    if (filter.location != null && filter.location!.isNotEmpty) {
      final loc = filter.location!.toLowerCase();
      docs = docs.where((j) => (j['location'] as String).toLowerCase().contains(loc)).toList();
    }

    if (filter.category != null && filter.category!.isNotEmpty) {
      final cat = filter.category!.toLowerCase();
      docs = docs.where((j) => (j['role'] as String).toLowerCase().contains(cat)).toList();
    }

    // Featured posts sort first, then by date
    docs.sort((a, b) {
      final aFeatured = a['isFeatured'] == true ? 1 : 0;
      final bFeatured = b['isFeatured'] == true ? 1 : 0;
      if (aFeatured != bFeatured) return bFeatured - aFeatured;
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return docs;
  });
});

final employerJobsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('posts')
      .where('isJobPost', isEqualTo: true)
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': true,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'jobExperience': data['jobExperience'] ?? data['experience'] ?? '',
            'jobSkills': data['jobSkills'] ?? data['skills'] ?? '',
            'skills': data['skills'] ?? data['jobSkills'] ?? '',
            'jobCategory': data['jobCategory'] ?? data['category'] ?? '',
            'category': data['category'] ?? data['jobCategory'] ?? '',
            'jobType': data['jobType'] ?? '',
            'subLocation': data['subLocation'] ?? '',
            'duration': data['duration'] ?? '',
            'workersNeeded': data['workersNeeded'] ?? '',
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'isFeatured': data['isFeatured'] ?? false,
            'featuredUntil': data['featuredUntil'],
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        }).toList();

        docs.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return docs;
      });
});

final unifiedFeedProvider = StreamProvider.autoDispose((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;

  return FirebaseFirestore.instance
      .collection('posts')
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
        .where((doc) => _canViewPost(doc, blockedUids, hiddenPostIds, currentUid, currentRole))
        .map((doc) {
          final data = doc.data();
          final bool isJob = data['isJobPost'] == true;

          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': isJob,
            'isAvailabilityPost': data['isAvailabilityPost'] ?? false,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'jobExperience': data['jobExperience'] ?? data['experience'] ?? '',
            'jobSkills': data['jobSkills'] ?? data['skills'] ?? '',
            'skills': data['skills'] ?? data['jobSkills'] ?? '',
            'jobCategory': data['jobCategory'] ?? data['category'] ?? '',
            'category': data['category'] ?? data['jobCategory'] ?? '',
            'jobType': data['jobType'] ?? '',
            'subLocation': data['subLocation'] ?? '',
            'duration': data['duration'] ?? '',
            'workersNeeded': data['workersNeeded'] ?? '',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'shares': data['shares'] ?? 0,
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'eventDate': data['eventDate'],
            'eventTime': data['eventTime'],
            'eventLocation': data['eventLocation'],
            'eventTitle': data['eventTitle'],
            'visibility': data['visibility'] ?? 'public',
            'hasPendingEdit': data['hasPendingEdit'] ?? false,
            'isShared': data['isShared'] ?? false,
            'sharedByUserId': data['sharedByUserId'],
            'sharedByUserName': data['sharedByUserName'],
            'sharedByUserPhotoUrl': data['sharedByUserPhotoUrl'],
            'shareCaption': data['shareCaption'],
            'originalPostId': data['originalPostId'],
            'originalPostAuthorId': data['originalPostAuthorId'],
            'originalPostAuthorName': data['originalPostAuthorName'],
            'originalCreatedAt': data['originalCreatedAt'],
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        }).toList();

        // Sort: featured first, then by date
        docs.sort((a, b) {
          final aFeatured = a['isFeatured'] == true ? 1 : 0;
          final bFeatured = b['isFeatured'] == true ? 1 : 0;
          if (aFeatured != bFeatured) return bFeatured - aFeatured;
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return docs;
      });
});

final filteredUnifiedFeedProvider = Provider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final feedAsync = ref.watch(unifiedFeedProvider);
  final feed = feedAsync.value ?? [];
  final filterType = ref.watch(feedTypeFilterProvider);
  final advancedFilter = ref.watch(unifiedFeedFilterProvider);

  var result = feed;

  // Apply FeedType filter (the tabs/chips)
  switch (filterType) {
    case FeedType.jobs:
      result = result.where((p) => p['isJobPost'] == true).toList();
      break;
    case FeedType.community:
      result = result.where((p) => 
        p['isJobPost'] == false && 
        p['isAvailabilityPost'] == false && 
        (p['eventTitle'] == null || p['eventTitle'].toString().isEmpty)
      ).toList();
      break;
    case FeedType.events:
      result = result.where((p) => p['eventTitle'] != null && p['eventTitle'].toString().isNotEmpty).toList();
      break;
    case FeedType.availability:
      result = result.where((p) => p['isAvailabilityPost'] == true).toList();
      break;
    case FeedType.all:
    default:
      break;
  }

  // Apply Advanced Filters
  if (advancedFilter.onlyJobs) {
    result = result.where((p) => p['isJobPost'] == true).toList();
  }

  if (advancedFilter.onlyMedia) {
    result = result.where((p) => 
      (p['media'] != null && (p['media'] as List).isNotEmpty) || 
      (p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty)
    ).toList();
  }

  if (advancedFilter.searchQuery.isNotEmpty) {
    final q = advancedFilter.searchQuery.toLowerCase();
    result = result.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final text = (p['text'] ?? '').toString().toLowerCase();
      final jobTitle = (p['jobTitle'] ?? '').toString().toLowerCase();
      final companyName = (p['companyName'] ?? '').toString().toLowerCase();
      
      return name.contains(q) || text.contains(q) || jobTitle.contains(q) || companyName.contains(q);
    }).toList();
  }

  return result;
});


final userPostsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('posts')
      .where(Filter.or(
        Filter('uid', isEqualTo: uid),
        Filter('sharedByUserId', isEqualTo: uid),
      ))
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.where((doc) {
          final data = doc.data();
          final isShared = data['isShared'] == true;
          final sharedByUserId = data['sharedByUserId'];
          final postUid = data['uid'];

          if (isShared) {
            // If it's a shared post, only show it on this profile if THIS user shared it
            return sharedByUserId == uid;
          } else {
            // If it's an original post, only show it if THIS user authored it
            return postUid == uid;
          }
        }).map((doc) {
          final data = doc.data();
          final bool isJob = data['isJobPost'] == true;
          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': isJob,
            'isAvailabilityPost': data['isAvailabilityPost'] ?? false,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'shares': data['shares'] ?? 0,
            'hasPendingEdit': data['hasPendingEdit'] ?? false,
            'isShared': data['isShared'] ?? false,
            'sharedByUserId': data['sharedByUserId'],
            'sharedByUserName': data['sharedByUserName'],
            'sharedByUserPhotoUrl': data['sharedByUserPhotoUrl'],
            'shareCaption': data['shareCaption'],
            'originalPostId': data['originalPostId'],
            'originalPostAuthorId': data['originalPostAuthorId'],
            'originalPostAuthorName': data['originalPostAuthorName'],
            'originalCreatedAt': data['originalCreatedAt'],
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        }).toList();


        docs.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return docs;
      });
});

final workerAppliedJobsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final applicationsAsync = ref.watch(userApplicationsProvider);
  
  return applicationsAsync.when(
    data: (applications) async* {
      if (applications.isEmpty) {
        yield [];
        return;
      }

      final List<Future<DocumentSnapshot>> futures = applications.map((app) {
        final jobId = app['jobId'] as String;
        return FirebaseFirestore.instance.collection('posts').doc(jobId).get();
      }).toList();

      final jobSnapshots = await Future.wait(futures);
      
      final List<Map<String, dynamic>> appliedJobs = [];
      for (int i = 0; i < jobSnapshots.length; i++) {
        final doc = jobSnapshots[i];
        final app = applications[i];
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          appliedJobs.add({
            ...data, // Keep all original post data
            'id': doc.id,
            'applicationStatus': app['status'] ?? 'pending', // Inject status
            'isJobPost': true,
          });
        }
      }
      yield appliedJobs;
    },
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (e, st) => Stream.error(e),
  );
});

// ─────────────────────────────────────────────────────────────────────────
// 🔖 SAVED JOBS PROVIDER
// ─────────────────────────────────────────────────────────────────────────

final savedJobsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value([]);

  return PostService.getSavedJobIds(auth.uid).asyncExpand((ids) async* {
    if (ids.isEmpty) {
      yield [];
      return;
    }
    final futures = ids.map((id) =>
        FirebaseFirestore.instance.collection('posts').doc(id).get());
    final snaps = await Future.wait(futures);
    final jobs = snaps
        .where((doc) {
          if (!doc.exists) return false;
          final data = doc.data();
          if (data == null) return false;
          
          final bool isJob = data['isJobPost'] == true;
          final bool isAvailability = data['isAvailabilityPost'] == true;
          final bool isEvent = data['eventTitle'] != null && data['eventTitle'].toString().trim().isNotEmpty;
          final bool isAdmin = data['isAdmin'] == true || data['role'] == 'admin';
          final bool hasJobTitle = data['jobTitle'] != null && 
                                  data['jobTitle'].toString().trim().isNotEmpty;
          
          // Return true ONLY if it's a real job post (not availability, not event)
          return isJob && !isAvailability && !isEvent && (!isAdmin || hasJobTitle);
        })
        .map((doc) {
          final data = doc.data()!;
          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': data['isJobPost'] ?? true,
            'isAvailabilityPost': data['isAvailabilityPost'] ?? false,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isShared': data['isShared'] ?? false,
            'sharedByUserId': data['sharedByUserId'],
            'sharedByUserName': data['sharedByUserName'],
            'sharedByUserPhotoUrl': data['sharedByUserPhotoUrl'],
            'shareCaption': data['shareCaption'],
            'originalPostId': data['originalPostId'],
            'originalPostAuthorId': data['originalPostAuthorId'],
            'originalPostAuthorName': data['originalPostAuthorName'],
            'originalCreatedAt': data['originalCreatedAt'],
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        })
        .toList();
    yield jobs;
  });
});

final systemAnnouncementsProvider = StreamProvider((ref) {
  final auth = ref.watch(authProvider);
  final currentUid = auth?.uid;

  // Usage in FeedScreen:
  // final tabKey = _getTabKey();
  // final feedAsyncValue = ref.watch(feedProvider(tabKey));
  // final filteredPosts = ref.watch(filteredCommunityFeedProvider(tabKey));
  // final theme = Theme.of(context);
  // ...
  // return RefreshIndicator(
  //   backgroundColor: theme.cardColor,
  //   color: AppColors.primary,
  //   onRefresh: () async => ref.refresh(feedProvider(tabKey).future),
  //   child: ListView.builder(
  //     padding: const EdgeInsets.only(top: 8),
  //     itemCount: filteredPosts.length + 2,
  //     itemBuilder: (context, index) {
  //       if (index == 0) return _buildCreatePostArea(context, theme, userPhoto);
  //       if (index == 1) return _buildFeaturedWorkers(theme);
  //       return PostCard(post: filteredPosts[index - 2]);
  //     },
  //   ),
  // );

  return FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Official Update',
              'message': data['message'] ?? '',
              'createdAt': data['createdAt'],
              'type': data['type'] ?? 'general',
              'postId': data['postId'],
              'targetUid': data['targetUid'],
            };
          })
          .where((msg) {
            final target = msg['targetUid'];
            return target == null || target == 'all' || target == 'global' || target == currentUid;
          })
          .toList());
});

// ─────────────────────────────────────────────────────────────────────────
// 🎬 REELS FEED PROVIDER
// ─────────────────────────────────────────────────────────────────────────

final reelsFeedProvider = StreamProvider((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;

  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
        .where((doc) => _canViewPost(doc, blockedUids, hiddenPostIds, currentUid, currentRole))
        .where((doc) {
           final data = doc.data();
           if (data['media'] != null) {
              try {
                final mediaList = List<Map<String, dynamic>>.from(data['media']);
                return mediaList.any((m) {
                   if (m['type'] == 'video') return true;
                   final url = (m['url'] ?? '').toString().toLowerCase();
                   return ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => url.contains('.$ext?') || url.endsWith('.$ext'));
                });
              } catch (e) {
                return false;
              }
           }
           // Fallback for single imageUrl
           if (data['imageUrl'] != null) {
             final url = data['imageUrl'].toString().toLowerCase();
             return ['mp4', 'mov', 'avi', 'mkv', 'webm'].any((ext) => url.contains('.$ext?') || url.endsWith('.$ext'));
           }
           return false;
        })
        .map((doc) {
          final data = doc.data();
          final bool isJob = data['isJobPost'] == true;

          return {
            'id': doc.id,
            'uid': data['uid'] ?? '',
            'name': data['name'] ?? '',
            'companyName': data['companyName'] ?? data['name'] ?? '',
            'text': data['text'] ?? data['description'] ?? '',
            'imageUrl': data['imageUrl'],
            'location': data['location'] ?? '',
            'role': data['role'] ?? data['userRole'] ?? '',
            'profilePhotoUrl': data['profilePhotoUrl'] ?? data['userPhotoUrl'] ?? '',
            'isVerified': data['isVerified'] ?? data['isUserVerified'] ?? false,
            'isAdmin': data['isAdmin'] ?? false,
            'isJobPost': isJob,
            'isAvailabilityPost': data['isAvailabilityPost'] ?? false,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'eventDate': data['eventDate'],
            'eventTime': data['eventTime'],
            'eventLocation': data['eventLocation'],
            'eventTitle': data['eventTitle'],
            'visibility': data['visibility'] ?? 'public',
            'media': data['media'],
            'createdAt': data['createdAt'],
          };
        }).toList();

        return docs;
      });
});

