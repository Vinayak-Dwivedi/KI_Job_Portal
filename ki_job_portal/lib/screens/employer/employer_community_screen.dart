import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employer_community_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../l10n/app_localizations.dart';

class EmployerCommunityScreen extends ConsumerWidget {
  const EmployerCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final employeesAsync = ref.watch(employerHiredEmployeesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.community,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows for Premium Aesthetic
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlow(AppColors.primary.withOpacity(0.05), 350),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: _buildGlow(const Color(0xFF10B981).withOpacity(0.04), 400),
          ),
          
          SafeArea(
            child: employeesAsync.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return _buildEmptyState(context, theme);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    return _buildEmployeeCard(context, ref, employees[index], theme);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error: $err',
                    style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, WidgetRef ref, Map<String, dynamic> employee, ThemeData theme) {
    final name = employee['workerName'] ?? 'Worker';
    final phone = employee['workerPhone'] ?? '';
    final imageUrl = employee['workerImageUrl'] ?? '';
    final workerId = employee['workerId'] ?? '';
    final appliedAt = employee['appliedAt'];

    String hiredDate = 'Hired Employee';
    if (appliedAt is Timestamp) {
      final date = appliedAt.toDate();
      hiredDate = 'Hired on ${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Photo
            GestureDetector(
              onTap: () {
                if (workerId.isNotEmpty) {
                  context.push('/profile/worker/$workerId');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 24)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (workerId.isNotEmpty) {
                        context.push('/profile/worker/$workerId');
                      }
                    },
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hiredDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat Button
                _buildActionCircle(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  onTap: () async {
                    final auth = ref.read(authProvider);
                    if (auth == null || workerId.isEmpty) return;
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingContext) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                      
                      final targetUserData = {
                        'name': name,
                        'profilePhotoUrl': imageUrl,
                        'phone': phone,
                      };
                      
                      final chatId = await ChatService.getOrCreateChat(auth.uid, workerId, targetUserData);
                      if (context.mounted) Navigator.pop(context); // Close loading
                      
                      if (chatId.isNotEmpty) {
                        if (context.mounted) {
                          context.push('/chat/$chatId', extra: {
                            'name': name,
                            'photo': imageUrl,
                          });
                        }
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      debugPrint("Error opening chat: $e");
                    }
                  },
                ),
                const SizedBox(width: 8),
                
                // Call Button
                if (phone.isNotEmpty) ...[
                  _buildActionCircle(
                    icon: Icons.call_outlined,
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      final url = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch dialer.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No community is there',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't hired any employees yet. Once you hire a worker, they will appear in your community list.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/employer/workers'),
                icon: const Icon(Icons.person_search_rounded, color: Colors.white),
                label: Text(
                  'Browse Workers',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
        ],
      ),
    );
  }
}
