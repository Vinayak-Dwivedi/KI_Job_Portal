import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Mock Auth Notifier — replace with FirebaseAuth stream later
class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid = prefs.getString('auth_uid');
    final phone = prefs.getString('auth_phone');
    final role = prefs.getString('auth_role');
    
    if (uid != null && phone != null && role != null) {
      return UserModel(
        uid: uid,
        phone: phone,
        role: role,
        isVerified: true,
        isProfileComplete: true,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  void login(String phone, String role) {
    final uid = 'uid_${phone.replaceAll(RegExp(r'\D'), '')}';
    loginWithUid(uid, phone, role);
  }

  void loginWithUid(String uid, String phone, String role) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('auth_uid', uid);
    prefs.setString('auth_phone', phone);
    prefs.setString('auth_role', role);

    state = UserModel(
      uid: uid,
      phone: phone,
      role: role,
      isVerified: true,
      isProfileComplete: true,
      createdAt: DateTime.now(),
    );
  }

  void logout() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('auth_uid');
    prefs.remove('auth_phone');
    prefs.remove('auth_role');
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider)?.role;
});
