import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/post_provider.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/feed/post_card.dart';

class AdminPostsScreen extends ConsumerWidget {
  const AdminPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Pending Posts', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: pendingAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('All caught up! No pending posts.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    IgnorePointer( // Disable interactions inside the post card
                      child: PostCard(post: post),
                    ),
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              AdminService.updatePostStatus(post['id'], 'rejected');
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              AdminService.updatePostStatus(post['id'], 'approved');
                            },
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text('Approve', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
