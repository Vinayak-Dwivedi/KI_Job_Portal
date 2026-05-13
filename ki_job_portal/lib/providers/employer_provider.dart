import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employer_model.dart';
import '../core/services/firestore_service.dart';

class EmployerNotifier extends Notifier<EmployerModel?> {
  @override
  EmployerModel? build() {
    return null;
  }

  void updateFromSignup({
    required String uid,
    required String contactName,
    required String companyName,
    required String phone,
    String? bio,
    String? hirerSubType,
  }) {
    state = EmployerModel(
      uid: uid,
      contactPersonName: contactName,
      companyName: companyName,
      phone: phone,
      isVerified: true,
      businessType: 'company',
      hirerSubType: hirerSubType ?? 'Company',
      officeAddress: '',
      credits: 50,
      bio: bio ?? '',
    );
  }


  Future<void> loadProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print("🔥 DATA FROM FIRESTORE: $data");
        state = EmployerModel.fromMap(data, uid);
      } else {
        // 🆕 Handle new employer WITHOUT a document (fallback)
        print("ℹ️ Employer Profile document not found, initializing basic state");
        state = EmployerModel(
          uid: uid,
          contactPersonName: 'Employer',
          companyName: 'Company Name',
          phone: '',
          businessType: '',
          officeAddress: '',
          isVerified: true,
          credits: 50,
        );
      }
    } catch (e) {
      print("❌ Error loading employer profile: $e");
    }
  }

  Future<void> boostProfile(int days) async {
    if (state == null) return;
    await FirestoreService.boostProfile(state!.uid, days);
    await loadProfile(state!.uid);
  }
}

final employerProvider = NotifierProvider<EmployerNotifier, EmployerModel?>(() => EmployerNotifier());
