import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUid = ref.read(authProvider)?.uid ?? '';
    final success = await ChatService.sendMessage(currentUid, widget.chatId, text);
    if (success) {
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send message. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final currentUid = auth?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty)
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: (widget.otherUserPhoto == null || widget.otherUserPhoto!.isEmpty)
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: ChatService.isChatUnlocked(widget.chatId),
        builder: (context, unlockSnap) {
          final isUnlocked = unlockSnap.data ?? false;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg['senderId'] == currentUid;
                        final timestamp = msg['timestamp'] as Timestamp?;
                        
                        // Determine sender label
                        String? senderLabel;
                        if (!isMe) {
                          final senderId = msg['senderId'] as String? ?? '';
                          if (senderId.toLowerCase().contains('admin')) {
                            senderLabel = "Admin";
                          }
                        }

                        return _MessageBubble(
                          text: msg['text'] ?? '',
                          isMe: isMe,
                          senderLabel: senderLabel,
                          time: timestamp != null ? timeago.format(timestamp.toDate(), locale: 'en_short') : '',
                          theme: theme,
                        );
                      },
                    );
                  },
                ),
              ),
              if (isUnlocked)
                _buildInputArea(theme)
              else
                _buildUnlockPaywall(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnlockPaywall(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            "Conversation Locked",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            "Unlock this conversation to start chatting with ${widget.otherUserName}. This helps us maintain a secure community.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.toll_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Unlock for 10 Credits",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnlock() async {
    final theme = Theme.of(context);
    
    // 1. Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Unlock Conversation", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to unlock this chat with ${widget.otherUserName} for 10 credits?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Unlock Now"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Process Unlock
    final currentUid = ref.read(authProvider)?.uid ?? '';
    
    setState(() => _isProcessing = true);
    try {
      final success = await ChatService.unlockChat(currentUid, widget.chatId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Conversation unlocked! You can now send messages. 🔓"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Insufficient credits or error unlocking chat."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? senderLabel;
  final String time;
  final ThemeData theme;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    this.senderLabel,
    required this.time,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 20 : 0),
            topRight: Radius.circular(isMe ? 0 : 20),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderLabel != null) ...[
              Text(
                senderLabel!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.7) : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
