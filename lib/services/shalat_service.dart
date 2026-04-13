import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/shalat_schedule.dart';

class ShalatService {
  ShalatService._();
  static final ShalatService instance = ShalatService._();

  static const String _base = 'https://equran.id/api/v2/shalat';

  Future<List<String>> getProvinsi() async {
    final response = await http
        .get(Uri.parse('$_base/provinsi'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat provinsi (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>?;
    if (data == null) return const [];
    return data.whereType<String>().toList(growable: false);
  }

  Future<List<String>> getKabkota(String provinsi) async {
    final response = await http
        .post(
          Uri.parse('$_base/kabkota'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'provinsi': provinsi}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat kabupaten/kota (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>?;
    if (data == null) return const [];
    return data.whereType<String>().toList(growable: false);
  }

  Future<MonthlyShalatSchedule> getJadwal({
    required String provinsi,
    required String kabkota,
    required int bulan,
    required int tahun,
  }) async {
    final response = await http
        .post(
          Uri.parse(_base),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'provinsi': provinsi,
            'kabkota': kabkota,
            'bulan': bulan,
            'tahun': tahun,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat jadwal sholat (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Format data jadwal sholat tidak valid');
    }

    return MonthlyShalatSchedule.fromMap(data);
  }
}
