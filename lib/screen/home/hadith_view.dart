import 'package:flutter/material.dart';

import '../../controllers/hadith_controller.dart';
import '../../models/hadith.dart';

class HadithView extends StatefulWidget {
  const HadithView({super.key});

  @override
  State<HadithView> createState() => _HadithViewState();
}

class _HadithViewState extends State<HadithView> {
  late final HadithController _controller;
  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _deepTeal = Color(0xFF0F5A4E);

  @override
  void initState() {
    super.initState();
    _controller = HadithController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {
      if (_searchController.text != _controller.query) {
        _searchController.text = _controller.query;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryTeal),
      );
    }

    if (_controller.error != null && _controller.currentPage == null) {
      return _ErrorState(
        error: _controller.error!,
        onRetry: _controller.refresh,
      );
    }

    final hadiths = _controller.filteredHadiths;

    return RefreshIndicator(
      color: _primaryTeal,
      onRefresh: _controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: hadiths.length + 2,
        separatorBuilder: (_, index) {
          if (index == 0) return const SizedBox(height: 12);
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader();
          if (index == hadiths.length + 1) return _buildFooter(hadiths.isEmpty);

          final hadith = hadiths[index - 1];
          return _HadithCard(
            hadith: hadith,
            bookName: _controller.currentPage?.bookName ?? 'HR. Hadis',
            onTap: () => _showHadithDetail(hadith),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final pageData = _controller.currentPage;
    final total =
        _controller.selectedBook?.available ?? pageData?.available ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepTeal, _primaryTeal, Color(0xFF34A39B)],
            ),
            boxShadow: [
              BoxShadow(
                color: _deepTeal.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hadis Shahih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Baca hadis dari Shahih Bukhari dan Shahih Muslim dengan terjemahan Indonesia.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PillStat(label: 'Kitab', value: pageData?.bookName ?? '-'),
                  _PillStat(label: 'Total', value: total.toString()),
                  _PillStat(
                    label: 'Range',
                    value:
                        '${_controller.startNumber}-${_controller.endNumber}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildBookSelector(),
        const SizedBox(height: 12),
        _buildSearchField(),
        if (_controller.isPageLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            color: _primaryTeal,
            backgroundColor: Color(0xFFE7F2EF),
          ),
        ],
        if (_controller.error != null && _controller.currentPage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: _controller.error!),
        ],
      ],
    );
  }

  Widget _buildBookSelector() {
    if (_controller.books.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _controller.books
          .map((book) {
            final selected = book.id == _controller.selectedBookId;
            return ChoiceChip(
              selected: selected,
              onSelected: _controller.isPageLoading
                  ? null
                  : (_) {
                      _controller.selectBook(book.id);
                    },
              showCheckmark: false,
              avatar: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.menu_book_outlined,
                size: 18,
                color: selected ? Colors.white : _primaryTeal,
              ),
              label: Text(book.name.replaceFirst('HR. ', '')),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF24344A),
                fontWeight: FontWeight.w800,
              ),
              selectedColor: _primaryTeal,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? _primaryTeal : const Color(0xFFDCE6EC),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _controller.setQuery,
      decoration: InputDecoration(
        hintText: 'Cari nomor atau terjemahan di halaman ini...',
        prefixIcon: const Icon(Icons.search_rounded, color: _primaryTeal),
        suffixIcon: _controller.query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _controller.setQuery('');
                },
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Bersihkan pencarian',
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildFooter(bool isEmpty) {
    if (_controller.currentPage == null && _controller.isPageLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: _primaryTeal)),
      );
    }

    return Column(
      children: [
        if (isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE6EC)),
            ),
            child: const Text(
              'Tidak ada hadis yang cocok di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF647377),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _controller.canGoPrevious && !_controller.isPageLoading
                    ? () {
                        _controller.previousPage();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deepTeal,
                  side: const BorderSide(color: Color(0xFFD0E5DF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE6EC)),
              ),
              child: Text(
                '${_controller.page}',
                style: const TextStyle(
                  color: _primaryTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _controller.canGoNext && !_controller.isPageLoading
                    ? () {
                        _controller.nextPage();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Berikutnya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD8E7E4),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHadithDetail(Hadith hadith) {
    final bookName = _controller.currentPage?.bookName ?? 'HR. Hadis';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE6EC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: const Color(0xFFE8F4F1),
                      child: Text(
                        '${hadith.number}',
                        style: const TextStyle(
                          color: _primaryTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$bookName No. ${hadith.number}',
                            style: const TextStyle(
                              color: Color(0xFF24344A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Teks Arab dan terjemahan Indonesia',
                            style: TextStyle(
                              color: Color(0xFF647377),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  hadith.arabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.75,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE6EC)),
                  ),
                  child: Text(
                    hadith.translation,
                    style: const TextStyle(
                      color: Color(0xFF24344A),
                      height: 1.55,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HadithCard extends StatelessWidget {
  final Hadith hadith;
  final String bookName;
  final VoidCallback onTap;

  const _HadithCard({
    required this.hadith,
    required this.bookName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE6EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF082B2A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${hadith.number}',
                    style: const TextStyle(
                      color: Color(0xFF1A7F6D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$bookName No. ${hadith.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24344A),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              hadith.arabic,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hadith.translation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final String value;

  const _PillStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D28B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFCBA052)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A5A16),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE8F4F1),
              child: Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFF1A7F6D),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hadis belum bisa dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF24344A),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF647377), height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7F6D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
