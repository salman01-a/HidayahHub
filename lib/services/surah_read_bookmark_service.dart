import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class SurahReadBookmarkService {
  SurahReadBookmarkService._();
  static final SurahReadBookmarkService instance = SurahReadBookmarkService._();

  Future<Map<int, int>> loadAllBookmarks() async {
    final db = await DBHelper.instance.database;
    final result = <int, int>{};
    final latestRows = await db.query('surah_read_bookmarks');
    for (final row in latestRows) {
      final surahNo = row['surah_no'];
      final ayat = row['ayat'];
      if (surahNo is int && ayat is int) {
        result[surahNo] = ayat;
      }
    }

    return result;
  }


  Future<int?> getBookmarkAyat(int surahNo) async {
    final db = await DBHelper.instance.database;
    final rows = await db.query(
      'surah_read_bookmarks',
      columns: ['ayat'],
      where: 'surah_no = ?',
      whereArgs: [surahNo],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ayat = rows.first['ayat'];
    return ayat is int ? ayat : null;
  }

  Future<void> saveBookmark({required int surahNo, required int ayat}) async {
    final db = await DBHelper.instance.database;
    await db.insert('surah_read_bookmarks', {
      'surah_no': surahNo,
      'ayat': ayat,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearBookmark(int surahNo) async {
    final db = await DBHelper.instance.database;
    await db.delete(
      'surah_read_bookmarks',
      where: 'surah_no = ?',
      whereArgs: [surahNo],
    );
  }

  Future<bool> toggleBookmark({required int surahNo, required int ayat}) async {
    final current = await getBookmarkAyat(surahNo);
    if (current == ayat) {
      await clearBookmark(surahNo);
      return false;
    }

    await saveBookmark(surahNo: surahNo, ayat: ayat);
    return true;
  }
}
