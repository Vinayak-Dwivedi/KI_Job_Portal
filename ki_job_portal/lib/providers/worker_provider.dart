import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';

class WorkerNotifier extends Notifier<WorkerModel?> {
  @override
  WorkerModel? build() => null;

  void updateFromSignup({
    required String uid,
    required String name,
    required String phone,
    required String skill,
    required String experience,
  }) {
    state = WorkerModel(
      uid: uid,
      name: name.isNotEmpty ? name : 'Worker',
      phone: phone,
      isVerified: true,
      jobCategory: 'blue_collar',
      jobTitles: skill.isNotEmpty ? [skill] : [],
      skills: skill.isNotEmpty ? [skill] : [],
      experience: int.tryParse(experience) ?? 0,
      location: 'India',
      credits: 50,
    );
  }

  void updateWorker(WorkerModel updated) {
    state = updated;
  }

  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name);
  }

  void updateSkills(List<String> skills) {
    if (state == null) return;
    state = state!.copyWith(skills: skills);
  }
  Future<void> loadProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final skillsList = data['skills'];
        List<String> parsedSkills = [];
        if (skillsList is List) {
          parsedSkills = List<String>.from(skillsList);
        }
        state = WorkerModel.fromMap(data, uid);
      } else {
        // 🆕 Handle new user WITHOUT a document (fallback)
        print("ℹ️ Worker Profile document not found, initializing basic state");
        state = WorkerModel(
          uid: uid,
          name: 'Worker',
          phone: '',
          isVerified: false, // Default to false
          jobCategory: 'blue_collar',
          jobTitles: [],
          skills: [],
          experience: 0,
          location: 'Not set',
          credits: 50,
        );
      }
    } catch (e) {
      print("❌ Error loading worker profile: $e");
    }
  }
}

final workerProvider = NotifierProvider<WorkerNotifier, WorkerModel?>(() => WorkerNotifier());
