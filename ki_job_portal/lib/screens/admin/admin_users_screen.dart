import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/admin_service.dart';

final usersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map(
    (snap) => snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList(),
  );
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isBanned = user['isBanned'] ?? false;
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBanned ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    child: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? Colors.red : Colors.blue),
                  ),
                  title: Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['role']} • ${user['phone']}'),
                  trailing: TextButton(
                    onPressed: () {
                      if (isBanned) {
                        AdminService.unbanUser(user['uid']);
                      } else {
                        AdminService.banUser(user['uid']);
                      }
                    },
                    child: Text(isBanned ? 'Unban' : 'Ban', style: TextStyle(color: isBanned ? Colors.green : Colors.red)),
                  ),
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
