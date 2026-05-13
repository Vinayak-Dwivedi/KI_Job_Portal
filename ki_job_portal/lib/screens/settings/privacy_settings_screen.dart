import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/privacy_api_service.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _publicProfile = true;
  bool _showPhone = false;
  bool _showEmail = true;
  bool _showLocation = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    try {
      final settings = await PrivacyApiService.getPrivacySettings(user.uid);
      if (mounted) {
        setState(() {
          _publicProfile = settings['publicProfile'] ?? true;
          _showLocation = settings['showLocation'] ?? true;
          _showPhone = settings['showPhoneNumber'] ?? false;
          _showEmail = settings['showEmail'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSetting(String field, bool newValue) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    // Optimistic UI Update
    setState(() {
      if (field == 'publicProfile') _publicProfile = newValue;
      if (field == 'showLocation') _showLocation = newValue;
      if (field == 'showPhoneNumber') _showPhone = newValue;
      if (field == 'showEmail') _showEmail = newValue;
    });

    try {
      await PrivacyApiService.updatePrivacySettings(
        userId: user.uid,
        publicProfile: _publicProfile,
        showLocation: _showLocation,
        showPhoneNumber: _showPhone,
        showEmail: _showEmail,
      );
    } catch (e) {
      debugPrint('Error updating setting: $e');
      // Revert if failed
      _loadPrivacySettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Controls', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
                  _buildSectionHeader('Profile Visibility', theme),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.public_rounded,
                      title: 'Public Profile',
                      subtitle: 'Allow others to find your profile',
                      value: _publicProfile,
                      onChanged: (val) => _toggleSetting('publicProfile', val),
                      theme: theme,
                    ),
                    _buildSwitchTile(
                      icon: Icons.location_on_outlined,
                      title: 'Show Location',
                      subtitle: 'Visible to potential employers/workers',
                      value: _showLocation,
                      onChanged: (val) => _toggleSetting('showLocation', val),
                      theme: theme,
                    ),
                  ], theme),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Contact Information', theme),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.phone_outlined,
                      title: 'Show Phone Number',
                      subtitle: 'Only verified contacts can see',
                      value: _showPhone,
                      onChanged: (val) => _toggleSetting('showPhoneNumber', val),
                      theme: theme,
                    ),
                    _buildSwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Show Email Address',
                      subtitle: 'Visible on your public profile',
                      value: _showEmail,
                      onChanged: (val) => _toggleSetting('showEmail', val),
                      theme: theme,
                    ),
                  ], theme),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.info.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.info, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Privacy settings control how other users interact with your data. Highly sensitive data like Govt ID is never shared.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
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

extension on ColorScheme {
  Color get info => const Color(0xFF0EA5E9);
}
