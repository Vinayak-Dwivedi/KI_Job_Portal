import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _jobAlerts = true;
  bool _postInteractions = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ [NOTIFS] No user found during load");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pushEnabled = data['pushEnabled'] ?? true;
          _emailEnabled = data['emailEnabled'] ?? true;
          _smsEnabled = data['smsEnabled'] ?? false;
          _jobAlerts = data['jobAlerts'] ?? true;
          _postInteractions = data['postInteractions'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    // 1. Request system level permission (Android 13+)
    PermissionStatus status = await Permission.notification.request();
    
    if (status.isGranted) {
      // 2. Request FCM permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint("✅ [NOTIFS] Permissions granted");
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications are blocked. Please enable them in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set({
        key: value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $key: $e')),
        );
      }
    }
  }

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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                onChanged: (val) async {
                  if (val) {
                    await _requestNotificationPermission();
                  }
                  setState(() => _pushEnabled = val);
                  _updateSetting('pushEnabled', val);
                },
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email Notifications',
                subtitle: 'Periodic updates via email',
                value: _emailEnabled,
                onChanged: (val) {
                  setState(() => _emailEnabled = val);
                  _updateSetting('emailEnabled', val);
                },
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.sms_outlined,
                title: 'SMS Alerts',
                subtitle: 'Critical updates via text message',
                value: _smsEnabled,
                onChanged: (val) {
                  setState(() => _smsEnabled = val);
                  _updateSetting('smsEnabled', val);
                },
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
                onChanged: (val) {
                  setState(() => _jobAlerts = val);
                  _updateSetting('jobAlerts', val);
                },
                theme: theme,
              ),
              _buildSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Post Interactions',
                subtitle: 'Likes and comments on your posts',
                value: _postInteractions,
                onChanged: (val) {
                  setState(() => _postInteractions = val);
                  _updateSetting('postInteractions', val);
                },
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
