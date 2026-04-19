import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final faqs = [
      {
        'q': 'How do I earn more recruitment credits?',
        'a': 'You can earn credits by subscribing to a premium plan or participating in promotional activities. Each plan (Pro/Elite) offers a dedicated credit pool.'
      },
      {
        'q': 'How do I change my profile role?',
        'a': 'Role changes are locked after verification for security reasons. Please contact support if you need to switch between Worker and Employer roles.'
      },
      {
        'q': 'Is my data secure?',
        'a': 'We use industry-standard encryption and Firestore security rules to ensure your personal data and documents are protected.'
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Contact Methods', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(Icons.mail_rounded, 'Email Support', 'support@kijob.com', theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(Icons.chat_rounded, 'Live Chat', 'Average wait: 5m', theme),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Frequently Asked Questions', theme),
            const SizedBox(height: 16),
            ...faqs.map((faq) => _buildFaqTile(faq['q']!, faq['a']!, theme)),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 1.0.0 (Build 20260408)',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, 
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: [
          Text(answer, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
