import 'package:flutter/material.dart';

import '../models/surah.dart';
import '../services/equran_service.dart';

class QuranController extends ChangeNotifier {
  Future<List<Surah>>? _surahFuture;

  Future<List<Surah>> get surahFuture {
    _surahFuture ??= EQuranService.instance.getSurahList();
    return _surahFuture!;
  }

  Future<void> refresh() async {
    _surahFuture = EQuranService.instance.getSurahList();
    notifyListeners();
    await _surahFuture;
  }
}
