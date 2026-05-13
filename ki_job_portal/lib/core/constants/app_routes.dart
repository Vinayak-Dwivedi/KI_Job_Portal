import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/firebase_test_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/employer_provider.dart';
import '../../screens/splash_landing_screen.dart';
import '../../screens/user_type_selection.dart';
import '../../core/services/subscription_service.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/verification_success_screen.dart';
import '../../screens/auth/worker_signup.dart';
import '../../screens/auth/employer_signup.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/common/search_screen.dart';
import '../../screens/worker/worker_dashboard.dart';
import '../../screens/worker/worker_profile_screen.dart';
import '../../screens/common/edit_profile_screen.dart';
import '../../screens/worker/worker_subscription_screen.dart';
import '../../screens/worker/worker_jobs_screen.dart';
import '../../screens/employer/employer_dashboard.dart';
import '../../screens/employer/employer_profile_screen.dart';
import '../../screens/employer/employer_workers_screen.dart';
import '../../screens/employer/employer_my_jobs_screen.dart';
import '../../screens/employer/create_job_screen.dart';
import '../../screens/worker/job_detail_screen.dart';
import '../../screens/feed/feed_screen.dart';
import '../../screens/feed/create_post_screen.dart';
import '../../screens/feed/post_detail_screen.dart';
import '../../screens/feed/reels_screen.dart';
import '../../screens/common/public_profile_screen.dart';
import '../../screens/subscription/subscription_plans_screen.dart';
import '../../screens/subscription/subscription_checkout_screen.dart';
import '../../screens/subscription/subscription_success_screen.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_posts_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_promotions_screen.dart';
import '../../screens/admin/admin_plans_screen.dart';
import '../../screens/banned_screen.dart';
import '../../widgets/common/page_transitions.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/language_settings_screen.dart';
import '../../screens/settings/privacy_settings_screen.dart';
import '../../screens/settings/notification_settings_screen.dart';
import '../../screens/settings/verification_screen.dart';
import '../../screens/settings/role_preferences_screen.dart';
import '../../screens/settings/support_screen.dart';
import '../../screens/settings/blocked_users_screen.dart';
import '../../screens/common/announcements_screen.dart';
import '../../screens/common/notifications_screen.dart';
import '../../screens/worker/earnings_screen.dart';
import '../../screens/employer/applicant_management_screen.dart';
import '../../screens/common/profile_visitors_screen.dart';
import '../../screens/common/credit_history_screen.dart';
import '../../screens/common/referral_screen.dart';

import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_room_screen.dart';
import '../../widgets/common/ki_bottom_nav_bar.dart';

// Shell scaffold for Worker — holds bottom nav bar
class WorkerShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;
  const WorkerShell({super.key, required this.child, required this.currentIndex});

  @override
  ConsumerState<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends ConsumerState<WorkerShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth != null) {
        ref.read(workerProvider.notifier).loadProfile(auth.uid);
        SubscriptionService.checkAndDeactivateIfExpired(auth.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: KIBottomNavBar(currentIndex: widget.currentIndex),
    );
  }
}

// Shell scaffold for Employer — holds bottom nav bar
class EmployerShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;
  const EmployerShell({super.key, required this.child, required this.currentIndex});

  @override
  ConsumerState<EmployerShell> createState() => _EmployerShellState();
}

class _EmployerShellState extends ConsumerState<EmployerShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth != null) {
        ref.read(employerProvider.notifier).loadProfile(auth.uid);
        SubscriptionService.checkAndDeactivateIfExpired(auth.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: KIBottomNavBar(currentIndex: widget.currentIndex),
    );
  }
}

// Router provider
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = auth != null;
      final isAuthRoute = state.matchedLocation.startsWith('/splash') ||
          state.matchedLocation.startsWith('/role-select') ||
          state.matchedLocation.startsWith('/worker/signup') ||
          state.matchedLocation.startsWith('/employer/signup') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/admin') ||
          state.matchedLocation.startsWith('/verified');
      
      if (isLoggedIn && isAuthRoute) {
        return auth.role == 'employer' ? '/employer/dashboard' : '/worker/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashLandingScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const UserTypeSelectionScreen()),
      GoRoute(path: '/worker/signup', builder: (_, __) => const WorkerSignupScreen()),
      GoRoute(path: '/employer/signup', builder: (_, __) => const EmployerSignupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return fadeInPage(
            state,
            OtpVerificationScreen(
              phone: extra['phone'] ?? '',
              role: extra['role'] ?? 'worker',
              name: extra['name'] ?? '',
              company: extra['company'] ?? '',
              skill: extra['skill'] ?? '',
              experience: extra['experience'] ?? '',
              location: extra['location'] ?? '',
              subLocation: extra['subLocation'] ?? '',
              latitude: extra['latitude']?.toString() ?? '0',
              longitude: extra['longitude']?.toString() ?? '0',
              bio: extra['bio']?.toString() ?? '',
              businessType: extra['businessType']?.toString() ?? '',
              profilePhotoPath: extra['profilePhotoPath'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/verified', 
        pageBuilder: (context, state) => fadeInPage(state, const VerificationSuccessScreen()),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      
      // Worker shell routes
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.matchedLocation;
          int currentIndex = 0;
          if (loc.startsWith('/worker/jobs')) currentIndex = 1;
          if (loc.startsWith('/worker/subscriptions')) currentIndex = 3;
          if (loc.startsWith('/worker/profile')) currentIndex = 4;
          return WorkerShell(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(path: '/worker/dashboard', builder: (_, __) => const WorkerHomeFeed()),
          GoRoute(path: '/worker/jobs', builder: (_, __) => const WorkerJobsScreen()),
          GoRoute(
            path: '/worker/subscriptions',
            builder: (context, state) {
              final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return WorkerSubscriptionScreen(initialTab: tab);
            },
          ),
          GoRoute(path: '/worker/profile', builder: (_, __) => const WorkerProfileScreen()),
        ],
      ),
      // Employer shell routes
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.matchedLocation;
          int currentIndex = 0;
          if (loc.startsWith('/employer/workers')) currentIndex = 1;
          if (loc.startsWith('/employer/my-jobs')) currentIndex = 3;
          if (loc.startsWith('/employer/profile')) currentIndex = 4;
          return EmployerShell(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(path: '/employer/dashboard', builder: (_, __) => const EmployerDashboardScreen()),
          GoRoute(path: '/employer/workers', builder: (_, __) => const EmployerWorkersScreen()),
          GoRoute(path: '/employer/my-jobs', builder: (_, __) => const EmployerMyJobsScreen()),
          GoRoute(path: '/employer/profile', builder: (_, __) => const EmployerProfileScreen()),
        ],
      ),
      
      // Detailed Views (Full Screen)
      GoRoute(
        path: '/job/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return slideRightPage(state, JobDetailScreen(jobId: id));
        },
      ),
      GoRoute(
        path: '/job/:id/applicants',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return slideRightPage(state, ApplicantManagementScreen(jobId: id));
        },
      ),
      
      // Compatibility Redirect
      GoRoute(
        path: '/employer/:uid',
        redirect: (context, state) => '/profile/employer/${state.pathParameters['uid']}',
      ),
      
      // Unified Profile Route
      GoRoute(
        path: '/profile/:role/:uid',
        pageBuilder: (context, state) {
          final role = state.pathParameters['role']!;
          final uid = state.pathParameters['uid']!;
          return slideRightPage(state, PublicProfileScreen(uid: uid, role: role));
        },
      ),

      GoRoute(path: '/employer/create-job', builder: (_, __) => const CreateJobScreen()),

      // Feed routes
      GoRoute(
        path: '/feed', 
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return FeedScreen(targetPostId: postId);
        },
      ),
      GoRoute(
        path: '/feed/create', 
        builder: (context, state) {
          final post = state.extra as Map<String, dynamic>?;
          return CreatePostScreen(post: post);
        },
      ),
      GoRoute(
        path: '/feed/post/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return slideRightPage(state, PostDetailScreen(postId: id));
        },
      ),
      GoRoute(
        path: '/reels',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return slideRightPage(state, ReelsScreen(initialPostId: extra['postId']));
        },
      ),

      // Chat routes
      GoRoute(path: '/chat', redirect: (_, __) => '/chats'),
      GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return slideRightPage(
            state,
            ChatRoomScreen(
              chatId: id,
              otherUserName: extra['name'] ?? 'User',
              otherUserPhoto: extra['photo'],
            ),
          );
        },
      ),

      // Subscription routes
      GoRoute(path: '/subscription', redirect: (_, __) => '/subscription-plans'),
      GoRoute(path: '/subscription-plans', builder: (_, __) => const SubscriptionPlansScreen()),
      GoRoute(
        path: '/subscription-checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SubscriptionCheckoutScreen(
            plan: extra['plan'],
          );
        },
      ),
      GoRoute(path: '/subscription-success', builder: (_, __) => const SubscriptionSuccessScreen()),

      // Admin routes
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/posts', builder: (_, __) => const AdminPostsScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/promotions', builder: (_, __) => const AdminPromotionsScreen()),
      GoRoute(path: '/admin/plans', builder: (_, __) => const AdminPlansScreen()),

      // Banned Screen
      GoRoute(path: '/banned', builder: (_, __) => const BannedScreen()),
      GoRoute(
        path: '/test',
        builder: (context, state) => const FirebaseTestScreen(),
      ),

      // Settings routes
      GoRoute(path: '/settings', pageBuilder: (context, state) => slideRightPage(state, const SettingsScreen())),
      GoRoute(path: '/settings/language', pageBuilder: (context, state) => slideRightPage(state, const LanguageSettingsScreen())),
      GoRoute(path: '/settings/privacy', pageBuilder: (context, state) => slideRightPage(state, const PrivacySettingsScreen())),
      GoRoute(path: '/settings/notifications', pageBuilder: (context, state) => slideRightPage(state, const NotificationSettingsScreen())),
      GoRoute(path: '/settings/verification', pageBuilder: (context, state) => slideRightPage(state, const VerificationScreen())),
      GoRoute(path: '/settings/preferences', pageBuilder: (context, state) => slideRightPage(state, const RolePreferencesScreen())),
      GoRoute(path: '/settings/support', pageBuilder: (context, state) => slideRightPage(state, const SupportScreen())),
      GoRoute(path: '/settings/blocked', pageBuilder: (context, state) => slideRightPage(state, const BlockedUsersScreen())),
      GoRoute(path: '/announcements', pageBuilder: (context, state) => slideRightPage(state, const AnnouncementsScreen())),
      GoRoute(path: '/notifications', pageBuilder: (context, state) => slideRightPage(state, const NotificationsScreen())),
      GoRoute(path: '/worker/earnings', pageBuilder: (context, state) => slideRightPage(state, const EarningsScreen())),
      GoRoute(path: '/profile/visitors', pageBuilder: (context, state) => slideRightPage(state, const ProfileVisitorsScreen())),
      GoRoute(path: '/profile/credits', pageBuilder: (context, state) => slideRightPage(state, const CreditHistoryScreen())),
      GoRoute(
        path: '/buy-credits',
        pageBuilder: (context, state) => slideRightPage(
          state,
          const WorkerSubscriptionScreen(initialTab: 1),
        ),
      ),
      GoRoute(path: '/referral', pageBuilder: (context, state) => slideRightPage(state, const ReferralScreen())),
    ],
  );
});
