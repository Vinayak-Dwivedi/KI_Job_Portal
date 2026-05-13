import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/services/post_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  void _sendComment() async {
    final auth = ref.read(authProvider);
    if (auth == null || _commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    String name = "User";
    String? photoUrl;
    String role = "worker";

    // Try to get more detailed user info from providers
    final worker = ref.read(workerProvider);
    final employer = ref.read(employerProvider);

    bool isVerified = false;
    if (worker != null && worker.uid == auth.uid) {
      name = worker.name;
      photoUrl = worker.profilePhotoUrl;
      role = "worker";
      isVerified = worker.isVerified;
    } else if (employer != null && employer.uid == auth.uid) {
      name = employer.name;
      photoUrl = employer.profilePhotoUrl;
      role = "employer";
      isVerified = employer.isVerified;
    }

    await PostService.addComment(widget.postId, {
      'uid': auth.uid,
      'name': name,
      'role': role,
      'profilePhotoUrl': photoUrl,
      'text': _commentController.text.trim(),
      'isVerified': isVerified,
    });

    _commentController.clear();
    if (mounted) setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Comments",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Comments List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PostService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "No comments yet",
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final String name = comment['name'] ?? 'User';
                    final String text = comment['text'] ?? '';
                    final String? photoUrl = comment['profilePhotoUrl'];
                    final dynamic createdAt = comment['createdAt'];

                    String timeStr = 'Just now';
                    if (createdAt is Timestamp) {
                      timeStr = timeago.format(createdAt.toDate());
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final uid = comment['uid'];
                            final role = comment['role'] ?? 'worker';
                            if (uid != null) {
                              Navigator.pop(context); // Close sheet
                              context.push('/profile/$role/$uid');
                            }
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                            child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, size: 18, color: theme.colorScheme.onSurfaceVariant) : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final uid = comment['uid'];
                                  final role = comment['role'] ?? 'worker';
                                    if (uid != null) {
                                      Navigator.pop(context); // Close sheet
                                      context.push('/profile/$role/$uid');
                                    }
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (comment['isVerified'] == true) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.verified_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 14,
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Text(
                                      timeStr,
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input Field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding + 12,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
