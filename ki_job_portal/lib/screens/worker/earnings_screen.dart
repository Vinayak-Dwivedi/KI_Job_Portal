import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

// Provider that streams credit transaction history
final _creditTransactionsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('contactCredits')
      .doc(auth.uid)
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'type': data['type'] ?? 'debit',
              'amount': data['amount'] ?? 0,
              'description': data['description'] ?? '',
              'createdAt': data['createdAt'],
            };
          }).toList());
});

// Provider that watches the credit balance
final _creditBalanceProvider =
    StreamProvider.autoDispose<int>((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('contactCredits')
      .doc(auth.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return 0;
        return int.tryParse(doc.data()!['balance']?.toString() ?? '0') ?? 0;
      });
});

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(_creditBalanceProvider);
    final txAsync = ref.watch(_creditTransactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Credits & Earnings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance Hero Card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AVAILABLE BALANCE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  balanceAsync.when(
                    data: (balance) => Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$balance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 8),
                          child: Text(
                            'Credits',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                    error: (_, __) =>
                        const Text('--', style: TextStyle(color: Colors.white, fontSize: 48)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatChip(Icons.bolt_rounded, 'Unlock Contact = 10 cr'),
                      const SizedBox(width: 10),
                      _buildStatChip(Icons.star_rounded, 'Boost Job = 50 cr'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 32),

            // ── Transaction History ───────────────────────────────
            Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            txAsync.when(
              data: (txs) {
                if (txs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your credit purchases and unlocks will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: theme.dividerColor, height: 1),
                  itemBuilder: (context, index) {
                    return _TransactionTile(tx: txs[index])
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.05, end: 0);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCredit = tx['type'] == 'credit';
    final int amount = tx['amount'] as int? ?? 0;
    final String desc = tx['description']?.toString() ?? 'Transaction';
    final createdAt = tx['createdAt'];

    String dateStr = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateStr =
          '${d.day} ${_monthName(d.month)} ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: isCredit ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}$amount',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
