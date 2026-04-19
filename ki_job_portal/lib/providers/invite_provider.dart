import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/invite_service.dart';
import 'auth_provider.dart';

/// Stream of all invitations for the current logged-in worker.
final workerInvitationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth == null) return Stream.value([]);
  return InviteService.getWorkerInvitations(auth.uid);
});

/// Count of pending invitations for the current worker.
final pendingInvitesCountProvider = Provider.autoDispose<int>((ref) {
  final invitesAsync = ref.watch(workerInvitationsProvider);
  return invitesAsync.when(
    data: (list) =>
        list.where((inv) => inv['status'] == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
