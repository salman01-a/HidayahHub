import 'package:flutter/material.dart';

import '../models/surah.dart';
import '../services/equran_service.dart';

class SearchSurahController extends ChangeNotifier {
  Future<List<Surah>>? _surahFuture;
  String query = '';

  Future<List<Surah>> get surahFuture {
    _surahFuture ??= EQuranService.instance.getSurahList();
    return _surahFuture!;
  }

  void setQuery(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  List<Surah> filtered(List<Surah> allSurah) {
    if (query.isEmpty) return allSurah;
    return allSurah
        .where(
          (s) =>
              s.namaLatin.toLowerCase().contains(query) ||
              s.nama.toLowerCase().contains(query) ||
              s.arti.toLowerCase().contains(query) ||
              '${s.nomor}'.contains(query),
        )
        .toList(growable: false);
  }

  Future<void> refresh() async {
    _surahFuture = EQuranService.instance.getSurahList();
    notifyListeners();
    await _surahFuture;
  }
}
