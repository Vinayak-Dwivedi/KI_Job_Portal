import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final currentUid = auth?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: currentUid == null 
        ? const Center(child: Text('Please log in to see messages'))
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: ChatService.getMyChats(currentUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('UID: $currentUid', style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 10)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final members = chat['members'] as List? ?? [];
              final otherUid = members.firstWhere((id) => id != currentUid, orElse: () => '');
              final memberData = chat['memberData'] as Map? ?? {};
              final otherData = memberData[otherUid] as Map? ?? {};
              
              final name = otherData['name'] ?? 'User';
              final photo = otherData['photoUrl'] ?? '';
              final lastMsg = chat['lastMessage'] ?? '';
              final lastTime = chat['lastMessageTime'];

              return ListTile(
                onTap: () {
                  context.push('/chat/${chat['id']}', extra: {
                    'name': name,
                    'photo': photo,
                  });
                },
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: lastTime != null 
                    ? Text(timeago.format(lastTime.toDate(), locale: 'en_short'), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))
                    : null,
                tileColor: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            },
          );
        },
      ),
    );
  }
}
