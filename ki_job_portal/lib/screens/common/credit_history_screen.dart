import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class CreditHistoryScreen extends ConsumerWidget {
  const CreditHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Credit Transactions', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contactCredits')
            .doc(user.uid)
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No transaction history found', 
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final tx = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final title = tx['title'] ?? 'Transaction';
              final desc = tx['description'] ?? '';
              final amount = tx['amount'] ?? 0;
              final createdAt = tx['createdAt'] as Timestamp?;
              final isDebit = amount < 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDebit ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebit ? Icons.remove_rounded : Icons.add_rounded,
                      color: isDebit ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        createdAt != null ? timeago.format(createdAt.toDate()) : 'Recently',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${isDebit ? "" : "+"}$amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDebit ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
