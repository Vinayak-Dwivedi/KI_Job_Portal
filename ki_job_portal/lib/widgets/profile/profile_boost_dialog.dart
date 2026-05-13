import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileBoostDialog extends StatefulWidget {
  final int currentCredits;
  final Function(int) onConfirm;

  const ProfileBoostDialog({
    super.key,
    required this.currentCredits,
    required this.onConfirm,
  });

  @override
  State<ProfileBoostDialog> createState() => _ProfileBoostDialogState();
}

class _ProfileBoostDialogState extends State<ProfileBoostDialog> {
  static const int _totalCost = 80;

  @override
  Widget build(BuildContext context) {
    const int totalCost = _totalCost;
    final bool canAfford = widget.currentCredits >= totalCost;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF151921).withOpacity(0.95), // darkSurfaceContainer
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Boost Your Profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get 10x more visibility and hire faster!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.darkOnSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Duration Selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Boost Duration",
                      style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "24 Hours",
                      style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cost and Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TOTAL COST", style: GoogleFonts.plusJakartaSans(color: AppColors.darkOnSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("$totalCost Credits", style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("YOUR BALANCE", style: GoogleFonts.plusJakartaSans(color: AppColors.darkOnSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("${widget.currentCredits} Credits", style: GoogleFonts.plusJakartaSans(color: canAfford ? Colors.white70 : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAfford ? () => widget.onConfirm(1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                    disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        canAfford ? 'Boost Now' : 'Insufficient Credits',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
