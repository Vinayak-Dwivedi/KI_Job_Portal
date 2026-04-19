import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches active job categories from the 'job_categories' collection.
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('job_categories')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? 'Unknown')
          .where((name) => name != 'Unknown') // Filter out invalid data
          .toList();

      // Sort alphabetically for a better user experience
      categories.sort();
      
      return categories;
    } catch (e) {
      print("❌ ERROR in CategoryService.getCategories: $e");
      return []; // Return empty list on error to prevent crashes
    }
  }
}
