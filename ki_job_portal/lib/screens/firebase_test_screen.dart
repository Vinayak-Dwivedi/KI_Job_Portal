import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatelessWidget {
  const FirebaseTestScreen({super.key});

  // 🔥 WRITE TEST
  Future<void> addTestUser() async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': 'Test User',
        'role': 'worker',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ Data written successfully");
    } catch (e) {
      print("❌ Write error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Test")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 🔥 WRITE BUTTON
          ElevatedButton(
            onPressed: addTestUser,
            child: const Text("Add Test User"),
          ),

          const Divider(),

          // 🔥 READ TEST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("❌ Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No data found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];

                    return ListTile(
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text(data['role'] ?? 'No Role'),
                    );
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
