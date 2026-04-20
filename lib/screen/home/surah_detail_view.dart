import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/surah.dart';
import '../../models/surah_detail.dart';
import '../../services/equran_service.dart';
import '../../services/surah_read_bookmark_service.dart';

class SurahDetailView extends StatefulWidget {
  final Surah surah;

  const SurahDetailView({super.key, required this.surah});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  late Future<SurahDetail> _detailFuture;
  AudioPlayer? _audioPlayer;
  int? _playingAyat;
  bool _isPlaying = false;
  int? _bookmarkedAyat;
  bool _audioReady = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _targetKey = GlobalKey();
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = EQuranService.instance.getSurahDetail(widget.surah.nomor);
    _initAudioSafe();
    _loadBookmark();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _scrollToBookmark() {
    if (_bookmarkedAyat != null && !_hasScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_targetKey.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey.currentContext!,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
          _hasScrolled = true;
        }
      });
    }
  }

  void _initAudioSafe() {
    try {
      final player = AudioPlayer();
      player.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });
      player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _playingAyat = null;
          _isPlaying = false;
        });
      });

      _audioPlayer = player;
      _audioReady = true;
    } on MissingPluginException {
      _audioReady = false;
    } catch (_) {
      _audioReady = false;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _hasScrolled = false;
      _detailFuture = EQuranService.instance.getSurahDetail(widget.surah.nomor);
    });
    await _detailFuture;
  }

  Future<void> _loadBookmark() async {
    final ayat = await SurahReadBookmarkService.instance.getBookmarkAyat(
      widget.surah.nomor,
    );
    if (!mounted) return;
    setState(() {
      _bookmarkedAyat = ayat;
    });
  }

  Future<void> _toggleAudio(SurahAyat ayat) async {
    if (!_audioReady || _audioPlayer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fitur audio belum aktif pada sesi ini. Tutup aplikasi lalu jalankan ulang.',
          ),
        ),
      );
      return;
    }

    final url = ayat.preferredAudioUrl;
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio ayat belum tersedia.')),
      );
      return;
    }

    if (_playingAyat == ayat.nomorAyat && _isPlaying) {
      await _audioPlayer!.pause();
      return;
    }

    if (_playingAyat == ayat.nomorAyat && !_isPlaying) {
      await _audioPlayer!.resume();
      return;
    }

    try {
      await _audioPlayer!.stop();
      setState(() {
        _playingAyat = ayat.nomorAyat;
      });
      await _audioPlayer!.play(UrlSource(url));
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _audioReady = false;
        _playingAyat = null;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Plugin audio belum siap. Lakukan full restart aplikasi.',
          ),
        ),
      );
    }
  }

  Future<void> _markAsLastRead(SurahAyat ayat) async {
    final isSaved = await SurahReadBookmarkService.instance.toggleBookmark(
      surahNo: widget.surah.nomor,
      ayat: ayat.nomorAyat,
    );
    if (!mounted) return;
    setState(() {
      _bookmarkedAyat = isSaved ? ayat.nomorAyat : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? 'Ayat ${ayat.nomorAyat} disimpan sebagai terakhir dibaca.'
              : 'Bookmark ayat ${ayat.nomorAyat} dihapus.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EA),
      appBar: AppBar(
        title: Text(widget.surah.namaLatin),
        centerTitle: true,
        backgroundColor: const Color(0xFF194B4A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<SurahDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      'Gagal memuat detail surah.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Detail surah tidak ditemukan.'));
          }

          _scrollToBookmark();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              controller: _scrollController,
              cacheExtent: 5000,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: detail.ayat.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SurahHeader(
                    detail: detail,
                    bookmarkedAyat: _bookmarkedAyat,
                  );
                }

                if (index == 1) {
                  return const SizedBox(height: 10);
                }

                final ayat = detail.ayat[index - 2];
                final isThisBookmarked = _bookmarkedAyat == ayat.nomorAyat;

                return _AyatCard(
                  key: isThisBookmarked ? _targetKey : null,
                  ayat: ayat,
                  isPlaying: _playingAyat == ayat.nomorAyat && _isPlaying,
                  isBookmarked: isThisBookmarked,
                  onPlayTap: () => _toggleAudio(ayat),
                  onBookmarkTap: () => _markAsLastRead(ayat),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final SurahDetail detail;
  final int? bookmarkedAyat;

  const _SurahHeader({required this.detail, required this.bookmarkedAyat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D504E), Color(0xFF2B7A73)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF103532).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                _TagPill(label: detail.tempatTurun),
                const SizedBox(width: 8),
                _TagPill(label: '${detail.jumlahAyat} Ayat'),
                const Spacer(),
                Text(
                  '#${detail.nomor}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail.nama,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${detail.namaLatin} • ${detail.arti}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECE6D2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD2C8A7)),
            ),
            child: Column(
              children: const [
                Text(
                  'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    color: Color(0xFF3A352D),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'bismillaahir-rahmaanir-rahiim',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF456F6A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arti surah: ${detail.arti}',
            style: const TextStyle(color: Colors.white),
          ),
          if (bookmarkedAyat != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF173E3C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Terakhir dibaca: Ayat $bookmarkedAyat',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyatCard extends StatelessWidget {
  final SurahAyat ayat;
  final bool isPlaying;
  final bool isBookmarked;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmarkTap;

  const _AyatCard({
    super.key,
    required this.ayat,
    required this.isPlaying,
    required this.isBookmarked,
    required this.onPlayTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: isBookmarked ? const Color(0xFFFFFDF4) : const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBookmarked
              ? const Color(0xFFE0C86E)
              : const Color(0xFFDCD8C8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E3D2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFCFC6AD)),
                ),
                child: Text(
                  '${ayat.nomorAyat}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A5140),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: isPlaying ? 'Pause audio' : 'Play audio',
                onPressed: onPlayTap,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 26,
                  color: const Color(0xFF2A7A73),
                ),
              ),
              IconButton(
                tooltip: 'Tandai terakhir dibaca',
                onPressed: onBookmarkTap,
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked
                      ? const Color(0xFFB48B1D)
                      : const Color(0xFF7B7567),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ayat.teksArab,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 31,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2F2D2A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ayat.teksLatin,
            style: const TextStyle(
              color: Color(0xFF2A7A73),
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ayat.teksIndonesia,
            style: const TextStyle(
              color: Color(0xFF555555),
              height: 1.35,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
