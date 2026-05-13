import 'dart:convert';
import 'package:http/http.dart' as http;

class PrivacyApiService {
  // Base URL for REST API. Change to 10.0.2.2 for Android Emulator if needed.
  static const String baseUrl = 'http://localhost:5000/api';

  // 1. Fetch Privacy Settings
  static Future<Map<String, dynamic>> getPrivacySettings(String userId) async {
    final url = Uri.parse('$baseUrl/privacy-settings/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load privacy settings: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // 2. Update Privacy Settings
  static Future<void> updatePrivacySettings({
    required String userId,
    required bool publicProfile,
    required bool showLocation,
    required bool showPhoneNumber,
    required bool showEmail,
  }) async {
    final url = Uri.parse('$baseUrl/privacy-settings');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'publicProfile': publicProfile,
          'showLocation': showLocation,
          'showPhoneNumber': showPhoneNumber,
          'showEmail': showEmail,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update privacy settings: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // 3. Fetch Filtered Profile Data
  static Future<Map<String, dynamic>> getFilteredProfile({
    required String targetUid,
    required String viewerUid,
  }) async {
    final url = Uri.parse('$baseUrl/profile/$targetUid?viewerUid=$viewerUid');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load profile data: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // 4. Establish Verified Connection
  static Future<void> verifyContact({
    required String user1,
    required String user2,
  }) async {
    final url = Uri.parse('$baseUrl/contacts/verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user1': user1, 'user2': user2}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify contact: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // 5. Fetch Verification Documents
  static Future<List<Map<String, dynamic>>> getVerificationDocs(String userId) async {
    final url = Uri.parse('$baseUrl/verification-docs/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Failed to load verification docs: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // 6. Upload Verification Document
  static Future<void> uploadVerificationDoc({
    required String userId,
    required String documentName,
  }) async {
    final url = Uri.parse('$baseUrl/verification-docs/upload');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'documentName': documentName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload doc: ${response.body}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}
