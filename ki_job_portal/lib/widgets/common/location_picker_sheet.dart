import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';

class LocationPickerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  const LocationPickerSheet({super.key, required this.onLocationSelected});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _onSearch(String val) async {
    if (val.length < 3) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await LocationService.searchPlaces(val);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Select Location",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Search city, area or street...",
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_results.isEmpty && _searchController.text.length >= 3)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No results found"),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(color: theme.dividerColor.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final res = _results[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      res['description'],
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      widget.onLocationSelected(res);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
