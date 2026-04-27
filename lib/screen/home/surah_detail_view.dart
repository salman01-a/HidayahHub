import 'package:flutter/material.dart';

import '../../controllers/surah_detail_controller.dart';
import '../../models/surah.dart';
import '../../models/surah_detail.dart';

class SurahDetailView extends StatefulWidget {
  final Surah surah;

  const SurahDetailView({super.key, required this.surah});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  late final SurahDetailController _controller;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayatKeys = <int, GlobalKey>{};
  bool _hasScrolled = false;
  bool _scrollingInProgress = false;
  int _scrollAttempts = 0;

  static const int _maxScrollAttempts = 8;
  static const double _estimatedItemHeight = 260;

  @override
  void initState() {
    super.initState();
    _controller = SurahDetailController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize(widget.surah.nomor);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  GlobalKey _keyForAyat(int nomorAyat) {
    return _ayatKeys.putIfAbsent(
      nomorAyat,
      () => GlobalObjectKey('ayat-$nomorAyat'),
    );
  }

  void _scrollToBookmark() {
    final bookmarkedAyat = _controller.bookmarkedAyat;
    if (bookmarkedAyat == null || _hasScrolled || _scrollingInProgress) return;

    _scrollingInProgress = true;
    _scrollAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScrollToBookmarkedAyat(bookmarkedAyat);
    });
  }

  Future<void> _tryScrollToBookmarkedAyat(int bookmarkedAyat) async {
    if (!mounted) return;

    final targetContext = _ayatKeys[bookmarkedAyat]?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
      if (!mounted) return;
      _hasScrolled = true;
      _scrollingInProgress = false;
      return;
    }

    if (_scrollAttempts >= _maxScrollAttempts || !_scrollController.hasClients) {
      _scrollingInProgress = false;
      return;
    }

    _scrollAttempts += 1;
    final targetIndex = bookmarkedAyat + 1;
    final roughOffset =
        (targetIndex * _estimatedItemHeight)
            .clamp(0.0, _scrollController.position.maxScrollExtent)
            .toDouble();

    await _scrollController.animateTo(
      roughOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScrollToBookmarkedAyat(bookmarkedAyat);
    });
  }

  Future<void> _reload() async {
    _hasScrolled = false;
    _scrollingInProgress = false;
    _scrollAttempts = 0;
    await _controller.refresh(widget.surah.nomor);
  }

  Future<void> _toggleAudio(SurahAyat ayat) async {
    final message = await _controller.toggleAudio(ayat);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _markAsLastRead(SurahAyat ayat) async {
    final message = await _controller.markAsLastRead(
      surahNo: widget.surah.nomor,
      ayat: ayat,
    );
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        future: _controller.detailFuture,
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
                    bookmarkedAyat: _controller.bookmarkedAyat,
                  );
                }

                if (index == 1) {
                  return const SizedBox(height: 10);
                }

                final ayat = detail.ayat[index - 2];
                final isThisBookmarked =
                    _controller.bookmarkedAyat == ayat.nomorAyat;

                return _AyatCard(
                  key: _keyForAyat(ayat.nomorAyat),
                  ayat: ayat,
                  isPlaying:
                      _controller.playingAyat == ayat.nomorAyat &&
                      _controller.isPlaying,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4F4D), Color(0xFF2A7A73)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF103532).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: Text(
              detail.nama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 34,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${detail.namaLatin} • ${detail.arti}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE5F2F0),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Arti surah: ${detail.arti}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (bookmarkedAyat != null) ...[
            const SizedBox(height: 10),
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
          Align(
            alignment: Alignment.centerRight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayat.teksArab,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 31,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2F2D2A),
                ),
              ),
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
