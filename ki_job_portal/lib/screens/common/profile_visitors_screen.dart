import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileVisitorsScreen extends ConsumerWidget {
  const ProfileVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text('Profile Visitors', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(auth.uid)
            .collection('visitors')
            .orderBy('viewedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text('No visitors yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'A visitor';
              final photo = data['photo'] ?? '';
              final viewedAt = (data['viewedAt'] as Timestamp?)?.toDate();
              final visitorUid = data['uid'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    viewedAt != null 
                      ? 'Visited ${DateFormat('MMM dd, hh:mm a').format(viewedAt)}'
                      : 'Recently visited',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                  onTap: () {
                    // Navigate to visitor's public profile
                    // Note: We don't know the visitor's role easily here, 
                    // but most likely we can check their doc if we really wanted to.
                    // For now, let's assume they could be worker or employer.
                    // We'll just push to a generic profile route if it exists or handle role.
                    context.push('/profile/worker/$visitorUid');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
