import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/public_user_provider.dart';
import '../../core/theme/app_colors.dart';

class UserCreditsWidget extends ConsumerWidget {
  final bool showLabel;
  final double fontSize;
  final double iconSize;
  final Color? color;
  final bool useCardStyle;

  const UserCreditsWidget({
    super.key,
    this.showLabel = true,
    this.fontSize = 14,
    this.iconSize = 18,
    this.color,
    this.useCardStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(userCreditsProvider);
    final theme = Theme.of(context);

    return creditsAsync.when(
      data: (data) {
        final credits = int.tryParse(data?['balance']?.toString() ?? '0') ?? 0;
        return _buildCreditsUI(context, credits, theme);
      },
      loading: () => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => _buildCreditsUI(context, 0, theme),
    );
  }

  Widget _buildCreditsUI(BuildContext context, int credits, ThemeData theme) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.toll_rounded,
          size: iconSize,
          color: color ?? AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$credits${showLabel ? " Credits" : ""}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    if (useCardStyle) {
      return InkWell(
        onTap: () => context.push('/worker/subscriptions?tab=1'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: content,
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/worker/subscriptions?tab=1'),
      child: content,
    );
  }
}
