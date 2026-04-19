import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class RolePreferencesScreen extends ConsumerStatefulWidget {
  const RolePreferencesScreen({super.key});

  @override
  ConsumerState<RolePreferencesScreen> createState() => _RolePreferencesScreenState();
}

class _RolePreferencesScreenState extends ConsumerState<RolePreferencesScreen> {
  // Worker State
  String _workSchedule = 'Full-time';
  String _primaryTrade = 'Plumbing / Pipefitting';
  String _secondaryTrade = 'General Maintenance';

  // Employer State
  String _hiringSpeed = 'Urgent / Immediate';
  String _teamSize = '5 - 10 Workers';
  String _locationPref = 'Mumbai Metropolitan';
  String _prefExperience = '3+ Years Professional';
  String _certLevel = 'Govt Certified Only';

  void _showSelectionSheet(String title, List<String> options, String currentValue, void Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((opt) {
                        final isSelected = opt == currentValue;
                        return ListTile(
                          title: Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
                          onTap: () {
                            onSelected(opt);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final isEmployer = user?.role == 'employer';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEmployer ? 'Recruitment Prefs' : 'Job Preferences', 
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
        child: isEmployer ? _buildEmployerPrefs(theme) : _buildWorkerPrefs(theme),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerPrefs(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Job Availability', theme),
        const SizedBox(height: 12),
        _buildCard([
          _buildPreferenceTile(Icons.access_time_rounded, 'Work Schedule', _workSchedule, theme, () {
            _showSelectionSheet('Work Schedule', ['Full-time', 'Part-time', 'Contract'], _workSchedule, (v) => setState(() => _workSchedule = v));
          }),
        ], theme),
        const SizedBox(height: 24),
        _buildSectionHeader('Trade Focus', theme),
        const SizedBox(height: 12),
        _buildCard([
          _buildPreferenceTile(Icons.construction_rounded, 'Primary Trade', _primaryTrade, theme, () {
            _showSelectionSheet('Primary Trade', ['Plumbing / Pipefitting', 'Electrical Work', 'Carpentry', 'Masonry', 'Driving', 'General Labor'], _primaryTrade, (v) => setState(() => _primaryTrade = v));
          }),
          _buildPreferenceTile(Icons.settings_suggest_outlined, 'Secondary Trade', _secondaryTrade, theme, () {
            _showSelectionSheet('Secondary Trade', ['General Maintenance', 'Welding', 'Painting', 'None', 'Security'], _secondaryTrade, (v) => setState(() => _secondaryTrade = v));
          }),
        ], theme),
      ],
    );
  }

  Widget _buildEmployerPrefs(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Hiring Strategy', theme),
        const SizedBox(height: 12),
        _buildCard([
          _buildPreferenceTile(Icons.speed_rounded, 'Hiring Speed', _hiringSpeed, theme, () {
            _showSelectionSheet('Hiring Speed', ['Urgent / Immediate', 'Within 1 Week', 'Within 1 Month'], _hiringSpeed, (v) => setState(() => _hiringSpeed = v));
          }),
          _buildPreferenceTile(Icons.groups_outlined, 'Typical Team Size', _teamSize, theme, () {
            _showSelectionSheet('Team Size', ['1 - 5 Workers', '5 - 10 Workers', '10+ Workers'], _teamSize, (v) => setState(() => _teamSize = v));
          }),
          _buildPreferenceTile(Icons.location_city_rounded, 'Project Location', _locationPref, theme, () {
            _showSelectionSheet('Location', ['Mumbai Metropolitan', 'Navi Mumbai', 'Thane', 'Pune', 'Delhi NCR'], _locationPref, (v) => setState(() => _locationPref = v));
          }),
        ], theme),
        const SizedBox(height: 24),
        _buildSectionHeader('Worker Requirements', theme),
        const SizedBox(height: 12),
        _buildCard([
          _buildPreferenceTile(Icons.verified_outlined, 'Preferred Experience', _prefExperience, theme, () {
            _showSelectionSheet('Experience', ['Entry Level', '1-2 Years', '3+ Years Professional'], _prefExperience, (v) => setState(() => _prefExperience = v));
          }),
          _buildPreferenceTile(Icons.workspace_premium_outlined, 'Certification Level', _certLevel, theme, () {
            _showSelectionSheet('Certification', ['Govt Certified Only', 'Any Certification', 'No Preference'], _certLevel, (v) => setState(() => _certLevel = v));
          }),
        ], theme),
      ],
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

  Widget _buildPreferenceTile(IconData icon, String title, String value, ThemeData theme, VoidCallback onTap) {
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
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(value, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
