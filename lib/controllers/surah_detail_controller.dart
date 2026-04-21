import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/surah_detail.dart';
import '../services/equran_service.dart';
import '../services/surah_read_bookmark_service.dart';

class SurahDetailController extends ChangeNotifier {
  Future<SurahDetail>? _detailFuture;
  AudioPlayer? _audioPlayer;

  int? _playingAyat;
  bool _isPlaying = false;
  int? _bookmarkedAyat;
  bool _audioReady = false;
  bool _disposed = false;

  Future<SurahDetail>? get detailFuture => _detailFuture;
  int? get playingAyat => _playingAyat;
  bool get isPlaying => _isPlaying;
  int? get bookmarkedAyat => _bookmarkedAyat;

  Future<void> initialize(int surahNo) async {
    _detailFuture = EQuranService.instance.getSurahDetail(surahNo);
    _initAudioSafe();
    notifyListeners();
    await loadBookmark(surahNo);
  }

  Future<void> refresh(int surahNo) async {
    _detailFuture = EQuranService.instance.getSurahDetail(surahNo);
    _safeNotify();
    await _detailFuture;
  }

  Future<void> loadBookmark(int surahNo) async {
    final ayat = await SurahReadBookmarkService.instance.getBookmarkAyat(surahNo);
    if (_disposed) return;
    _bookmarkedAyat = ayat;
    _safeNotify();
  }

  Future<String?> toggleAudio(SurahAyat ayat) async {
    if (!_audioReady || _audioPlayer == null) {
      return 'Fitur audio belum aktif pada sesi ini. Tutup aplikasi lalu jalankan ulang.';
    }

    final url = ayat.preferredAudioUrl;
    if (url == null) {
      return 'Audio ayat belum tersedia.';
    }

    if (_playingAyat == ayat.nomorAyat && _isPlaying) {
      await _audioPlayer!.pause();
      return null;
    }

    if (_playingAyat == ayat.nomorAyat && !_isPlaying) {
      await _audioPlayer!.resume();
      return null;
    }

    try {
      await _audioPlayer!.stop();
      _playingAyat = ayat.nomorAyat;
      _safeNotify();
      await _audioPlayer!.play(UrlSource(url));
      return null;
    } on MissingPluginException {
      _audioReady = false;
      _playingAyat = null;
      _isPlaying = false;
      _safeNotify();
      return 'Plugin audio belum siap. Lakukan full restart aplikasi.';
    }
  }

  Future<String> markAsLastRead({
    required int surahNo,
    required SurahAyat ayat,
  }) async {
    final isSaved = await SurahReadBookmarkService.instance.toggleBookmark(
      surahNo: surahNo,
      ayat: ayat.nomorAyat,
    );

    if (_disposed) return '';
    _bookmarkedAyat = isSaved ? ayat.nomorAyat : null;
    _safeNotify();

    return isSaved
        ? 'Ayat ${ayat.nomorAyat} disimpan sebagai terakhir dibaca.'
        : 'Bookmark ayat ${ayat.nomorAyat} dihapus.';
  }

  void _initAudioSafe() {
    try {
      final player = AudioPlayer();
      player.onPlayerStateChanged.listen((state) {
        if (_disposed) return;
        _isPlaying = state == PlayerState.playing;
        _safeNotify();
      });

      player.onPlayerComplete.listen((_) {
        if (_disposed) return;
        _playingAyat = null;
        _isPlaying = false;
        _safeNotify();
      });

      _audioPlayer = player;
      _audioReady = true;
    } on MissingPluginException {
      _audioReady = false;
    } catch (_) {
      _audioReady = false;
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer?.dispose();
    super.dispose();
  }
}
