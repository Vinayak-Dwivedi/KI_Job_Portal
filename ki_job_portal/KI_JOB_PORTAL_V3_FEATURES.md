# KI-Job Portal — Feature Update v3
## AI Agent Build Instructions · Feed + Subscriptions + Admin Panel + Profile Images + Post Flow

> **Extends:** KI_JOB_PORTAL_STRUCTURE.md (v1) + v2 update  
> **Stack:** Flutter (Android) · Firebase Auth (Phone OTP) · Cloud Firestore · Firebase Storage · Razorpay (future-ready)  
> **New Roles:** Admin (new) · Worker (existing) · Employer (existing)  
> **Agent Rule:** All sections below are ADDITIVE to existing structure. Do not remove or rewrite existing screens unless explicitly stated.

---

## TABLE OF CONTENTS

1. [New File Tree Additions](#1-new-file-tree-additions)
2. [Firestore Schema Updates](#2-firestore-schema-updates)
3. [Profile Image Upload](#3-profile-image-upload)
4. [Post Creation Flow](#4-post-creation-flow)
5. [LinkedIn-Style Feed System](#5-linkedin-style-feed-system)
6. [Subscription System](#6-subscription-system)
7. [Payment Integration (Razorpay-Ready)](#7-payment-integration-razorpay-ready)
8. [Admin Panel](#8-admin-panel)
9. [Firebase Security Rules](#9-firebase-security-rules-full-updated)
10. [Providers & Services](#10-providers--services)
11. [UI Specifications](#11-ui-specifications)
12. [pubspec.yaml Additions](#12-pubspecyaml-additions)
13. [Build Order Phase 11–15](#13-build-order-phase-1115)
14. [Critical Rules for Agent](#14-critical-rules-for-agent)

---

## 1. New File Tree Additions

Add these files into the existing project tree:

```
lib/
│
├── core/
│   └── services/
│       ├── post_service.dart              # CRUD for posts
│       ├── subscription_service.dart      # Subscribe, check status, expire
│       ├── admin_service.dart             # Approve/reject posts, ban users
│       ├── analytics_service.dart         # Aggregate counts for admin
│       └── pdf_export_service.dart        # Export analytics as PDF
│
├── models/
│   ├── post_model.dart
│   ├── subscription_model.dart
│   └── analytics_model.dart
│
├── providers/
│   ├── post_provider.dart
│   ├── feed_provider.dart
│   ├── subscription_provider.dart
│   └── admin_provider.dart
│
├── screens/
│   │
│   ├── feed/
│   │   ├── feed_screen.dart               # LinkedIn-style global feed
│   │   ├── create_post_screen.dart        # Text + image(s) post creation
│   │   └── post_detail_screen.dart        # Single post expanded view
│   │
│   ├── profile/
│   │   ├── profile_image_picker.dart      # Reusable image upload widget screen
│   │   ├── worker_profile_screen.dart     # UPDATE: add profile photo + posts tab
│   │   └── employer_profile_screen.dart   # UPDATE: add logo + posts tab
│   │
│   ├── subscription/
│   │   ├── subscription_plans_screen.dart # Plans + pricing UI
│   │   ├── subscription_checkout_screen.dart  # Razorpay trigger point
│   │   └── subscription_success_screen.dart   # Post-payment confirmation
│   │
│   └── admin/
│       ├── admin_login_screen.dart        # Separate admin login (email+pass)
│       ├── admin_dashboard_screen.dart    # Analytics overview
│       ├── admin_posts_screen.dart        # Pending/approved/rejected posts list
│       ├── admin_users_screen.dart        # User list + ban/unban
│       └── admin_analytics_screen.dart    # Charts + PDF export
│
└── widgets/
    ├── feed/
    │   ├── post_card.dart                 # Feed post card widget
    │   ├── post_image_grid.dart           # 1/2/3+ image layout in post
    │   └── post_pending_banner.dart       # "Awaiting admin approval" banner
    │
    ├── subscription/
    │   ├── subscription_gate_widget.dart  # Wrap any gated content
    │   └── subscribe_prompt_card.dart     # CTA card for non-subscribers
    │
    └── admin/
        ├── analytics_stat_card.dart
        ├── pending_post_card.dart
        └── user_row_tile.dart
```

---

## 2. Firestore Schema Updates

### 2A. Update `users/{uid}` document

Add these fields to the existing `users` document:

```
users/{uid}
├── ... (existing fields)
├── profilePhotoUrl: string          # Firebase Storage URL
├── isSubscribed: bool               # default: false
├── subscriptionStart: timestamp?    # null if never subscribed
├── subscriptionEnd: timestamp?      # null if never subscribed
├── isBanned: bool                   # default: false — set by admin
├── isAdmin: bool                    # default: false — set manually or via claim
└── postIds: [string]                # list of post IDs by this user
```

### 2B. Update `workers/{uid}` and `employers/{uid}`

```
workers/{uid} / employers/{uid}
├── ... (existing fields)
└── profilePhotoUrl: string          # mirrors users/{uid}.profilePhotoUrl
```

### 2C. New collection: `posts`

```
posts/
└── {postId}/
    ├── postId: string               # same as doc ID
    ├── userId: string               # UID of creator
    ├── userRole: "worker" | "employer"
    ├── userName: string             # denormalized for feed display
    ├── userPhotoUrl: string         # denormalized
    ├── isUserVerified: bool         # denormalized verified badge
    ├── title: string                # optional short title
    ├── description: string          # main post content (max 1000 chars)
    ├── imageUrls: [string]          # 0–4 Firebase Storage URLs
    ├── status: "pending" | "approved" | "rejected"
    ├── rejectionReason: string?     # filled by admin on reject
    ├── createdAt: timestamp
    ├── approvedAt: timestamp?
    └── likeCount: int               # for future engagement feature
```

### 2D. New collection: `subscriptions`

```
subscriptions/
└── {subscriptionId}/               # auto-ID
    ├── userId: string
    ├── plan: "basic" | "standard" | "premium"
    ├── amount: int                  # in paise (₹99 = 9900)
    ├── status: "active" | "expired" | "pending" | "failed"
    ├── paymentId: string?           # Razorpay payment ID
    ├── orderId: string?             # Razorpay order ID
    ├── createdAt: timestamp
    └── expiresAt: timestamp
```

### 2E. New collection: `admin_analytics` (cached aggregates)

```
admin_analytics/
└── summary/                        # single document, updated by Cloud Function or admin service
    ├── totalUsers: int
    ├── totalWorkers: int
    ├── totalEmployers: int
    ├── subscribedUsers: int
    ├── activeUsersLast30Days: int
    ├── totalPosts: int
    ├── pendingPosts: int
    ├── approvedPosts: int
    ├── rejectedPosts: int
    └── lastUpdated: timestamp
```

---

## 3. Profile Image Upload

### 3A. Firebase Storage path

```
Storage paths:
  Profile photos:  users/{uid}/profile.jpg
  Post images:     posts/{postId}/image_0.jpg
                   posts/{postId}/image_1.jpg
                   (up to image_3.jpg)
```

### 3B. `profile_image_picker.dart` widget

```dart
// lib/screens/profile/profile_image_picker.dart
// A reusable bottom-sheet triggered widget used on both worker and employer profile edit screens.

class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String newUrl) onUploaded;
  const ProfileImagePicker({required this.onUploaded, this.currentImageUrl});
}

// Behavior:
// 1. Tap the avatar circle → shows bottom sheet with options:
//    "Take Photo" (camera) | "Choose from Gallery" | "Remove Photo"
// 2. On image selected:
//    a. Show circular crop dialog (image_cropper package)
//    b. Upload to Firebase Storage at users/{uid}/profile.jpg
//    c. Get download URL
//    d. Update users/{uid}.profilePhotoUrl in Firestore
//    e. Update workers/{uid}.profilePhotoUrl OR employers/{uid}.profilePhotoUrl
//    f. Call onUploaded(url) to update local state
// 3. Show upload progress indicator inside the avatar circle (CircularProgressIndicator overlay)
// 4. On success: animate avatar to new image with a subtle scale bounce

Widget build(BuildContext context) {
  return GestureDetector(
    onTap: _showBottomSheet,
    child: Stack(
      children: [
        // Avatar circle
        CircleAvatar(
          radius: 52,
          backgroundImage: _imageUrl != null
              ? NetworkImage(_imageUrl!) as ImageProvider
              : const AssetImage('assets/images/default_avatar.png'),
          child: _isUploading
              ? Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45, shape: BoxShape.circle),
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : null,
        ),
        // Camera edit icon overlay
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
          ),
        ),
      ],
    ),
  );
}

void _showBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Take Photo'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from Gallery'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        ),
        if (_imageUrl != null)
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(context); _removePhoto(); },
          ),
      ]),
    ),
  );
}
```

### 3C. Upload service method

```dart
// lib/core/services/storage_service.dart  — add this method

Future<String> uploadProfilePhoto(String uid, File imageFile) async {
  final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
  final uploadTask = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}

// After upload, update Firestore:
Future<void> updateProfilePhoto(String uid, String role, String url) async {
  final batch = FirebaseFirestore.instance.batch();
  batch.update(FirebaseFirestore.instance.collection('users').doc(uid),
      {'profilePhotoUrl': url});
  batch.update(
      FirebaseFirestore.instance.collection('${role}s').doc(uid),
      {'profilePhotoUrl': url});
  await batch.commit();
}
```

---

## 4. Post Creation Flow

### 4A. `create_post_screen.dart`

```dart
// lib/screens/feed/create_post_screen.dart
// Accessible from:
//   - Worker dashboard bottom nav "Post" tab
//   - Employer dashboard bottom nav "Post" tab
//   - Feed screen FAB (floating action button)

// UI Layout:
// ┌──────────────────────────────────────┐
// │ ←  Create Post              [Post →] │
// ├──────────────────────────────────────┤
// │ [Avatar] Ravi Kumar · Electrician    │
// │                                      │
// │ Title (optional)                     │
// │ [________________________________]   │
// │                                      │
// │ What's on your mind?                 │
// │ [________________________________]   │
// │ [________________________________]   │
// │ [________________________________]   │
// │ (max 1000 characters, counter shown) │
// │                                      │
// │ ┌──────┐ ┌──────┐ ┌──────┐ [+Add]   │
// │ │img 1 │ │img 2 │ │img 3 │          │  (up to 4 images)
// │ └──────┘ └──────┘ └──────┘          │
// │                                      │
// │ 📷 Add Photos                        │
// └──────────────────────────────────────┘

class CreatePostScreen extends ConsumerStatefulWidget { ... }

// State:
String _title = '';
String _description = '';
List<File> _selectedImages = [];    // max 4
bool _isPosting = false;

// Validation:
// - description cannot be empty
// - max 4 images
// - max 1000 chars in description

Future<void> _submitPost() async {
  if (_description.trim().isEmpty) {
    _showError('Please write something before posting');
    return;
  }

  setState(() => _isPosting = true);

  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final postId = FirebaseFirestore.instance.collection('posts').doc().id;

    // 1. Upload images to Storage (parallel)
    final imageUrls = await Future.wait(
      _selectedImages.asMap().entries.map((e) =>
        StorageService.uploadPostImage(uid, postId, e.key, e.value)
      ),
    );

    // 2. Write post document (status = "pending")
    await FirebaseFirestore.instance.collection('posts').doc(postId).set({
      'postId': postId,
      'userId': uid,
      'userRole': ref.read(userRoleProvider),
      'userName': ref.read(userNameProvider),
      'userPhotoUrl': ref.read(userPhotoProvider),
      'isUserVerified': ref.read(isUserVerifiedProvider),
      'title': _title.trim(),
      'description': _description.trim(),
      'imageUrls': imageUrls,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
    });

    // 3. Add postId to user's postIds array
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'postIds': FieldValue.arrayUnion([postId]),
    });

    setState(() => _isPosting = false);

    // 4. Show success notification + pop screen
    _showPostSuccessBanner(context);
    Future.delayed(const Duration(milliseconds: 400), () {
      Navigator.pop(context);
    });

  } catch (e) {
    setState(() => _isPosting = false);
    _showError('Failed to post. Please try again.');
  }
}
```

### 4B. Post Success Banner (top overlay)

```dart
// lib/widgets/feed/post_pending_banner.dart
// Same overlay mechanism as applied_banner.dart (Section 18B in v2)
// Slides from top, stays 4 seconds, auto-dismisses

// Content:
// ✅  "Post Submitted!"
//     "Your post will go live once approved by our admin."

void showPostPendingBanner(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PostPendingBannerWidget(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

// Widget appearance:
// Background color: Color(0xFF1A56DB) (blue — not green, since it's pending not confirmed)
// Icon: Icons.schedule (clock) — indicates "waiting for review"
// Title: "Post Submitted!"
// Subtitle: "Your post will go live once approved by admin."
// Animation: same SlideTransition from Offset(0, -1) to Offset.zero with easeOutBack
```

### 4C. Image upload for posts

```dart
// lib/core/services/storage_service.dart  — add:

Future<String> uploadPostImage(String uid, String postId, int index, File imageFile) async {
  final ref = FirebaseStorage.instance
      .ref('posts/$postId/image_$index.jpg');
  final task = await ref.putFile(imageFile,
      SettableMetadata(contentType: 'image/jpeg'));
  return await task.ref.getDownloadURL();
}
```

### 4D. Image grid widget in post card

```dart
// lib/widgets/feed/post_image_grid.dart
// Renders 0–4 images in different layouts:

// 0 images: show nothing
// 1 image: full width, height 220, border radius 12
// 2 images: side by side, each half width, height 180
// 3 images: left full height + right column with 2 stacked, height 220
// 4 images: 2x2 grid, each cell height 140

Widget build(BuildContext context) {
  switch (urls.length) {
    case 0: return const SizedBox.shrink();
    case 1: return _single(urls[0]);
    case 2: return _two(urls);
    case 3: return _three(urls);
    default: return _four(urls);
  }
}

// All images use CachedNetworkImage with shimmer placeholder
// All images are wrapped in GestureDetector → opens full-screen photo_view on tap
```

---

## 5. LinkedIn-Style Feed System

### 5A. `feed_screen.dart`

```dart
// lib/screens/feed/feed_screen.dart

// Feed structure (top to bottom):
// 1. AppBar: "Feed" title + notification bell icon
// 2. Create Post bar (tappable, navigates to create_post_screen.dart):
//    [User Avatar] [What's on your mind? (greyed placeholder)]  [📷]
// 3. ListView.builder of PostCards
//    - Only shows posts where status == "approved"
//    - Sorted by createdAt descending
//    - Shimmer loading while fetching

// Data query:
final approvedFeedQuery = FirebaseFirestore.instance
    .collection('posts')
    .where('status', isEqualTo: 'approved')
    .orderBy('createdAt', descending: true)
    .limit(20);   // paginate with startAfterDocument

// Pagination:
// Use ScrollController + listener to load next 20 when near bottom
// Keep List<DocumentSnapshot> _lastDoc for pagination cursor
```

### 5B. `post_card.dart`

```dart
// lib/widgets/feed/post_card.dart

// Card layout:
// ┌────────────────────────────────────────┐
// │ [Avatar] Name · Role     Verified ✅   │
// │          2 hours ago                   │
// ├────────────────────────────────────────┤
// │ Title (bold, if present)               │
// │ Description text (max 3 lines, "more") │
// ├────────────────────────────────────────┤
// │ [Image grid — 0 to 4 images]           │
// ├────────────────────────────────────────┤
// │ 👍 Like   💬 Comment   ↗ Share         │  (future engagement — wire up later)
// └────────────────────────────────────────┘

// Tapping the card → post_detail_screen.dart (slideRightPage transition)
// Tapping the avatar/name → public profile of the post owner
// "more" expands description in-place (setState toggle)
```

### 5C. My Posts section on profile

On both `worker_profile_screen.dart` and `employer_profile_screen.dart`, add a **"My Posts"** tab:

```dart
// Tab controller with 2 tabs: "Profile" | "Posts"
// Posts tab:
//   - Shows own posts (ALL statuses — pending/approved/rejected)
//   - Pending: show amber banner "Awaiting approval"
//   - Rejected: show red banner "Rejected" + reason if available
//   - Approved: show normal post card

// Query:
FirebaseFirestore.instance
    .collection('posts')
    .where('userId', isEqualTo: uid)
    .orderBy('createdAt', descending: true)
```

---

## 6. Subscription System

### 6A. Plans

| Plan | Credits | Duration | Price (₹) | Razorpay Amount (paise) |
|------|---------|----------|-----------|------------------------|
| Basic | 20 | 30 days | 99 | 9900 |
| Standard | 60 | 30 days | 249 | 24900 |
| Premium | 150 | 30 days | 499 | 49900 |

### 6B. `subscription_service.dart`

```dart
// lib/core/services/subscription_service.dart

class SubscriptionService {

  // Check if user's subscription is currently active
  static Future<bool> isSubscriptionActive(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    if (!(data['isSubscribed'] ?? false)) return false;
    final end = (data['subscriptionEnd'] as Timestamp?)?.toDate();
    if (end == null) return false;
    return end.isAfter(DateTime.now());
  }

  // Activate subscription after successful payment
  // Called from payment success callback
  static Future<void> activateSubscription({
    required String uid,
    required String plan,
    required int amount,
    required String paymentId,
    required String orderId,
  }) async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 30));

    final batch = FirebaseFirestore.instance.batch();

    // Update user doc
    batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
      'isSubscribed': true,
      'subscriptionStart': Timestamp.fromDate(now),
      'subscriptionEnd': Timestamp.fromDate(end),
    });

    // Write subscription record
    final subRef = FirebaseFirestore.instance.collection('subscriptions').doc();
    batch.set(subRef, {
      'userId': uid,
      'plan': plan,
      'amount': amount,
      'status': 'active',
      'paymentId': paymentId,
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(end),
    });

    await batch.commit();
  }

  // Deactivate expired subscriptions (call on app launch + auth state change)
  static Future<void> checkAndDeactivateIfExpired(String uid) async {
    final isActive = await isSubscriptionActive(uid);
    if (!isActive) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isSubscribed': false,
      });
    }
  }
}
```

### 6C. `subscription_gate_widget.dart`

```dart
// lib/widgets/subscription/subscription_gate_widget.dart
// Wraps ANY content that requires an active subscription.
// If not subscribed: shows subscribe_prompt_card.dart instead.

class SubscriptionGate extends ConsumerWidget {
  final Widget child;
  final String gatedItemDescription;   // e.g. "contact details"
  const SubscriptionGate({required this.child, required this.gatedItemDescription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed = ref.watch(subscriptionStatusProvider);
    return isSubscribed.when(
      data: (active) => active ? child : SubscribePromptCard(item: gatedItemDescription),
      loading: () => const SizedBox(height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Usage example in worker_detail_screen.dart:
SubscriptionGate(
  gatedItemDescription: 'contact details',
  child: ContactRevealedWidget(phone: employer.phone, email: employer.email),
)
```

### 6D. `subscribe_prompt_card.dart`

```dart
// lib/widgets/subscription/subscribe_prompt_card.dart

// Visual:
// ┌──────────────────────────────────────────────┐
// │ 🔒  Subscribe to view [contact details]      │
// │     Unlock contact info, messages & more     │
// │                                              │
// │  [  View Plans  →  ]                         │
// └──────────────────────────────────────────────┘

// Tapping "View Plans" → context.push('/subscription/plans')
```

### 6E. `subscription_plans_screen.dart`

```dart
// lib/screens/subscription/subscription_plans_screen.dart

// Layout:
// AppBar: "Choose a Plan"
// Subtitle: "Get full access to connect with workers/employers"
//
// Three plan cards (vertical list):
// ┌──────────────────────────────────────────┐
// │ ⭐ Standard  ← "Most Popular" badge       │
// │ ₹249 / month                             │
// │ • 60 connection credits                  │
// │ • View contact details                   │
// │ • Message workers/employers              │
// │ • Priority search listing                │
// │                      [Subscribe Now →]   │
// └──────────────────────────────────────────┘
//
// Selected plan border: Color(0xFF1A56DB) with slight scale up animation
// "Subscribe Now" → subscription_checkout_screen.dart with plan details

// Current subscription status banner (if already subscribed):
// "Your [Standard] plan is active until [date]"
// Green banner at top
```

### 6F. `subscription_checkout_screen.dart`

```dart
// lib/screens/subscription/subscription_checkout_screen.dart
// This is the Razorpay trigger point.

// UI:
// Order summary card (plan, amount, validity)
// "Pay ₹249 with Razorpay" button
// UPI/card logos row

// Razorpay integration (FUTURE-READY structure):
void _initiatePayment() async {
  // Step 1: Create order on your backend / Cloud Function
  // POST /createOrder → returns { orderId, amount, currency }
  // For now: use a placeholder orderId for testing

  // Step 2: Open Razorpay checkout
  var options = {
    'key': 'YOUR_RAZORPAY_KEY_HERE',           // Replace with env variable
    'amount': plan.amountInPaise,
    'name': 'Bharat Karigar',
    'description': '${plan.name} Plan - 30 days',
    'order_id': _orderId,
    'prefill': {
      'contact': currentUserPhone,
    },
    'theme': {'color': '#1A56DB'},
  };

  // Step 3: Handle response
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
    await SubscriptionService.activateSubscription(
      uid: uid,
      plan: plan.id,
      amount: plan.amountInPaise,
      paymentId: response.paymentId!,
      orderId: response.orderId!,
    );
    context.go('/subscription/success');
  });

  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    _showError('Payment failed: ${response.message}');
  });

  _razorpay.open(options);
}

// NOTE TO AGENT:
// razorpay_flutter package requires minSdkVersion 19 in android/app/build.gradle
// Add: implementation 'com.razorpay:checkout:1.6.33' in android/app/build.gradle
```

---

## 7. Payment Integration (Razorpay-Ready)

### 7A. Android manifest + gradle changes

```xml
<!-- android/app/src/main/AndroidManifest.xml — add inside <application> -->
<activity
  android:name="com.razorpay.CheckoutActivity"
  android:configChanges="keyboard|keyboardHidden|orientation|screenSize"
  android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

```groovy
// android/app/build.gradle
android {
  defaultConfig {
    minSdkVersion 21   // Razorpay requires minimum 19, use 21 for safety
  }
}
dependencies {
  implementation 'com.razorpay:checkout:1.6.33'
}
```

### 7B. Cloud Function stub (future backend)

```javascript
// functions/index.js — Firebase Cloud Function stub
// Deploy this when backend is ready

exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');

  const Razorpay = require('razorpay');
  const rzp = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });

  const order = await rzp.orders.create({
    amount: data.amount,        // in paise
    currency: 'INR',
    receipt: `receipt_${Date.now()}`,
  });

  return { orderId: order.id, amount: order.amount };
});
```

---

## 8. Admin Panel

### 8A. Admin Authentication

```dart
// lib/screens/admin/admin_login_screen.dart
// Admin logs in with EMAIL + PASSWORD (not phone OTP)
// After login, check Firestore users/{uid}.isAdmin == true
// If not admin → sign out + show "Access denied"

// Admin account setup (manual, one-time):
// 1. Create user in Firebase Auth Console with email + password
// 2. In Firestore, set users/{adminUid}.isAdmin = true
// 3. Admin app entry point: separate route '/admin/login'
//    Recommend: separate admin flavor OR a hidden route accessible via deep link

Future<void> _adminLogin(String email, String password) async {
  final cred = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
  final doc = await FirebaseFirestore.instance
      .collection('users').doc(cred.user!.uid).get();
  if (doc.data()?['isAdmin'] != true) {
    await FirebaseAuth.instance.signOut();
    throw Exception('Access denied');
  }
  context.go('/admin/dashboard');
}
```

### 8B. `admin_dashboard_screen.dart`

```dart
// lib/screens/admin/admin_dashboard_screen.dart

// Layout:
// AppBar: "Admin Dashboard" + logout icon
// Bottom nav: Dashboard | Posts | Users
//
// Dashboard tab:
// ┌─────────────────────────────────────┐
// │ BHARAT KARIGAR ADMIN                │
// │ Last updated: [timestamp]           │
// ├──────────┬──────────┬───────────────┤
// │ 👥       │ 💼       │ ✅            │
// │ 1,240    │ 845      │ 312           │
// │ Total    │ Workers  │ Subscribed    │
// │ Users    │          │               │
// ├──────────┼──────────┼───────────────┤
// │ 🏢       │ 📝       │ ⏳            │
// │ 395      │ 540      │ 23            │
// │ Employers│ Posts    │ Pending       │
// └──────────┴──────────┴───────────────┘
//
// Quick Actions:
// [Review Pending Posts (23)] [Export PDF]

// Stat cards use analytics_stat_card.dart widget
// Data pulled from admin_analytics/summary doc
// "Refresh" button triggers AnalyticsService.refreshSummary()
```

### 8C. `admin_posts_screen.dart`

```dart
// lib/screens/admin/admin_posts_screen.dart

// Three tabs: Pending | Approved | Rejected
// Default tab: Pending (most urgent)
//
// Each pending post shows pending_post_card.dart:
// ┌──────────────────────────────────────────┐
// │ [Avatar] Name · Role · Posted 2h ago     │
// │ Title: "Looking for electrician"         │
// │ Description: (first 150 chars...)        │
// │ [Images: 2 thumbnails if present]        │
// │                                          │
// │ [✗ Reject]              [✓ Approve]      │
// └──────────────────────────────────────────┘

// Approve flow:
Future<void> _approvePost(String postId) async {
  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
    'status': 'approved',
    'approvedAt': FieldValue.serverTimestamp(),
  });
  // Update analytics summary
  await AnalyticsService.incrementApproved();
  _showSnack('Post approved and live!');
}

// Reject flow:
// Show bottom sheet with text field for rejection reason
Future<void> _rejectPost(String postId, String reason) async {
  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
    'status': 'rejected',
    'rejectionReason': reason,
  });
  await AnalyticsService.incrementRejected();
  _showSnack('Post rejected.');
}
```

### 8D. `admin_users_screen.dart`

```dart
// lib/screens/admin/admin_users_screen.dart

// Filter chips: All | Workers | Employers | Subscribed | Banned
// Search bar: search by name or phone
//
// Each row (user_row_tile.dart):
// [Avatar] Name · Role · Verified badge      [Ban / Unban]
//          Phone number                       (red / green)
//          Subscribed: Yes (until Jan 2026)

// Ban user:
Future<void> _banUser(String uid) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'isBanned': true,
  });
  // Banned users: block login in auth_gate.dart by checking isBanned on each auth state change
}

// Unban user:
Future<void> _unbanUser(String uid) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'isBanned': false,
  });
}
```

### 8E. Ban enforcement in `auth_gate.dart`

```dart
// lib/screens/auth/auth_gate.dart — update redirect logic

final userDoc = await FirebaseFirestore.instance
    .collection('users').doc(user.uid).get();

if (userDoc.data()?['isBanned'] == true) {
  await FirebaseAuth.instance.signOut();
  // Navigate to banned screen or show dialog
  return '/banned';
}
```

### 8F. Analytics PDF Export

```dart
// lib/core/services/pdf_export_service.dart
// Uses 'pdf' and 'printing' packages

Future<void> exportAnalyticsPdf(AnalyticsModel data) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bharat Karigar — Admin Analytics',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Count'],
            data: [
              ['Total Users', data.totalUsers],
              ['Workers', data.totalWorkers],
              ['Employers', data.totalEmployers],
              ['Subscribed Users', data.subscribedUsers],
              ['Active (last 30 days)', data.activeUsersLast30Days],
              ['Total Posts', data.totalPosts],
              ['Approved Posts', data.approvedPosts],
              ['Pending Posts', data.pendingPosts],
              ['Rejected Posts', data.rejectedPosts],
            ],
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'BharatKarigar_Analytics_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
}
```

### 8G. Analytics Service

```dart
// lib/core/services/analytics_service.dart

class AnalyticsService {

  static final _summaryRef = FirebaseFirestore.instance
      .collection('admin_analytics').doc('summary');

  // Recount everything from scratch (expensive — call only on demand)
  static Future<void> refreshSummary() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    int workers = 0, employers = 0, subscribed = 0;
    for (final doc in users.docs) {
      final role = doc.data()['role'];
      if (role == 'worker') workers++;
      if (role == 'employer') employers++;
      if (doc.data()['isSubscribed'] == true) subscribed++;
    }

    final posts = await FirebaseFirestore.instance.collection('posts').get();
    int pending = 0, approved = 0, rejected = 0;
    for (final doc in posts.docs) {
      final status = doc.data()['status'];
      if (status == 'pending') pending++;
      if (status == 'approved') approved++;
      if (status == 'rejected') rejected++;
    }

    await _summaryRef.set({
      'totalUsers': users.size,
      'totalWorkers': workers,
      'totalEmployers': employers,
      'subscribedUsers': subscribed,
      'totalPosts': posts.size,
      'pendingPosts': pending,
      'approvedPosts': approved,
      'rejectedPosts': rejected,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Lightweight increments (call on each action instead of full refresh)
  static Future<void> incrementApproved() async {
    await _summaryRef.update({
      'approvedPosts': FieldValue.increment(1),
      'pendingPosts': FieldValue.increment(-1),
    });
  }
  static Future<void> incrementRejected() async {
    await _summaryRef.update({
      'rejectedPosts': FieldValue.increment(1),
      'pendingPosts': FieldValue.increment(-1),
    });
  }
}
```

---

## 9. Firebase Security Rules (Full Updated)

Replace existing rules entirely with this complete version:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Helpers ──────────────────────────────────────────────────────
    function isAuth() { return request.auth != null; }
    function isOwner(uid) { return request.auth.uid == uid; }
    function isAdmin() {
      return isAuth() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    function isSubscribed() {
      return isAuth() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSubscribed == true;
    }
    function phoneUnchanged() {
      return !('phone' in request.resource.data.diff(resource.data).affectedKeys());
    }

    // ─── Users ────────────────────────────────────────────────────────
    match /users/{uid} {
      allow read: if isAuth();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid) && phoneUnchanged()
                    || isAdmin();
      allow delete: if isAdmin();
    }

    // ─── Workers ──────────────────────────────────────────────────────
    match /workers/{uid} {
      allow read: if isAuth();
      allow write: if isOwner(uid) && phoneUnchanged()
                   || isAdmin();
    }

    // ─── Employers ────────────────────────────────────────────────────
    match /employers/{uid} {
      allow read: if isAuth();
      allow write: if isOwner(uid) && phoneUnchanged()
                   || isAdmin();
    }

    // ─── Posts ────────────────────────────────────────────────────────
    match /posts/{postId} {
      // Anyone authenticated can read APPROVED posts
      allow read: if isAuth() && (
        resource.data.status == 'approved'
        || resource.data.userId == request.auth.uid   // own posts (any status)
        || isAdmin()
      );
      allow create: if isAuth()
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.status == 'pending';  // must be pending on create
      allow update: if
        // Owner can edit own PENDING posts (description, title, images only)
        (isOwner(resource.data.userId)
          && resource.data.status == 'pending'
          && !('status' in request.resource.data.diff(resource.data).affectedKeys()))
        // Admin can change status (approve/reject)
        || isAdmin();
      allow delete: if isOwner(resource.data.userId) || isAdmin();
    }

    // ─── Jobs ─────────────────────────────────────────────────────────
    match /jobs/{jobId} {
      allow read: if isAuth();
      allow create: if isAuth();
      allow update, delete: if isOwner(resource.data.employerUid) || isAdmin();
    }

    // ─── Applications ─────────────────────────────────────────────────
    match /applications/{appId} {
      allow read: if isAuth() && (
        resource.data.workerUid == request.auth.uid
        || resource.data.employerUid == request.auth.uid
        || isAdmin()
      );
      allow create: if isAuth() && request.resource.data.workerUid == request.auth.uid;
      allow update: if isAuth() && resource.data.employerUid == request.auth.uid || isAdmin();
    }

    // ─── Connections ──────────────────────────────────────────────────
    match /connections/{connId} {
      allow read: if isAuth() && (
        resource.data.initiatorUid == request.auth.uid
        || resource.data.targetUid == request.auth.uid
      );
      allow create: if isAuth()
                    && request.resource.data.initiatorUid == request.auth.uid
                    && isSubscribed();    // must be subscribed to connect
    }

    // ─── Subscriptions ────────────────────────────────────────────────
    match /subscriptions/{subId} {
      allow read: if isAuth() && resource.data.userId == request.auth.uid || isAdmin();
      allow create: if isAuth() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin();    // only admin/Cloud Function updates status
    }

    // ─── Admin Analytics ─────────────────────────────────────────────
    match /admin_analytics/{docId} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
  }
}
```

---

## 10. Providers & Services

### 10A. `post_provider.dart`

```dart
// lib/providers/post_provider.dart

// Global approved feed
final feedProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data())).toList());
});

// My posts (all statuses)
final myPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data())).toList());
});

// Admin: pending posts
final pendingPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: false)   // oldest first for admin
      .snapshots()
      .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data())).toList());
});
```

### 10B. `subscription_provider.dart`

```dart
// lib/providers/subscription_provider.dart

final subscriptionStatusProvider = FutureProvider<bool>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  return SubscriptionService.isSubscriptionActive(uid);
});

// Invalidate after payment success:
// ref.invalidate(subscriptionStatusProvider);
```

### 10C. `post_model.dart`

```dart
// lib/models/post_model.dart

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

  factory PostModel.fromMap(Map<String, dynamic> data) => PostModel(
    postId: data['postId'] ?? '',
    userId: data['userId'] ?? '',
    userRole: data['userRole'] ?? '',
    userName: data['userName'] ?? '',
    userPhotoUrl: data['userPhotoUrl'],
    isUserVerified: data['isUserVerified'] ?? false,
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    imageUrls: List<String>.from(data['imageUrls'] ?? []),
    status: data['status'] ?? 'pending',
    rejectionReason: data['rejectionReason'],
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    likeCount: data['likeCount'] ?? 0,
  );
}
```

---

## 11. UI Specifications

### 11A. Feed Screen color palette & style

```dart
// Feed card styling guidelines
const feedCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
);

// Status badge colors on "My Posts" tab
// Pending:  background Color(0xFFFFF8E1), text Color(0xFFE65100), icon: clock
// Approved: background Color(0xFFE8F5E9), text Color(0xFF1B5E20), icon: check
// Rejected: background Color(0xFFFFEBEE), text Color(0xFFB71C1C), icon: close
```

### 11B. Admin panel color theme

```dart
// Admin screens use a slightly different color theme to distinguish from user app
const adminPrimary   = Color(0xFF1A237E);   // deep indigo (vs user blue 0xFF1A56DB)
const adminAccent    = Color(0xFF283593);
const adminBg        = Color(0xFFF5F6FA);
```

### 11C. GoRouter additions

```dart
// Add to existing GoRouter in lib/core/constants/app_routes.dart

// Feed
GoRoute(path: '/feed', pageBuilder: (_, __) => slideUpPage(FeedScreen())),
GoRoute(path: '/feed/create', pageBuilder: (_, __) => slideUpPage(CreatePostScreen())),
GoRoute(path: '/feed/post/:postId', pageBuilder: (_, state) =>
    slideRightPage(PostDetailScreen(postId: state.pathParameters['postId']!))),

// Subscription
GoRoute(path: '/subscription/plans', pageBuilder: (_, __) => slideUpPage(SubscriptionPlansScreen())),
GoRoute(path: '/subscription/checkout', pageBuilder: (_, state) =>
    slideUpPage(SubscriptionCheckoutScreen(plan: state.extra as SubscriptionPlan))),
GoRoute(path: '/subscription/success', pageBuilder: (_, __) => scaleUpPage(SubscriptionSuccessScreen())),

// Admin (separate shell — no bottom nav)
GoRoute(path: '/admin/login', pageBuilder: (_, __) => slideUpPage(AdminLoginScreen())),
GoRoute(path: '/admin/dashboard', pageBuilder: (_, __) => slideUpPage(AdminDashboardScreen())),
GoRoute(path: '/admin/posts', pageBuilder: (_, __) => slideRightPage(AdminPostsScreen())),
GoRoute(path: '/admin/users', pageBuilder: (_, __) => slideRightPage(AdminUsersScreen())),

// Banned
GoRoute(path: '/banned', pageBuilder: (_, __) => scaleUpPage(BannedScreen())),
```

---

## 12. pubspec.yaml Additions

```yaml
# Add to existing dependencies:
dependencies:
  # Images & Cropping
  image_cropper: ^7.1.0             # Circular crop on profile photo
  image_picker: ^1.1.2              # Already listed — verify version

  # PDF export
  pdf: ^3.11.0
  printing: ^5.13.0

  # Subscription / Payment
  razorpay_flutter: ^1.3.7

  # Animations
  lottie: ^3.1.0                    # Already in v2 — verify
  flutter_animate: ^4.5.0           # Already in v2 — verify

  # Admin analytics charts
  fl_chart: ^0.68.0

  # Date formatting
  intl: ^0.19.0                     # Already listed — verify
```

---

## 13. Build Order Phase 11–15

```
Phase 11 — Profile Image Upload
  [ ] 45. storage_service.dart → add uploadProfilePhoto + uploadPostImage
  [ ] 46. profile_image_picker.dart widget (camera/gallery + crop + upload)
  [ ] 47. Update worker_edit_profile_screen.dart to include ProfileImagePicker
  [ ] 48. Update employer_edit_profile_screen.dart to include ProfileImagePicker

Phase 12 — Post Creation & Feed
  [ ] 49. post_model.dart
  [ ] 50. post_service.dart (create, fetch, delete)
  [ ] 51. post_provider.dart (feedProvider, myPostsProvider, pendingPostsProvider)
  [ ] 52. post_image_grid.dart widget
  [ ] 53. post_card.dart widget
  [ ] 54. post_pending_banner.dart (overlay notification)
  [ ] 55. create_post_screen.dart (text + image upload + submit)
  [ ] 56. feed_screen.dart (global approved feed + create bar + pagination)
  [ ] 57. post_detail_screen.dart
  [ ] 58. Add "My Posts" tab to worker_profile_screen.dart
  [ ] 59. Add "My Posts" tab to employer_profile_screen.dart
  [ ] 60. Wire "/feed" and "/feed/create" in GoRouter

Phase 13 — Subscription System
  [ ] 61. subscription_model.dart
  [ ] 62. subscription_service.dart (isActive, activate, deactivate)
  [ ] 63. subscription_provider.dart
  [ ] 64. subscription_gate_widget.dart
  [ ] 65. subscribe_prompt_card.dart
  [ ] 66. subscription_plans_screen.dart (3 plan cards)
  [ ] 67. subscription_checkout_screen.dart (Razorpay stub)
  [ ] 68. subscription_success_screen.dart (scaleUpPage transition)
  [ ] 69. Update contact reveal sections (worker_detail, employer_detail) to use SubscriptionGate
  [ ] 70. checkAndDeactivateIfExpired() call in auth_gate.dart on login

Phase 14 — Admin Panel
  [ ] 71. analytics_model.dart
  [ ] 72. analytics_service.dart (refreshSummary, increments)
  [ ] 73. admin_service.dart (approvePost, rejectPost, banUser, unbanUser)
  [ ] 74. pdf_export_service.dart
  [ ] 75. admin_login_screen.dart (email+pass, isAdmin check)
  [ ] 76. analytics_stat_card.dart widget
  [ ] 77. pending_post_card.dart widget
  [ ] 78. user_row_tile.dart widget
  [ ] 79. admin_dashboard_screen.dart (stats grid + quick actions)
  [ ] 80. admin_posts_screen.dart (3 tabs: Pending/Approved/Rejected)
  [ ] 81. admin_users_screen.dart (filter + ban/unban)
  [ ] 82. admin_analytics_screen.dart (fl_chart bar/pie + PDF export button)
  [ ] 83. banned_screen.dart (shown when isBanned == true)
  [ ] 84. Wire all admin routes in GoRouter

Phase 15 — Security & Polish
  [ ] 85. Deploy updated Firestore security rules (Section 9)
  [ ] 86. Ban enforcement in auth_gate.dart
  [ ] 87. admin_analytics/summary doc initialization (seed zeros)
  [ ] 88. Test full post flow: create → pending → approve → visible in feed
  [ ] 89. Test subscription gate: subscribe → contact visible → expire → hidden
  [ ] 90. Android gradle + manifest updates for Razorpay
```

---

## 14. Critical Rules for Agent

| Rule | Where to implement | Detail |
|------|-------------------|--------|
| Posts default to `status: "pending"` | `post_service.dart` create method | NEVER allow user to set status on create |
| Only admin can change post status | Firestore security rules + admin_service.dart | Client-side rule + server rule |
| Phone number immutable | Firestore rules `phoneUnchanged()` helper | Applied to users, workers, employers collections |
| Connection requires subscription | Firestore rules `isSubscribed()` on connections create | Also enforce in UI with SubscriptionGate |
| Ban check on every login | `auth_gate.dart` | After auth state change, before routing |
| Profile photo stored at `users/{uid}/profile.jpg` | `storage_service.dart` | Overwrite on update — no versioning needed |
| Post images at `posts/{postId}/image_N.jpg` | `storage_service.dart` | N = 0 to 3 |
| Feed only shows `approved` posts | `feedProvider` query | Not enforced by rules — rule allows owner to see own posts |
| Admin login is email+password | `admin_login_screen.dart` | Not phone OTP |
| `isAdmin` flag checked server-side in rules | Firestore rules `isAdmin()` helper | Not just Flutter-side |
| Subscription activates via `SubscriptionService.activateSubscription()` | Called only from payment success callback | Never from UI button directly |
| Analytics PDF uses `printing` package for share sheet | `pdf_export_service.dart` | Works on Android without file permission |

---

*Generated for KI-Job Portal · Flutter Android · Firebase · Feature Update v3 · 2026*
