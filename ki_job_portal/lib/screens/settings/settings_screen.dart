import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppLocalizations.of(context)!.accountPreferences, theme),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  title: AppLocalizations.of(context)!.verificationDocuments,
                  subtitle: AppLocalizations.of(context)!.verificationSubtitle,
                  onTap: () => context.push('/settings/verification'),
                  theme: theme,
                ),
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  title: AppLocalizations.of(context)!.rolePreferences,
                  subtitle: user?.role == 'employer' ? AppLocalizations.of(context)!.hiringNeeds : AppLocalizations.of(context)!.jobPreferences,
                  onTap: () => context.push('/settings/preferences'),
                  theme: theme,
                ),
                _SettingsTile(
                  icon: Icons.translate_rounded,
                  title: AppLocalizations.of(context)!.language,
                  subtitle: AppLocalizations.of(context)!.languageSubtitle,
                  onTap: () => context.push('/settings/language'),
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.securityPrivacy, theme),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: AppLocalizations.of(context)!.privacyControls,
                  subtitle: AppLocalizations.of(context)!.privacySubtitle,
                  onTap: () => context.push('/settings/privacy'),
                  theme: theme,
                ),
                _SettingsTile(
                  icon: Icons.block_rounded,
                  title: AppLocalizations.of(context)!.blockedUsers,
                  subtitle: AppLocalizations.of(context)!.blockedUsersSubtitle,
                  onTap: () => context.push('/settings/blocked'),
                  theme: theme,
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: AppLocalizations.of(context)!.notifications,
                  subtitle: AppLocalizations.of(context)!.notificationsSubtitle,
                  onTap: () => context.push('/settings/notifications'),
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.general, theme),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: AppLocalizations.of(context)!.helpSupport,
                  subtitle: AppLocalizations.of(context)!.helpSupportSubtitle,
                  onTap: () => context.push('/settings/support'),
                  theme: theme,
                ),
                _SettingsToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: AppLocalizations.of(context)!.darkMode,
                  subtitle: AppLocalizations.of(context)!.darkModeSubtitle,
                  value: ref.watch(themeModeProvider) == ThemeMode.dark,
                  onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
                  theme: theme,
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: AppLocalizations.of(context)!.about,
                  subtitle: AppLocalizations.of(context)!.aboutSubtitle,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.cardColor,
                        title: Text(AppLocalizations.of(context)!.aboutApp, style: const TextStyle(fontWeight: FontWeight.bold)),
                        content: Text(AppLocalizations.of(context)!.aboutContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(AppLocalizations.of(context)!.close),
                          )
                        ],
                      ),
                    );
                  },
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => _confirmLogout(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.confirmLogout, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.logoutMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        ref.read(authProvider.notifier).logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;

  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
