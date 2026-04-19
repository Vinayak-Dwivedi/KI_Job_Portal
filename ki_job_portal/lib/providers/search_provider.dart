import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_provider.dart';

// Notifier based on auth_provider.dart pattern
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set updateValue(String val) => state = val;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Provider to fetch all searchable entities (Jobs, Workers, Companies)
final searchResultsProvider = Provider.autoDispose<Map<String, List<Map<String, dynamic>>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final allPosts = ref.watch(unifiedFeedProvider).value ?? [];
  
  if (query.isEmpty) {
    return {
      'jobs': [],
      'workers': [],
      'companies': [],
    };
  }

  // 1. Filter Jobs (from posts)
  final jobs = allPosts.where((post) {
    if (post['isJobPost'] != true) return false;
    final title = (post['jobTitle'] ?? '').toString().toLowerCase();
    final companyName = (post['companyName'] ?? '').toString().toLowerCase();
    final text = (post['text'] ?? '').toString().toLowerCase();
    return title.contains(query) || companyName.contains(query) || text.contains(query);
  }).toList();

  // 2. Filter Workers & Companies
  final workers = ref.watch(workerListProvider).value ?? [];
  final filteredWorkers = workers.where((w) {
    final name = (w['name'] ?? '').toString().toLowerCase();
    final skills = (w['skills'] as List? ?? []).join(' ').toLowerCase();
    return name.contains(query) || skills.contains(query);
  }).toList();

  final companies = ref.watch(companyListProvider).value ?? [];
  final filteredCompanies = companies.where((c) {
    final name = (c['name'] ?? c['companyName'] ?? '').toString().toLowerCase();
    final bio = (c['bio'] ?? '').toString().toLowerCase();
    return name.contains(query) || bio.contains(query);
  }).toList();

  return {
    'jobs': jobs,
    'workers': filteredWorkers,
    'companies': filteredCompanies,
  };
});

// Helper provider for all workers
final workerListProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
});

// Helper provider for all companies
final companyListProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'employer')
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
});
