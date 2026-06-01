import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/hadith.dart';

class HadithService {
  HadithService._();
  static final HadithService instance = HadithService._();

  Future<List<HadithBook>> getBooks() async {
    final response = await http
        .get(Uri.parse('${AppEnv.hadithBaseUrl}/books'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar kitab hadis (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    if (data is! List) {
      throw Exception('Format response daftar kitab hadis tidak valid');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(HadithBook.fromMap)
        .toList(growable: false);
  }

  Future<HadithPage> getHadiths({
    required String bookId,
    required int start,
    required int end,
  }) async {
    final response = await http
        .get(
          Uri.parse('${AppEnv.hadithBaseUrl}/books/$bookId?range=$start-$end'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil hadis (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Format response hadis tidak valid');
    }

    return HadithPage.fromMap(data);
  }

  Future<Hadith> getHadithDetail({
    required String bookId,
    required int number,
  }) async {
    final response = await http
        .get(Uri.parse('${AppEnv.hadithBaseUrl}/books/$bookId/$number'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil detail hadis (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];

    if (data is! Map<String, dynamic> || data['contents'] is! Map) {
      throw Exception('Format response detail hadis tidak valid');
    }

    return Hadith.fromMap(Map<String, dynamic>.from(data['contents'] as Map));
  }
}
