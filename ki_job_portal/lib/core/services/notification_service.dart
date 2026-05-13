import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Initialize notifications
  static Future<void> initialize() async {
    try {
      // 1. Request Permission (Standard check)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [FCM] User granted permission');
        
        // 2. Get and Save Token
        await updateToken();
      } else {
        debugPrint('⚠️ [FCM] User declined or has not accepted permission');
      }

      // 3. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM] Foreground Message: ${message.notification?.title}');
        // You could show a local notification here if needed
      });
      
      // 5. Listen to Background Message Taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // 6. Check for Initial Message (App launched from killed state)
      _messaging.getInitialMessage().then((message) {
        if (message != null) _handleMessage(message);
      });

      // 7. Listen to Token Refresh
      _messaging.onTokenRefresh.listen((newToken) {
        saveTokenToFirestore(newToken);
      });

    } catch (e) {
      debugPrint('❌ [FCM] Initialization Error: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    debugPrint('📩 [FCM] Message Opened: ${message.data}');
    final postId = message.data['postId'] ?? message.data['communityPostId'];
    if (postId != null) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Navigate to /feed with the postId as a query parameter
        context.push('/feed?postId=$postId');
      }
    }
  }

  // Get current FCM token and save it
  static Future<void> updateToken({String? uid}) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔑 [FCM] Token: $token');
        await saveTokenToFirestore(token, uid: uid);
      }
    } catch (e) {
      debugPrint('❌ [FCM] Error getting token: $e');
    }
  }

  // Save token to user document
  static Future<void> saveTokenToFirestore(String token, {String? uid}) async {
    final effectiveUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) {
      debugPrint('⚠️ [FCM] Skip saving token: No UID found');
      return;
    }

    try {
      await _db.collection('users').doc(effectiveUid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('💾 [FCM] Token saved to Firestore for user: $effectiveUid');
    } catch (e) {
      debugPrint('❌ [FCM] Error saving token to Firestore: $e');
    }
  }

  // Request system level permission (Android 13+)
  static Future<bool> requestSystemPermission() async {
    if (await Permission.notification.isGranted) return true;
    
    final status = await Permission.notification.request();
    if (status.isGranted) {
      await updateToken();
      return true;
    }
    return false;
  }
}
