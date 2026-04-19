import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _jobAlerts = true;
  bool _postInteractions = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
            _buildSectionHeader('General Alerts', theme),
            const SizedBox(height: 12),
            _buildCard([
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Get instant alerts on your device',
                value: _pushEnabled,
                onChanged: (val) => setState(() => _pushEnabled = val),
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email Notifications',
                subtitle: 'Periodic updates via email',
                value: _emailEnabled,
                onChanged: (val) => setState(() => _emailEnabled = val),
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.sms_outlined,
                title: 'SMS Alerts',
                subtitle: 'Critical updates via text message',
                value: _smsEnabled,
                onChanged: (val) => setState(() => _smsEnabled = val),
                theme: theme,
              ),
            ], theme),
            const SizedBox(height: 24),
            _buildSectionHeader('Channel Preferences', theme),
            const SizedBox(height: 12),
            _buildCard([
              _buildSwitchTile(
                icon: Icons.work_outline_rounded,
                title: 'Job Recommendations',
                subtitle: 'New jobs matching your profile',
                value: _jobAlerts,
                onChanged: (val) => setState(() => _jobAlerts = val),
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Post Interactions',
                subtitle: 'Likes and comments on your posts',
                value: _postInteractions,
                onChanged: (val) => setState(() => _postInteractions = val),
                theme: theme,
              ),
            ], theme),
            const SizedBox(height: 32),
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

  Widget _buildCard(List<Widget> children, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
