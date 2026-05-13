import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum BadgeType { elite, topRated, expert, fastResponder, verified }

class AchievementBadge extends StatelessWidget {
  final BadgeType type;
  final String? label;

  const AchievementBadge({
    super.key,
    required this.type,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (type) {
      case BadgeType.elite:
        icon = Icons.workspace_premium_rounded;
        color = const Color(0xFFF59E0B);
        text = label ?? 'Elite';
        break;
      case BadgeType.topRated:
        icon = Icons.star_rounded;
        color = AppColors.primary;
        text = label ?? 'Top Rated';
        break;
      case BadgeType.expert:
        icon = Icons.psychology_rounded;
        color = Colors.deepPurpleAccent;
        text = label ?? 'Expert';
        break;
      case BadgeType.fastResponder:
        icon = Icons.bolt_rounded;
        color = Colors.cyan;
        text = label ?? 'Fast Responder';
        break;
      case BadgeType.verified:
        icon = Icons.verified_rounded;
        color = const Color(0xFF10B981);
        text = label ?? 'Verified';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
