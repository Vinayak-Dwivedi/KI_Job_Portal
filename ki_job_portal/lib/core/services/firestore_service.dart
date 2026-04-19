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

      // Documents list — expanded by user later in edit profile
      'documents': [],

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

    // ── Initialise contactCredits (only if doc doesn't exist yet) ─────────
    final credRef = _db.collection('contactCredits').doc(uid);
    final credSnap = await credRef.get();
    if (!credSnap.exists) {
      await credRef.set({
        'balance':          50,      // initial credits
        'freeCreditsUsed':  0,
        'freeLimit':        0,       // no separate free contacts, just balance
        'contactedUIDs':    [],
        'subscriptionTier': 'free',
        'subscriptionExpiry': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    print('✅ User + contactCredits saved to Firestore for uid=$uid');
  }

  // ── Unlock Contact Info (Transaction) ──────────────────────────────────
  static Future<void> unlockContactInfo({
    required String viewerUid,
    required String targetUid,
  }) async {
    final credRef = _db.collection('contactCredits').doc(viewerUid);

    return _db.runTransaction((transaction) async {
      final credSnap = await transaction.get(credRef);
      if (!credSnap.exists) throw Exception("Credit document not found.");

      final data = credSnap.data()!;
      final List contactedUIDs = List.from(data['contactedUIDs'] ?? []);

      // If already unlocked, no-op
      if (contactedUIDs.contains(targetUid)) return;

      int balance = int.tryParse(data['balance']?.toString() ?? '0') ?? 0;

      if (balance >= 10) {
        // Use balance
        transaction.update(credRef, {
          'balance': FieldValue.increment(-10),
          'contactedUIDs': FieldValue.arrayUnion([targetUid]),
        });
      } else {
        throw Exception("Insufficient credits (10 required) to unlock contact.");
      }
    });
  }
}
