import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';

class ZakatService {
  ZakatService._();
  static final ZakatService instance = ZakatService._();

  Future<Map<String, dynamic>> getExchangeRates() async {

    final url = Uri.parse(AppEnv.exchangeRateUrl);
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['rates'] as Map<String, dynamic>;
    } else {
      throw Exception(
        'Gagal mengambil data kurs mata uang (${response.statusCode})',
      );
    }
  }
}
