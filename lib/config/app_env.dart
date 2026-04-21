import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String _read(String key, {String fallback = ''}) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return value;
  }

  static String get equranBaseUrl =>
      _read('EQURAN_BASE_URL', fallback: 'https://equran.id/api/v2');

  static String get doaUrl =>
      _read('DOA_URL', fallback: 'https://equran.id/api/doa');

  static String get overpassUrl => _read(
    'OVERPASS_URL',
    fallback: 'https://overpass-api.de/api/interpreter',
  );

  static String get nominatimReverseUrl => _read(
    'NOMINATIM_REVERSE_URL',
    fallback: 'https://nominatim.openstreetmap.org/reverse',
  );

  static String get geminiApiKey => _read('GEMINI_API_KEY');

  static void ensureRequired() {
    if (geminiApiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY belum diatur di file .env',
      );
    }
  }
}
