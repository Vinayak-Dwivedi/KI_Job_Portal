import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

final relationshipProvider = Provider((ref) => RelationshipService(ref));

class RelationshipService {
  final Ref _ref;
  RelationshipService(this._ref);

  Future<void> followUser(String targetUid) async {
    final user = _ref.read(authProvider);
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Add to following
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(targetUid);
    batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});

    // Add to followers
    final followersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(user.uid);
    batch.set(followersRef, {'timestamp': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  Future<void> unfollowUser(String targetUid) async {
    final user = _ref.read(authProvider);
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Remove from following
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(targetUid);
    batch.delete(followingRef);

    // Remove from followers
    final followersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(user.uid);
    batch.delete(followersRef);

    await batch.commit();
  }

  Stream<bool> isFollowing(String targetUid) {
    final user = _ref.watch(authProvider);
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> getFollowerCount(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getFollowingCount(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<Map<String, int>> getStats(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((doc) async {
          final followers = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('followers')
              .get();
          final following = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('following')
              .get();
          return {
            'followers': followers.docs.length,
            'following': following.docs.length,
          };
        });
  }

  Stream<List<String>> getFollowers(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> getFollowing(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
