import 'db_helper.dart';
import 'package:sqflite/sqflite.dart';

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
  static const int _singletonRowId = 1;

  Future<void> save(HomePrayerPreference preference) async {
    final db = await DBHelper.instance.database;
    await db.insert('home_prayer_preferences', {
      'id': _singletonRowId,
      ...preference.toMap(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HomePrayerPreference?> load() async {
    final db = await DBHelper.instance.database;
    final rows = await db.query(
      'home_prayer_preferences',
      where: 'id = ?',
      whereArgs: [_singletonRowId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return HomePrayerPreference.fromMap(rows.first);
    }
    return null;
  }
}
