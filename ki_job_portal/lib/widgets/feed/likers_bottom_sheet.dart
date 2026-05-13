import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/public_user_provider.dart';

class LikersBottomSheet extends ConsumerWidget {
  final String postId;

  const LikersBottomSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Who liked this',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withOpacity(0.1)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('likes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No likes yet'),
                  );
                }

                final likes = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: likes.length,
                  itemBuilder: (context, index) {
                    final uid = likes[index].id;
                    return _LikerTile(uid: uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LikerTile extends ConsumerWidget {
  final String uid;

  const _LikerTile({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(publicProfileProvider(uid));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          // Fallback tile for null user data
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('Unknown User', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
            subtitle: Text('ID: ${uid.substring(0, min(8, uid.length))}', style: TextStyle(fontSize: 10)),
          );
        }

        final name = user['name'] ?? 'Unknown User';
        final photoUrl = user['profilePhotoUrl'] ?? user['photoUrl'];
        final role = user['role'] ?? 'worker';

        return ListTile(
          onTap: () {
            Navigator.pop(context);
            context.push('/profile/$role/$uid');
          },
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceVariant,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
          ),
          title: Text(
            name,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            role.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        );
      },
      loading: () => const ListTile(title: Text('Loading...')),
      error: (_, __) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.error_outline)),
        title: const Text('Error loading user'),
        subtitle: Text('ID: ${uid.substring(0, min(8, uid.length))}', style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}
