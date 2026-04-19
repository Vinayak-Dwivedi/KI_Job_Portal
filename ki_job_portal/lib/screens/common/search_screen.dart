import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';
import '../../widgets/feed/post_card.dart';
import '../../core/theme/app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: _buildSearchBox(theme),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).clear();
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 12),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "ALL"),
            Tab(text: "JOBS"),
            Tab(text: "WORKERS"),
            Tab(text: "COMPANIES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsList(results, 'all', theme),
          _buildResultsList(results, 'jobs', theme),
          _buildResultsList(results, 'workers', theme),
          _buildResultsList(results, 'companies', theme),
        ],
      ),
    );
  }

  Widget _buildSearchBox(ThemeData theme) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
        onChanged: (val) => ref.read(searchQueryProvider.notifier).updateValue = val,
        decoration: InputDecoration(
          hintText: "Search jobs, skills, or people...",
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildResultsList(Map<String, List<Map<String, dynamic>>> results, String category, ThemeData theme) {
    List<Map<String, dynamic>> items = [];
    if (category == 'all') {
      items = [...results['jobs']!, ...results['workers']!, ...results['companies']!];
      // Sort mixed results by some relevance if needed, for now just interleaving
    } else {
      items = results[category]!;
    }

    if (items.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        // Handle Posts (Jobs)
        if (item.containsKey('isJobPost') || item.containsKey('text')) {
          return PostCard(post: item);
        }
        
        // Handle User Profiles (Workers/Companies)
        return _buildUserResultTile(item, theme);
      },
    );
  }

  Widget _buildUserResultTile(Map<String, dynamic> user, ThemeData theme) {
    final isWorker = user['role'] == 'worker';
    final name = (user['name'] ?? user['companyName'] ?? user['contactPersonName'] ?? 'No Name').toString();
    final sub = isWorker 
        ? (user['skills'] as List? ?? []).join(' • ')
        : (user['businessType'] ?? 'Employer').toString();
    final photo = user['profilePhotoUrl'] ?? user['logoUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
            image: (photo != null && photo.isNotEmpty)
                ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                : null,
          ),
          child: (photo == null || photo.isEmpty)
              ? Icon(isWorker ? Icons.person_rounded : Icons.business_rounded, color: Colors.grey)
              : null,
        ),
        title: Text(
          name,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          sub,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        onTap: () {
          final role = user['role'] ?? (isWorker ? 'worker' : 'employer');
          context.push('/public-profile/${user['uid']}/$role');
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No matching results found.",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search terms.",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
