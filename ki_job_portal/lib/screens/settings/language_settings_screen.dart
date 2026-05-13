import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
// Trigger re-analysis
import '../../core/theme/app_colors.dart';
import '../../providers/localization_provider.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.languageSelection, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _languages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = currentLocale.languageCode == lang['code'];

          return GestureDetector(
            onTap: () => ref.read(localizationProvider.notifier).setLanguage(lang['code']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                   Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lang['name']![0],
                        style: TextStyle(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          lang['native']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
                  else
                    Icon(Icons.circle_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), size: 24),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: theme.colorScheme.primary.withOpacity(0.4),
            ),
            child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
