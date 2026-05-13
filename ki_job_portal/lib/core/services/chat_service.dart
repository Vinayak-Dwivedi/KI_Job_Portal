import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if chat is unlocked
  static Stream<bool> isChatUnlocked(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return false;
      return doc.data()?['isUnlocked'] ?? false;
    });
  }

  // Unlock chat for 100 credits
  static Future<bool> unlockChat(String currentUid, String chatId) async {
    if (currentUid.isEmpty) {
      debugPrint("❌ Unlock failed: No UID provided");
      return false;
    }

    final userRef = _db.collection('users').doc(currentUid);
    final chatRef = _db.collection('chats').doc(chatId);

    try {
      debugPrint("🔓 Attempting to unlock chat: $chatId using 'users' credits");
      return await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          debugPrint("❌ User doc not found for $currentUid");
          return false;
        }

        final data = userSnap.data()!;
        final balance = int.tryParse((data['credits'] ?? data['balance'] ?? '0').toString()) ?? 0;
        
        debugPrint("💳 Current balance in 'users': $balance");
        if (balance < 10) {
          debugPrint("❌ Unlock failed: Insufficient balance (need 10, have $balance)");
          return false;
        }

        // Deduct balance from users collection and unlock chat
        transaction.update(userRef, {'credits': FieldValue.increment(-10)});
        transaction.update(chatRef, {
          'isUnlocked': true,
          'unlockedAt': FieldValue.serverTimestamp(),
          'unlockedBy': currentUid,
        });

        // 📝 Record Transaction in user's subcollection for history
        final txRef = userRef.collection('transactions').doc();
        transaction.set(txRef, {
          'amount': 10,
          'type': 'debit',
          'label': 'Unlock Messaging',
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint("✅ Chat unlocked successfully using 'users' credits");
        return true;
      });
    } catch (e) {
      debugPrint("❌ Error unlocking chat: $e");
      return false;
    }
  }

  // Get or Create a chat room between two users
  static Future<String> getOrCreateChat(String currentUid, String otherUid, Map<String, dynamic> otherUserData) async {
    if (currentUid.isEmpty || otherUid.isEmpty) {
      debugPrint("❌ [CHAT] Cannot create chat: UID is empty. current: $currentUid, other: $otherUid");
      return '';
    }

    final chatId = _getChatId(currentUid, otherUid);
    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (chatDoc.exists) {
      debugPrint("✅ [CHAT] Found existing chat: $chatId");
      return chatId;
    }

    debugPrint("🆕 [CHAT] Creating new chat document: $chatId");

    // Check if the current user or target user is an admin
    final userSnap = await _db.collection('users').doc(currentUid).get();
    final bool isCurrentAdmin = userSnap.data()?['role'] == 'admin';
    
    final otherUserSnap = await _db.collection('users').doc(otherUid).get();
    final bool isOtherAdmin = otherUserSnap.data()?['role'] == 'admin';
    
    final bool shouldBeUnlocked = isCurrentAdmin || isOtherAdmin;

    await chatRef.set({
      'id': chatId,
      'members': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isUnlocked': shouldBeUnlocked,
      'memberData': {
        currentUid: {
          'name': userSnap.data()?['name'] ?? 'You',
          'photoUrl': userSnap.data()?['profilePhotoUrl'] ?? '',
        },
        otherUid: {
          'name': otherUserData['name'] ?? otherUserSnap.data()?['name'] ?? 'User',
          'photoUrl': otherUserData['profilePhotoUrl'] ?? otherUserSnap.data()?['profilePhotoUrl'] ?? '',
        }
      }
    });

    return chatId;
  }

  static String _getChatId(String uid1, String uid2) {
    final List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // Send message
  static Future<bool> sendMessage(String currentUid, String chatId, String text) async {
    try {
      if (currentUid.isEmpty) {
        debugPrint("❌ [SEND] No current user UID provided");
        return false;
      }

      debugPrint("📩 [SEND] Sending message to chat: $chatId");
      debugPrint("📩 [SEND] Sender UID: $currentUid");

      final messageData = {
        'senderId': currentUid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      };

      // 1. Add to messages subcollection
      try {
        debugPrint("📦 [SEND] Adding message document...");
        await _db.collection('chats').doc(chatId).collection('messages').add(messageData);
        debugPrint("✅ [SEND] Message added successfully");
      } catch (e) {
        debugPrint("❌ [SEND] Failed to add message: $e");
        rethrow;
      }

      // 2. Update chat head (metadata)
      try {
        debugPrint("🔝 [SEND] Updating chat head metadata...");
        await _db.collection('chats').doc(chatId).update({
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ [SEND] Chat head updated");
      } catch (e) {
        debugPrint("⚠️ [SEND] Non-critical failure updating chat head: $e");
        // We don't return false here because the message was already added
      }

      // 🚀 Trigger Notification
      _triggerNotification(chatId, currentUid, text);
      
      return true;
    } catch (e) {
      debugPrint("❌ [SEND] CRITICAL MESSAGE FAILURE: $e");
      return false;
    }
  }

  static Future<void> _triggerNotification(String chatId, String currentUid, String text) async {
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;
      
      final List members = chatDoc.data()?['members'] ?? [];
      final otherUid = members.firstWhere((m) => m != currentUid, orElse: () => null);
      
      if (otherUid != null) {
        final senderName = chatDoc.data()?['memberData']?[currentUid]?['name'] ?? 'Someone';
        
        await _db.collection('users').doc(otherUid).collection('notifications').add({
          'title': 'New message from $senderName',
          'body': text.length > 50 ? '${text.substring(0, 50)}...' : text,
          'type': 'chat',
          'chatId': chatId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  // Stream messages
  static Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    debugPrint("📂 Fetching messages for chat: $chatId");
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
          
          // Sort in memory (Newest first for ListView.builder reverse: true)
          messages.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1; // Pending messages at top (reverse:true)
            if (bTime == null) return 1;
            return bTime.compareTo(aTime);
          });
          
          return messages;
        });
  }

  // Stream chats
  static Stream<List<Map<String, dynamic>>> getMyChats(String currentUid) {
    debugPrint("📥 [CHATS] Fetching chats for user: $currentUid");
    return _db
        .collection('chats')
        .where('members', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
          debugPrint("📥 [CHATS] Query result: Found ${chats.length} chats for UID: $currentUid");
          
          // Sort in memory to avoid index requirements
          chats.sort((a, b) {
            final aTime = a['lastMessageTime'] as Timestamp?;
            final bTime = b['lastMessageTime'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          return chats;
        });
  }
}
