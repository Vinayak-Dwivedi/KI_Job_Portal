import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _nominatimReverseUrl = "https://nominatim.openstreetmap.org/reverse";
  static const String _nominatimSearchUrl = "https://nominatim.openstreetmap.org/search";
  static const String _userAgent = "job-portal-app";

  /// 🛰️ Get User Coordinates using GPS
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permissions are denied.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permissions are permanently denied.");
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("Error getting current location: $e");
      return null;
    }
  }

  /// 🌍 Reverse Geocoding (Nominatim API)
  static Future<Map<String, dynamic>?> getLocationFromCoordinates(double lat, double lng) async {
    try {
      final url = "$_nominatimReverseUrl?format=json&lat=$lat&lon=$lng&addressdetails=1";
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Extract city with priority
          String city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? 'Unknown City';
          String state = address['state'] ?? '';
          
          // Extract sub-location
          String? subLocation = address['suburb'] ?? address['neighbourhood'] ?? address['road'] ?? address['subdivision'];
          
          // Fallback: If sub-location is null, use city
          subLocation ??= city;

          String fullLocation = state.isNotEmpty ? "$city, $state" : city;

          return {
            'city': city,
            'state': state,
            'fullLocation': fullLocation,
            'subLocation': subLocation,
            'latitude': lat,
            'longitude': lng,
          };
        }
      }
    } catch (e) {
      debugPrint("Reverse Geocoding Error: $e");
    }
    return null;
  }

  /// 🔍 Autocomplete using Nominatim Search API (Bonus)
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    try {
      // Nominatim Search API
      final url = "$_nominatimSearchUrl?q=$query&format=json&addressdetails=1&limit=5";
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>?;
          String city = address?['city'] ?? address?['town'] ?? address?['village'] ?? '';
          String sub = address?['suburb'] ?? address?['neighbourhood'] ?? address?['road'] ?? '';
          
          String description = item['display_name'] ?? '';
          
          return {
            'description': description,
            'city': city,
            'subLocation': sub.isNotEmpty ? sub : city,
            'lat': double.tryParse(item['lat'].toString()),
            'lon': double.tryParse(item['lon'].toString()),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Location Search Error: $e");
    }
    
    // Fallback if API fails (could use existing mocks or just empty)
    return [];
  }
}
