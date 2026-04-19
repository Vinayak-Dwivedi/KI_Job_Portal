import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/post_service.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (auth == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blocked Users')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(auth.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final blockedUids = List<String>.from(data['blockedUsers'] ?? []);

          if (blockedUids.isEmpty) {
            return const Center(child: Text('No blocked users.'));
          }

          return ListView.builder(
            itemCount: blockedUids.length,
            itemBuilder: (context, index) {
              final String uid = blockedUids[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const ListTile(title: Text('Loading...'));
                  final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name = userData['name'] ?? userData['fullName'] ?? 'Unknown User';
                  
                  return ListTile(
                    leading: CircleAvatar(child: Text(name[0])),
                    title: Text(name),
                    trailing: TextButton(
                      onPressed: () {
                        PostService.unblockUser(auth.uid, uid);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name unblocked.')));
                      },
                      child: const Text('Unblock', style: TextStyle(color: Colors.blue)),
                    ),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}
