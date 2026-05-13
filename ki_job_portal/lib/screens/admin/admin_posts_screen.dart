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
              final isEdit = post['hasPendingEdit'] == true;
              
              // Prepare display post
              Map<String, dynamic> displayPost = Map<String, dynamic>.from(post);
              if (isEdit && post['pendingEdit'] != null) {
                final pendingEditData = Map<String, dynamic>.from(post['pendingEdit']);
                displayPost.addAll(pendingEditData);
                displayPost['status'] = 'pending_edit'; // Visual cue for admin
              }

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    if (isEdit)
                      Container(
                        width: double.infinity,
                        color: Colors.blue.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Text('EDIT PENDING APPROVAL', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    IgnorePointer( // Disable interactions inside the post card
                      child: PostCard(post: displayPost),
                    ),
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (isEdit) {
                                AdminService.rejectEdit(post['id']);
                              } else {
                                AdminService.updatePostStatus(post['id'], 'rejected');
                              }
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isEdit) {
                                AdminService.approveEdit(post['id']);
                              } else {
                                AdminService.updatePostStatus(post['id'], 'approved');
                              }
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
