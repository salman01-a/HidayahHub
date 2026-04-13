import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/surah.dart';

class EQuranService {
  EQuranService._();
  static final EQuranService instance = EQuranService._();

  static const String _baseUrl = 'https://equran.id/api/v2';

  Future<List<Surah>> getSurahList() async {
    final uri = Uri.parse('$_baseUrl/surat');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data surat (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    if (data is! List) {
      throw Exception('Format response API tidak valid');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Surah.fromMap)
        .toList(growable: false);
  }
}
