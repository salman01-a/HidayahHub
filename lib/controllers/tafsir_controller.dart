import 'package:flutter/material.dart';

import '../models/surah.dart';
import '../models/tafsir.dart';
import '../services/equran_service.dart';

class TafsirController extends ChangeNotifier {
  Future<List<Surah>>? _surahFuture;
  Future<TafsirSurah>? _tafsirFuture;

  int selectedSurahNo = 1;
  String query = '';

  Future<List<Surah>> get surahFuture {
    _surahFuture ??= EQuranService.instance.getSurahList();
    return _surahFuture!;
  }

  Future<TafsirSurah> get tafsirFuture {
    _tafsirFuture ??= EQuranService.instance.getTafsir(selectedSurahNo);
    return _tafsirFuture!;
  }

  void selectSurah(int nomorSurah) {
    if (nomorSurah == selectedSurahNo) return;
    selectedSurahNo = nomorSurah;
    _tafsirFuture = EQuranService.instance.getTafsir(selectedSurahNo);
    notifyListeners();
  }

  void setQuery(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  List<TafsirAyat> filtered(List<TafsirAyat> allTafsir) {
    if (query.isEmpty) return allTafsir;
    return allTafsir
        .where(
          (item) =>
              item.ayat.toString().contains(query) ||
              item.teks.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> refresh() async {
    _surahFuture = EQuranService.instance.getSurahList();
    _tafsirFuture = EQuranService.instance.getTafsir(selectedSurahNo);
    notifyListeners();
    await Future.wait([_surahFuture!, _tafsirFuture!]);
  }
}
