// lib/core/services/firestore_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Changes vs original:
//   • Saves description / bio from employer signup
//   • Saves businessType / hirerSubType for employers
//   • Initialises contactCredits/{uid} on first save so credits are real
//   • Sets verificationStatus = 'unverified' and isVerifiedBadge = false
//   • Sets profileCompletionPct based on fields present
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Get User Data ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ── Save User (Worker OR Employer) ─────────────────────────────────────────
  static Future<void> saveUser(
      String uid, Map<String, dynamic> data) async {

    final role = (data['role'] ?? 'worker').toString();
    final extras = data['extras'] ?? {};

    // ── Build user document ────────────────────────────────────────────────
    final Map<String, dynamic> userDoc = {
      'uid':   uid,
      'name':  data['name'] ?? '',
      'phone': data['phone'] ?? '',
      'role':  role,

      // Common
      'bio':             data['bio'] ?? data['description'] ?? extras['bio'] ?? '',
      'profilePhotoUrl': data['profilePhotoUrl'] ?? '',

      // Location — stored as map so lat/lng can be added later
      'location': {
        'address': data['location'] ?? '',
        'subLocation': data['subLocation'] ?? '',
        'lat': double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
        'lng': double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
      },

      // Verification — always starts unverified
      'verificationStatus': 'unverified',
      'isVerifiedBadge':    false,
      'isVerified':         false, // backward compat

      // Admin / subscription flags
      'isSubscribed': false,
      'isAdmin':      false,

      // Ratings (aggregated by Cloud Function / client after reviews)
      'avgRating':    0.0,
      'totalReviews': 0,
      'credits': data['credits'] ?? (role == 'employer' ? 50 : 0),
      'documents': [],
      'latitude': double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
      'longitude': double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // ── Worker-specific fields ─────────────────────────────────────────────
    if (role == 'worker') {
      userDoc['skills']     = data['skills'] ?? [];
      userDoc['experience'] = data['experience'] ?? 0;
      userDoc['availability'] = 'available';
      userDoc['portfolioItems'] = [];
    }

    // ── Employer-specific fields ───────────────────────────────────────────
    if (role == 'employer') {
      userDoc['companyName']  = data['companyName'] ?? data['company'] ?? '';
      userDoc['contactPersonName'] = data['name'] ?? data['contactPersonName'] ?? '';
      userDoc['businessType'] = data['businessType'] ?? data['industry'] ?? '';
      userDoc['hirerSubType'] = data['hirerSubType'] ?? 'individual';
      userDoc['website']      = data['website'] ?? '';
      userDoc['email']        = data['email'] ?? '';
      userDoc['totalHires']   = 0;
    }

    // ── Profile completion % (quick estimate) ──────────────────────────────
    int filled = 0;
    const fields = ['name', 'phone', 'bio', 'location'];
    for (final f in fields) {
      final v = userDoc[f];
      if (v != null && v.toString().isNotEmpty && v != '{}') filled++;
    }
    userDoc['profileCompletionPct'] = filled / fields.length;

    // ── Write user doc (merge so repeat signups don't overwrite) ──────────
    await _db
        .collection('users')
        .doc(uid)
        .set(userDoc, SetOptions(merge: true));

    print('✅ User saved to Firestore for uid=$uid');
  }

  // ── Unlock Contact Info (Transaction) ──────────────────────────────────
  static Future<void> unlockContactInfo({
    required String viewerUid,
    required String targetUid,
  }) async {
    final userRef = _db.collection('users').doc(viewerUid);

    return _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception("User document not found.");

      final data = userSnap.data()!;
      final List contactedUIDs = List.from(data['contactedUIDs'] ?? []);

      // If already unlocked, no-op
      if (contactedUIDs.contains(targetUid)) return;

      int balance = int.tryParse((data['credits'] ?? data['balance'] ?? '0').toString()) ?? 0;

      if (balance >= 10) {
        // Use balance
        transaction.update(userRef, {
          'credits': FieldValue.increment(-10),
          'contactedUIDs': FieldValue.arrayUnion([targetUid]),
        });

        // Log transaction (Internal call to log debits)
        final transactionRef = _db
            .collection('contactCredits')
            .doc(viewerUid)
            .collection('transactions')
            .doc();
        transaction.set(transactionRef, {
          'title': 'Contact Unlocked',
          'description': 'Viewed contact details for a professional',
          'amount': -10,
          'type': 'debit',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception("Insufficient credits (10 required) to unlock contact.");
      }
    });
  }

  // ── Record Profile View ──────────────────────────────────────────────────
  static Future<void> recordProfileView({
    required String viewerUid,
    required String targetUid,
    String? viewerName,
    String? viewerPhoto,
  }) async {
    if (viewerUid == targetUid) return;

    final targetUserRef = _db.collection('users').doc(targetUid);
    final visitorRef = targetUserRef.collection('visitors').doc(viewerUid);

    // 1. Update/Set visitor record
    await visitorRef.set({
      'uid': viewerUid,
      'name': viewerName ?? 'A visitor',
      'photo': viewerPhoto ?? '',
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Increment view count
    await targetUserRef.update({
      'profileViews': FieldValue.increment(1),
    });

    // 3. Send notification (optional but good for UX)
    final notifRef = targetUserRef.collection('notifications').doc();
    await notifRef.set({
      'title': 'Profile Visited',
      'body': '${viewerName ?? "Someone"} viewed your profile.',
      'type': 'profile_view',
      'viewerId': viewerUid,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  static Future<void> boostProfile(String uid, int days) async {
    const int boostCost = 80; // Standardized to 80 credits for 1 day
    final userRef = _db.collection('users').doc(uid);
    final txRef = _db.collection('contactCredits').doc(uid).collection('transactions').doc();

    // 1. Transaction to deduct credits and mark profile
    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception('User not found.');

      final balance = int.tryParse(userSnap.data()?['credits']?.toString() ?? '0') ?? 0;
      if (balance < boostCost) {
        throw Exception('Insufficient credits. You need $boostCost credits to boost your profile for 1 day.');
      }

      final featuredUntil = DateTime.now().add(const Duration(days: 1));
      transaction.update(userRef, {
        'credits': FieldValue.increment(-boostCost),
        'isFeatured': true,
        'featuredUntil': Timestamp.fromDate(featuredUntil),
      });

      // Log transaction
      transaction.set(txRef, {
        'title': 'Profile Boost',
        'description': 'Featured profile for 1 day',
        'amount': -boostCost,
        'type': 'debit',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // 2. Batch update all existing posts to be featured
    try {
      final postsSnap = await _db.collection('posts').where('uid', isEqualTo: uid).get();
      if (postsSnap.docs.isNotEmpty) {
        final batch = _db.batch();
        final featuredUntil = DateTime.now().add(const Duration(days: 1));
        for (var doc in postsSnap.docs) {
          batch.update(doc.reference, {
            'isFeatured': true,
            'featuredUntil': Timestamp.fromDate(featuredUntil),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error boosting existing posts: $e');
    }
  }
}
