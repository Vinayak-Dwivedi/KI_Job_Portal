import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/post_service.dart';
import 'auth_provider.dart';
import 'application_provider.dart';

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
  
  if (blockedUids.contains(uid) || hiddenPostIds.contains(doc.id)) return false;
  
  if (uid != currentUid) {
     if (visibility == 'employers' && currentRole != 'employer') return false;
     if (visibility == 'workers' && currentRole != 'worker') return false;
  }
  return true;
}

final feedProvider = StreamProvider((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;

  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .where((doc) => _canViewPost(doc, blockedUids, hiddenPostIds, currentUid, currentRole))
          .map((doc) {
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
              'eventDate': data['eventDate'],
              'eventTime': data['eventTime'],
              'eventLocation': data['eventLocation'],
              'eventTitle': data['eventTitle'],
              'visibility': data['visibility'] ?? 'public',
              'createdAt': data['createdAt'],
            };
          }).toList());
});

final pendingPostsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
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
              'createdAt': data['createdAt'],
            };
          }).toList());
});

final jobFeedProvider = StreamProvider((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  final blockedUids = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['blockedUsers'] ?? []);
  final hiddenPostIds = List<String>.from((userDocAsync.value?.data() as Map<String, dynamic>?)?['hiddenPosts'] ?? []);
  final currentUid = ref.watch(authProvider)?.uid;
  final currentRole = ref.watch(authProvider)?.role;

  return FirebaseFirestore.instance
      .collection('posts')
      .where('isJobPost', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
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
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'createdAt': data['createdAt'],
          };
        }).toList();

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
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'isFeatured': data['isFeatured'] ?? false,
            'featuredUntil': data['featuredUntil'],
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

final unifiedFeedProvider = StreamProvider((ref) {
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
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
            'eventDate': data['eventDate'],
            'eventTime': data['eventTime'],
            'eventLocation': data['eventLocation'],
            'eventTitle': data['eventTitle'],
            'visibility': data['visibility'] ?? 'public',
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

final userPostsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('posts')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) {
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
      for (var doc in jobSnapshots) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          appliedJobs.add({
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
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'createdAt': data['createdAt'],
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
        .where((doc) => doc.exists)
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
            'isJobPost': data['isJobPost'] ?? false,
            'isAvailabilityPost': data['isAvailabilityPost'] ?? false,
            'jobTitle': data['jobTitle'] ?? 'Job Posting',
            'jobSalary': data['jobSalary'] ?? 'Negotiable',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'isFeatured': data['isFeatured'] ?? false,
            'hiringStatus': data['hiringStatus'] ?? 'active',
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