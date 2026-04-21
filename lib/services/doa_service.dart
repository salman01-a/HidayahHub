import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/doa.dart';

class DoaService {
  DoaService._();
  static final DoaService instance = DoaService._();

  Future<List<DoaItem>> getDoaList() async {
    final response = await http
        .get(Uri.parse(AppEnv.doaUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data doa (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    if (data is! List) {
      throw Exception('Format response API doa tidak valid');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(DoaItem.fromMap)
        .toList(growable: false);
  }
}
