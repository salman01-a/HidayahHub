import 'package:flutter/material.dart';

import '../../controllers/quran_controller.dart';
import '../../models/surah.dart';
import 'shared_widgets.dart';

class QuranView extends StatefulWidget {
  const QuranView({super.key});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  late final QuranController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = QuranController();
    _controller.addListener(_onControllerChanged);
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: _controller.surahFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorPane(error: snapshot.error.toString());
        }

        final surahList = snapshot.data ?? const <Surah>[];
        final filtered = _query.trim().isEmpty
            ? surahList
            : surahList
                  .where((surah) {
                    final q = _query.toLowerCase();
                    return surah.namaLatin.toLowerCase().contains(q) ||
                        surah.nama.toLowerCase().contains(q) ||
                        surah.arti.toLowerCase().contains(q) ||
                        surah.nomor.toString().contains(q);
                  })
                  .toList(growable: false);

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: filtered.length + 1,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 12)
                : const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _QuranHeader(
                  total: surahList.length,
                  current: filtered.length,
                  searchController: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                );
              }

              return SurahCard(surah: filtered[index - 1]);
            },
          ),
        );
      },
    );
  }
}

class _QuranHeader extends StatelessWidget {
  final int total;
  final int current;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;

  const _QuranHeader({
    required this.total,
    required this.current,
    required this.searchController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D3F66), Color(0xFF1E6A83), Color(0xFF339F8F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C395C).withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Baca Al Quran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Daftar surah lengkap dengan tampilan yang lebih fokus dan bersih.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PillStat(label: 'Total Surah', value: '$total'),
                  const SizedBox(width: 8),
                  _PillStat(label: 'Tampil', value: '$current'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Cari surah (nama latin, arab, arti, nomor)',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
