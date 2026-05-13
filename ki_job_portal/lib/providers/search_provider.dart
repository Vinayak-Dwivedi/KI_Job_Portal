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

class SearchFilters {
  final String? skillType;
  final String? location;
  final String? subLocation;
  final int? minExperience;
  final String? jobType;

  SearchFilters({
    this.skillType,
    this.location,
    this.subLocation,
    this.minExperience,
    this.jobType,
  });

  SearchFilters copyWith({
    String? skillType,
    String? location,
    String? subLocation,
    int? minExperience,
    String? jobType,
  }) {
    return SearchFilters(
      skillType: skillType ?? this.skillType,
      location: location ?? this.location,
      subLocation: subLocation ?? this.subLocation,
      minExperience: minExperience ?? this.minExperience,
      jobType: jobType ?? this.jobType,
    );
  }

  bool get isEmpty => skillType == null && location == null && subLocation == null && minExperience == null && jobType == null;
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => SearchFilters();

  void updateFilters(SearchFilters filters) => state = filters;
  void clear() => state = SearchFilters();
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(() {
  return SearchFiltersNotifier();
});

// Provider to fetch all searchable entities (Jobs, Workers, Companies)
final searchResultsProvider = Provider.autoDispose<Map<String, List<Map<String, dynamic>>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final filters = ref.watch(searchFiltersProvider);
  final allPosts = ref.watch(unifiedFeedProvider).value ?? [];
  
  if (query.isEmpty && filters.isEmpty) {
    return {
      'jobs': [],
      'workers': [],
      'companies': [],
    };
  }

  // 1. Filter Jobs (from posts)
  final jobs = allPosts.where((post) {
    if (post['isJobPost'] != true) return false;
    
    // Text Query
    final title = (post['jobTitle'] ?? '').toString().toLowerCase();
    final companyName = (post['companyName'] ?? '').toString().toLowerCase();
    final text = (post['text'] ?? '').toString().toLowerCase();
    bool matchesQuery = query.isEmpty || title.contains(query) || companyName.contains(query) || text.contains(query);
    
    if (!matchesQuery) return false;

    // Advanced Filters
    if (filters.skillType != null && post['jobCategory'] != filters.skillType) return false;
    if (filters.location != null && !post['location'].toString().contains(filters.location!)) return false;
    if (filters.subLocation != null && !post['location'].toString().contains(filters.subLocation!)) return false;
    if (filters.minExperience != null && (int.tryParse(post['jobExperience']?.toString() ?? '0') ?? 0) < filters.minExperience!) return false;
    if (filters.jobType != null && post['jobType'] != filters.jobType) return false;

    return true;
  }).toList();

  // 2. Filter Workers & Companies
  final workers = ref.watch(workerListProvider).value ?? [];
  final filteredWorkers = workers.where((w) {
    final name = (w['name'] ?? '').toString().toLowerCase();
    final skills = (w['skills'] as List? ?? []).join(' ').toLowerCase();
    bool matchesQuery = query.isEmpty || name.contains(query) || skills.contains(query);
    
    if (!matchesQuery) return false;

    // Advanced Filters (Workers)
    if (filters.skillType != null && !(w['skills'] as List? ?? []).contains(filters.skillType)) return false;
    if (filters.location != null && !w['location'].toString().contains(filters.location!)) return false;
    if (filters.minExperience != null && (int.tryParse(w['experience']?.toString() ?? '0') ?? 0) < filters.minExperience!) return false;

    return true;
  }).toList();

  final companies = ref.watch(companyListProvider).value ?? [];
  final filteredCompanies = companies.where((c) {
    final name = (c['name'] ?? c['companyName'] ?? '').toString().toLowerCase();
    final bio = (c['bio'] ?? '').toString().toLowerCase();
    bool matchesQuery = query.isEmpty || name.contains(query) || bio.contains(query);
    
    if (!matchesQuery) return false;

    // Advanced Filters (Companies)
    if (filters.location != null && !c['location'].toString().contains(filters.location!)) return false;

    return true;
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
