import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

// Fetch public profile data from the unified 'users' collection
String _normalizePhoto(Map<String, dynamic> data) {
  final photoFields = [
    'profilePhotoUrl',
    'photoUrl',
    'profilePic',
    'avatarUrl',
    'imageUrl',
    'photo',
    'profilePicUrl',
  ];
  for (final field in photoFields) {
    final val = data[field];
    if (val != null && val.toString().isNotEmpty) {
      return val.toString();
    }
  }
  return '';
}

// Fetch public profile data from the unified 'users' collection
final publicProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
      try {
        final cleanUid = uid.trim();
        if (cleanUid.isEmpty) return null;

        // Try direct fetch
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cleanUid)
            .get();
        
        // Fallback for admin if UID lookup fails
        if (!doc.exists && (cleanUid == 'uid_admin' || cleanUid.toLowerCase().contains('admin'))) {
          final adminQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();
          if (adminQuery.docs.isNotEmpty) {
            final adminDoc = adminQuery.docs.first;
            final data = adminDoc.data();
            data['id'] = adminDoc.id;
            data['profilePhotoUrl'] = _normalizePhoto(data);
            return data;
          }
        }

        if (!doc.exists) return null;

        final data = doc.data()!;
        data['id'] = doc.id;
        
        // Normalize profile photo field
        data['profilePhotoUrl'] = _normalizePhoto(data);
        
        return data;
      } catch (e) {
        return null;
      }
    });

// Stream to check if the current user has unlocked the target contact info
final isContactUnlockedProvider = StreamProvider.family<bool, String>((
  ref,
  targetUid,
) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('contactCredits')
      .doc(auth.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return false;
        final data = doc.data()!;
        final List contactedList = data['contactedUIDs'] ?? [];
        return contactedList.contains(targetUid);
      });
});

// Stream to watch current user's credit balance
final userCreditsProvider = StreamProvider((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('contactCredits')
      .doc(auth.uid)
      .snapshots()
      .map((doc) => doc.data());
});
// Stream to watch real-time updates for any user profile
final liveProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  final cleanUid = uid.trim();
  if (cleanUid.isEmpty) return Stream.value(null);
  
  // NOTE: Fallback in stream for admin mock UIDs
  if (cleanUid == 'uid_admin' || cleanUid.toLowerCase().contains('admin')) {
     return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'admin')
      .limit(1)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        final doc = snap.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        data['profilePhotoUrl'] = _normalizePhoto(data);
        return data;
      });
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(cleanUid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        data['id'] = doc.id;
        
        // Normalize profile photo field
        data['profilePhotoUrl'] = _normalizePhoto(data);
        
        return data;
      });
});
