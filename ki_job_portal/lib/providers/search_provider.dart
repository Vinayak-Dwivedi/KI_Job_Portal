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
    Object? skillType = const Object(),
    Object? location = const Object(),
    Object? subLocation = const Object(),
    Object? minExperience = const Object(),
    Object? jobType = const Object(),
  }) {
    return SearchFilters(
      skillType: skillType == const Object() ? this.skillType : (skillType as String?),
      location: location == const Object() ? this.location : (location as String?),
      subLocation: subLocation == const Object() ? this.subLocation : (subLocation as String?),
      minExperience: minExperience == const Object() ? this.minExperience : (minExperience as int?),
      jobType: jobType == const Object() ? this.jobType : (jobType as String?),
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

// Helper function to match query terms across searchable fields with keyword normalization/stemming
bool _matchesSearchQuery(String query, List<String> fieldsToSearch) {
  if (query.isEmpty) return true;
  
  // Helper to normalize a single word
  String normalizeWord(String word) {
    final clean = word.trim().toLowerCase();
    if (clean.startsWith('plumb')) return 'plumb';
    if (clean.startsWith('electr')) return 'electr';
    if (clean.startsWith('carpent')) return 'carpent';
    if (clean.startsWith('weld')) return 'weld';
    if (clean.startsWith('paint')) return 'paint';
    if (clean.startsWith('mason')) return 'mason';
    if (clean.startsWith('driv')) return 'driv';
    if (clean.startsWith('clean')) return 'clean';
    if (clean.startsWith('garden')) return 'garden';
    if (clean.startsWith('tailor')) return 'tailor';
    if (clean.startsWith('cook')) return 'cook';
    if (clean.startsWith('mechan')) return 'mechan';
    if (clean.startsWith('technic')) return 'technic';
    if (clean.startsWith('secur')) return 'secur';
    return clean;
  }

  // Split query into words and normalize each
  final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map(normalizeWord).toList();
  if (queryWords.isEmpty) return true;

  // Extract and normalize all words from all fields
  final allNormalizedFieldWords = <String>{};
  final combinedFieldTextLower = fieldsToSearch.join(' ').toLowerCase();
  
  for (final field in fieldsToSearch) {
    final fieldLower = field.toLowerCase();
    final fieldWords = fieldLower.split(RegExp(r'[\s\-_,./\\()]+')).where((w) => w.isNotEmpty).map(normalizeWord);
    allNormalizedFieldWords.addAll(fieldWords);
  }

  // Check if ALL query words are matched by at least one field word
  for (final qw in queryWords) {
    bool wordMatched = false;
    for (final fw in allNormalizedFieldWords) {
      if (fw.contains(qw) || qw.contains(fw)) {
        wordMatched = true;
        break;
      }
    }
    // Fallback: search the query word in the raw combined text
    if (!wordMatched && combinedFieldTextLower.contains(qw)) {
      wordMatched = true;
    }
    if (!wordMatched) {
      return false; // This query word wasn't found anywhere
    }
  }
  return true;
}

// Provider to fetch all searchable entities (Jobs, Workers, Companies)
final searchResultsProvider = Provider.autoDispose<Map<String, List<Map<String, dynamic>>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  final filters = ref.watch(searchFiltersProvider);
  final allPosts = ref.watch(unifiedFeedProvider).value ?? [];
  
  if (query.isEmpty && filters.isEmpty) {
    final workers = ref.watch(workerListProvider).value ?? [];
    final companies = ref.watch(companyListProvider).value ?? [];
    return {
      'jobs': allPosts,
      'workers': workers,
      'companies': companies,
    };
  }

  // 1. Filter Jobs (from posts)
  final jobs = allPosts.where((post) {
    if (post['isJobPost'] != true) return false;
    
    // Text Query matches: jobTitle, companyName, text/description, location, subLocation, jobCategory, skills
    final title = (post['jobTitle'] ?? '').toString();
    final companyName = (post['companyName'] ?? '').toString();
    final text = (post['text'] ?? post['description'] ?? '').toString();
    final loc = (post['location'] ?? '').toString();
    final subLoc = (post['subLocation'] ?? '').toString();
    final category = (post['jobCategory'] ?? post['category'] ?? '').toString();
    final List<String> skillsList = post['skills'] is List 
        ? List<String>.from(post['skills']) 
        : [ (post['skills'] ?? post['jobSkills'] ?? '').toString() ];

    bool matchesQuery = _matchesSearchQuery(query, [
      title,
      companyName,
      text,
      loc,
      subLoc,
      category,
      ...skillsList,
    ]);
    
    if (!matchesQuery) return false;

    // Advanced Filters
    if (filters.skillType != null && (post['jobCategory'] ?? post['category'] ?? '') != filters.skillType) return false;
    if (filters.location != null && !post['location'].toString().toLowerCase().contains(filters.location!.toLowerCase())) return false;
    if (filters.subLocation != null && !post['subLocation'].toString().toLowerCase().contains(filters.subLocation!.toLowerCase())) return false;
    if (filters.minExperience != null && (int.tryParse(post['jobExperience']?.toString() ?? '0') ?? 0) < filters.minExperience!) return false;
    if (filters.jobType != null && post['jobType'] != filters.jobType) return false;

    return true;
  }).toList();

  // 2. Filter Workers & Companies
  final workers = ref.watch(workerListProvider).value ?? [];
  final filteredWorkers = workers.where((w) {
    final name = (w['name'] ?? '').toString();
    final bio = (w['bio'] ?? '').toString();
    final loc = (w['location'] ?? '').toString();
    final subLoc = (w['subLocation'] ?? '').toString();
    final category = (w['jobCategory'] ?? '').toString();
    final List<String> skillsList = w['skills'] is List ? List<String>.from(w['skills']) : [];
    final List<String> titlesList = w['jobTitles'] is List ? List<String>.from(w['jobTitles']) : [];

    bool matchesQuery = _matchesSearchQuery(query, [
      name,
      bio,
      loc,
      subLoc,
      category,
      ...skillsList,
      ...titlesList,
    ]);
    
    if (!matchesQuery) return false;

    // Advanced Filters (Workers)
    if (filters.skillType != null && !(w['skills'] as List? ?? []).contains(filters.skillType)) return false;
    if (filters.location != null && !w['location'].toString().toLowerCase().contains(filters.location!.toLowerCase())) return false;
    if (filters.minExperience != null && (int.tryParse(w['experience']?.toString() ?? '0') ?? 0) < filters.minExperience!) return false;

    return true;
  }).toList();

  final companies = ref.watch(companyListProvider).value ?? [];
  final filteredCompanies = companies.where((c) {
    final name = (c['name'] ?? c['companyName'] ?? '').toString();
    final contactPerson = (c['contactPersonName'] ?? '').toString();
    final bio = (c['bio'] ?? c['description'] ?? '').toString();
    final loc = (c['location'] ?? '').toString();
    final officeAddr = (c['officeAddress'] ?? '').toString();
    final bizType = (c['businessType'] ?? '').toString();
    final subType = (c['hirerSubType'] ?? '').toString();

    bool matchesQuery = _matchesSearchQuery(query, [
      name,
      contactPerson,
      bio,
      loc,
      officeAddr,
      bizType,
      subType,
    ]);
    
    if (!matchesQuery) return false;

    // Advanced Filters (Companies)
    if (filters.location != null && !c['location'].toString().toLowerCase().contains(filters.location!.toLowerCase())) return false;

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
