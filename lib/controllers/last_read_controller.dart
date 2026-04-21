import 'package:flutter/material.dart';

import '../models/surah.dart';
import '../services/equran_service.dart';
import '../services/surah_read_bookmark_service.dart';

class LastReadItem {
  final Surah surah;
  final int ayat;

  const LastReadItem({required this.surah, required this.ayat});
}

class LastReadController extends ChangeNotifier {
  Future<List<LastReadItem>>? _itemsFuture;

  Future<List<LastReadItem>> get itemsFuture {
    _itemsFuture ??= _loadItems();
    return _itemsFuture!;
  }

  Future<void> refresh() async {
    _itemsFuture = _loadItems();
    notifyListeners();
    await _itemsFuture;
  }

  Future<String> deleteBookmark(LastReadItem item) async {
    await SurahReadBookmarkService.instance.clearBookmark(item.surah.nomor);
    return 'Bookmark ${item.surah.namaLatin} dihapus.';
  }

  Future<List<LastReadItem>> _loadItems() async {
    final bookmarks = await SurahReadBookmarkService.instance.loadAllBookmarks();
    if (bookmarks.isEmpty) return const <LastReadItem>[];

    final surahList = await EQuranService.instance.getSurahList();
    final items = surahList
        .where((surah) => bookmarks.containsKey(surah.nomor))
        .map((surah) => LastReadItem(surah: surah, ayat: bookmarks[surah.nomor]!))
        .toList(growable: false)
      ..sort((a, b) => a.surah.nomor.compareTo(b.surah.nomor));

    return items;
  }
}
