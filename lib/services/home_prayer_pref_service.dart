import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HomePrayerPreference {
  final String provinsi;
  final String kabkota;
  final int bulan;
  final int tahun;
  final String zona;

  const HomePrayerPreference({
    required this.provinsi,
    required this.kabkota,
    required this.bulan,
    required this.tahun,
    required this.zona,
  });

  Map<String, dynamic> toMap() {
    return {
      'provinsi': provinsi,
      'kabkota': kabkota,
      'bulan': bulan,
      'tahun': tahun,
      'zona': zona,
    };
  }

  factory HomePrayerPreference.fromMap(Map<String, dynamic> map) {
    return HomePrayerPreference(
      provinsi: map['provinsi'] as String? ?? '-',
      kabkota: map['kabkota'] as String? ?? '-',
      bulan: map['bulan'] as int? ?? DateTime.now().month,
      tahun: map['tahun'] as int? ?? DateTime.now().year,
      zona: map['zona'] as String? ?? 'WIB',
    );
  }
}

class HomePrayerPrefService {
  HomePrayerPrefService._();
  static final HomePrayerPrefService instance = HomePrayerPrefService._();

  static const _prefKey = 'home_prayer_preference_v1';

  Future<void> save(HomePrayerPreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(preference.toMap());
    await prefs.setString(_prefKey, encoded);
  }

  Future<HomePrayerPreference?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return HomePrayerPreference.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }
}
