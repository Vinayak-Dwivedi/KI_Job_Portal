import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';

class EmployerWorkersScreen extends ConsumerStatefulWidget {
  const EmployerWorkersScreen({super.key});

  @override
  ConsumerState<EmployerWorkersScreen> createState() => _EmployerWorkersScreenState();
}

class _EmployerWorkersScreenState extends ConsumerState<EmployerWorkersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(searchResultsProvider);
    final workers = results['workers'] ?? [];
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Browse Workers', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, fontSize: 20)),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search Header ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(searchQueryProvider.notifier).updateValue = val,
              decoration: InputDecoration(
                hintText: 'Search skills (e.g. Welding, Plumbing)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    })
                  : IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () => context.push('/search')),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // ── Workers List ───────────────────────────────
          Expanded(
            child: workers.isEmpty && query.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return _buildWorkerCard(worker, theme);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker, ThemeData theme) {
    final skills = (worker['skills'] as List? ?? []);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => context.push('/profile/worker/${worker['id']}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: (worker['profilePhotoUrl'] != null && worker['profilePhotoUrl'].isNotEmpty)
                  ? NetworkImage(worker['profilePhotoUrl'])
                  : null,
                child: (worker['profilePhotoUrl'] == null || worker['profilePhotoUrl'].isEmpty)
                  ? const Icon(Icons.person, size: 30)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(worker['name'] ?? 'Worker', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        if (worker['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(worker['location'] ?? 'No location', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: skills.take(3).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(s, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.person_search_outlined, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          const Text('Find Skilled Karigars', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Search for skilled workers by name or skills. You can also apply filters for better results.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
