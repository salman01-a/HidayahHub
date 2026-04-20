import 'package:shared_preferences/shared_preferences.dart';

class SurahReadBookmarkService {
  SurahReadBookmarkService._();
  static final SurahReadBookmarkService instance = SurahReadBookmarkService._();

  static const _prefix = 'surah_last_read_ayat_';

  Future<Map<int, int>> loadAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, int>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final surahNo = int.tryParse(key.substring(_prefix.length));
      final ayat = prefs.getInt(key);
      if (surahNo != null && ayat != null) {
        result[surahNo] = ayat;
      }
    }

    return result;
  }

  Future<int?> getBookmarkAyat(int surahNo) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$surahNo');
  }

  Future<void> saveBookmark({required int surahNo, required int ayat}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$surahNo', ayat);
  }

  Future<void> clearBookmark(int surahNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$surahNo');
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
