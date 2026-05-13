import 'dart:convert';
import 'package:http/http.dart' as http;

/// Translates text using the MyMemory free API (no API key needed for basic use).
/// Supports English → Hindi and Hindi → English.
class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  /// Translates [text] from [sourceLang] to [targetLang].
  /// langCodes: 'en', 'hi'
  /// Returns the translated text, or the original text on failure.
  static Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    if (text.trim().isEmpty) return text;
    if (sourceLang == targetLang) return text;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$sourceLang|$targetLang',
        'de': 'kijobportal@app.com', // optional contact for higher quota
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translated = data['responseData']?['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty) {
          return translated;
        }
      }
    } catch (_) {
      // Silently fail — return original
    }
    return text;
  }
}
