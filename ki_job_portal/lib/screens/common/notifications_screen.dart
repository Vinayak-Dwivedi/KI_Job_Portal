import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:ki_job_portal/core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'package:ki_job_portal/l10n/app_localizations.dart';

final unreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(0);

  // We need to listen to user document for 'lastReadAnnouncementAt' 
  // and count unread personal notifications
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().asyncMap((userSnap) async {
    final lastReadAt = userSnap.data()?['lastReadAnnouncementAt'] as Timestamp? ?? Timestamp.fromMillisecondsSinceEpoch(0);
    
    // Count unread personal
    final personalCount = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get()
        .then((s) => s.docs.length);
    
    // Count new global announcements
    final announcementCount = await FirebaseFirestore.instance
        .collection('announcements')
        .where('createdAt', isGreaterThan: lastReadAt)
        .get()
        .then((s) => s.docs.length);

    return personalCount + announcementCount;
  });
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final uid = auth?.uid;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () {
            if (uid != null) _updateLastReadAnnouncement(uid);
            Navigator.pop(context);
          },
        ),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text(
                l10n.markAllRead,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in to view notifications.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getCombinedNotificationsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noNotifications,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.notificationsHint,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = items[index];
                    final isRead = data['isRead'] ?? false;
                    final type = data['type'] ?? 'general';
                    final createdAt = data['createdAt'] as Timestamp?;
                    
                    // Localize title based on type
                    String title;
                    switch (type) {
                      case 'chat': title = l10n.notif_chat_title; break;
                      case 'post_like': title = l10n.notif_post_like_title; break;
                      case 'post_comment': title = l10n.notif_post_comment_title; break;
                      case 'post_approved': title = l10n.notif_post_approved_title; break;
                      case 'invite': title = l10n.notif_invite_title; break;
                      case 'post_share': title = l10n.notif_post_share_title; break;
                      default: title = data['title'] ?? l10n.notif_default_title;
                    }

                    // Localize body based on type
                    String body;
                    switch (type) {
                      case 'chat': body = l10n.notif_chat_body; break;
                      case 'post_like': body = l10n.notif_post_like_body; break;
                      case 'post_comment': body = l10n.notif_post_comment_body; break;
                      case 'post_approved': body = l10n.notif_post_approved_body; break;
                      case 'invite': body = l10n.notif_invite_body; break;
                      case 'post_share': body = l10n.notif_post_share_body; break;
                      default: body = data['body'] ?? data['message'] ?? '';
                    }

                    final timeAgo = createdAt != null
                        ? timeago.format(createdAt.toDate(), locale: l10n.localeName)
                        : '';

                    return GestureDetector(
                      onTap: () {
                        if (data['id'] != null && data['isGlobal'] != true) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('notifications')
                              .doc(data['id'])
                              .update({'isRead': true});
                        }

                        final postId = data['postId'] as String?;
                        final chatId = data['chatId'] as String?;
                        final jobId = data['jobId'] as String?;
                        final actorUid = data['actorUid'] as String?;

                        switch (type) {
                          case 'chat':
                            if (chatId != null) {
                              context.push('/chat/$chatId', extra: {'name': 'KI GLOBAL ADMIN'});
                            }
                            break;
                          case 'post':
                          case 'post_like':
                          case 'post_comment':
                          case 'post_approved':
                          case 'post_share':
                          case 'social':
                          case 'broadcast':
                          case 'success':
                          case 'error':
                          case 'warning':
                            if (postId != null && postId.isNotEmpty) {
                              context.push('/feed/post/$postId');
                            } else if (['post_approved', 'post', 'post_like', 'post_comment', 'post_share', 'success', 'error', 'warning'].contains(type)) {
                              context.push('/feed');
                            }
                            break;
                          case 'invite':
                            if (jobId != null) {
                              context.push('/job/$jobId');
                            } else {
                              context.push('/worker/jobs');
                            }
                            break;
                          case 'application':
                            if (jobId != null) {
                              final isEmployer = auth?.role == 'employer';
                              if (isEmployer) {
                                context.push('/job/$jobId/applicants');
                              } else {
                                context.push('/job/$jobId');
                              }
                            } else {
                              final isEmployer = auth?.role == 'employer';
                              context.push(isEmployer ? '/employer/dashboard' : '/worker/jobs');
                            }
                            break;
                          default:
                            if (actorUid != null) {
                              context.push('/profile/worker/$actorUid');
                            }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? theme.cardColor
                              : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? theme.colorScheme.outline.withOpacity(0.05)
                                : AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _getIconColor(type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getIcon(type),
                                color: _getIconColor(type),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (data['isGlobal'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                          ),
                                          child: const Text(
                                            'SYSTEM',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.blue,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    timeAgo,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedNotificationsStream(String uid) {
    final personalStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();

    final announcementsStream = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    final userDocStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return Rx.combineLatest3(
      personalStream,
      announcementsStream,
      userDocStream,
      (QuerySnapshot personal, QuerySnapshot global, DocumentSnapshot user) {
        final userData = user.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? 'worker';
        final lastReadAt = userData != null && userData.containsKey('lastReadAnnouncementAt')
            ? userData['lastReadAnnouncementAt'] as Timestamp
            : Timestamp.fromMillisecondsSinceEpoch(0);

        final List<Map<String, dynamic>> combined = [];

        // 1. Add Personal Notifications (Already filtered by UID in query)
        for (var doc in personal.docs) {
          final data = doc.data() as Map<String, dynamic>;
          combined.add({...data, 'id': doc.id, 'isGlobal': false});
        }

        // 2. Add and Filter Global Announcements
        for (var doc in global.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Filtering logic:
          // - target == 'all' -> show to everyone
          // - target == 'workers' -> show only if user is worker
          // - target == 'employers' -> show only if user is employer
          final target = data['target'] ?? 'all';
          bool shouldShow = target == 'all' || 
                           (target == 'workers' && userRole == 'worker') || 
                           (target == 'employers' && userRole == 'employer');

          if (shouldShow) {
            final createdAt = data['createdAt'] as Timestamp?;
            final isRead = createdAt != null && createdAt.millisecondsSinceEpoch <= lastReadAt.millisecondsSinceEpoch;
            combined.add({...data, 'id': doc.id, 'isGlobal': true, 'isRead': isRead, 'type': 'broadcast'});
          }
        }

        combined.sort((a, b) {
          final timeA = a['createdAt'] as Timestamp?;
          final timeB = b['createdAt'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        return combined;
      },
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'job':
        return Icons.work_outline_rounded;
      case 'application':
        return Icons.assignment_turned_in_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'credit':
        return Icons.toll_rounded;
      case 'subscription':
        return Icons.star_outline_rounded;
      case 'verification':
        return Icons.verified_outlined;
      case 'admin_post':
        return Icons.security_outlined;
      case 'post':
      case 'post_like':
      case 'post_comment':
        return Icons.article_outlined;
      case 'post_share':
        return Icons.repeat_rounded;
      case 'post_approved':
        return Icons.check_circle_outline_rounded;
      case 'broadcast':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'job':
        return AppColors.primary;
      case 'application':
        return const Color(0xFF10B981);
      case 'chat':
        return const Color(0xFF60A5FA);
      case 'credit':
        return const Color(0xFFFBBF24);
      case 'subscription':
        return const Color(0xFFEC4899);
      case 'verification':
        return const Color(0xFF10B981);
      case 'admin_post':
        return Colors.indigo;
      case 'post':
      case 'post_like':
      case 'post_comment':
        return const Color(0xFF8B5CF6); // Purple
      case 'post_share':
        return AppColors.primary; // Or any suitable color
      case 'post_approved':
        return const Color(0xFF10B981); // Green
      case 'broadcast':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _updateLastReadAnnouncement(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'lastReadAnnouncementAt': Timestamp.now(),
    });
  }

  Future<void> _markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Mark personal notifications
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Mark global ones by updating timestamp
    batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
      'lastReadAnnouncementAt': Timestamp.now(),
    });

    await batch.commit();
  }
}

class Rx {
  static Stream<T> combineLatest3<A, B, C, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    T Function(A, B, C) combiner,
  ) {
    final controller = StreamController<T>();
    A? lastA;
    B? lastB;
    C? lastC;
    
    void update() {
      if (lastA != null && lastB != null && lastC != null) {
        controller.add(combiner(lastA!, lastB!, lastC!));
      }
    }

    final subA = streamA.listen((v) { lastA = v; update(); });
    final subB = streamB.listen((v) { lastB = v; update(); });
    final subC = streamC.listen((v) { lastC = v; update(); });

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
      subC.cancel();
    };

    return controller.stream;
  }
}
