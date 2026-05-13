import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/primary_button.dart';
import '../providers/localization_provider.dart';
import '../l10n/app_localizations.dart';

class SplashLandingScreen extends ConsumerWidget {
  const SplashLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localizationProvider);
   

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    Text(
                      'KI',
                      style: theme.textTheme.displayLarge?.copyWith(color: Colors.white, letterSpacing: -1, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.earnSkills,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, left: 32, right: 32, bottom: 32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, -10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language selector
                    GestureDetector(
                      onTap: () => context.push('/settings/language'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              currentLocale.languageCode == 'hi' ? 'हिन्दी' : 'English',
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: AppLocalizations.of(context)!.getStarted,
                      onPressed: () => context.push('/role-select'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                          children: [
                            TextSpan(text: AppLocalizations.of(context)!.alreadyAccount),
                            TextSpan(
                              text: AppLocalizations.of(context)!.loginUnderlined,
                              style: const TextStyle(decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.terms, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, letterSpacing: 1)),
                        Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.outline.withOpacity(0.5))),
                        Text(AppLocalizations.of(context)!.privacy, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.copyrightMarketplace, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

