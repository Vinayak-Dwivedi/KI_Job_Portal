import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class KIBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const KIBottomNavBar({super.key, required this.currentIndex});

  void _onTap(WidgetRef ref, BuildContext context, int index) {
    if (index == currentIndex) return;
    
    final role = ref.read(authProvider)?.role ?? 'worker';

    switch (index) {
      case 0:
        context.go(role == 'employer' ? '/employer/dashboard' : '/worker/dashboard');
        break;
      case 1:
        context.go(role == 'employer' ? '/employer/workers' : '/worker/jobs');
        break;
      case 2:
        context.push('/feed');
        break;
      case 3:
        context.go(role == 'employer' ? '/employer/my-jobs' : '/worker/subscriptions');
        break;
      case 4:
        context.go(role == 'employer' ? '/employer/profile' : '/worker/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final role = ref.watch(authProvider)?.role ?? 'worker';
    final l10n = AppLocalizations.of(context)!;
    
    final List<_NavItem> items = [
      _NavItem(icon: Icons.home_rounded, label: l10n.home),
      _NavItem(
        icon: role == 'employer' ? Icons.people_outline_rounded : Icons.work_outline_rounded, 
        label: role == 'employer' ? l10n.workers : l10n.jobs
      ),
      _NavItem(icon: null, label: l10n.post), // FAB center slot
      _NavItem(
        icon: role == 'employer' ? Icons.assignment_outlined : Icons.card_membership_rounded, 
        label: role == 'employer' ? l10n.myJobs : l10n.sub
      ),
      _NavItem(icon: Icons.person_outline_rounded, label: l10n.profile),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              // Center FAB slot
              if (i == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(ref, context, i),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                );
              }

              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTap(ref, context, i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
