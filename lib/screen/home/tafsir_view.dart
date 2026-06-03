import 'package:flutter/material.dart';

import '../../controllers/tafsir_controller.dart';
import '../../models/surah.dart';
import '../../models/tafsir.dart';
import 'shared_widgets.dart';

class TafsirView extends StatefulWidget {
  const TafsirView({super.key});

  @override
  State<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<TafsirView> {
  late final TafsirController _controller;
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryTeal = Color(0xFF1A7F6D);

  @override
  void initState() {
    super.initState();
    _controller = TafsirController();
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
      builder: (context, surahSnapshot) {
        if (surahSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryTeal),
          );
        }
        if (surahSnapshot.hasError) {
          return ErrorPane(error: surahSnapshot.error.toString());
        }

        final surahList = surahSnapshot.data ?? const <Surah>[];

        return FutureBuilder<TafsirSurah>(
          future: _controller.tafsirFuture,
          builder: (context, tafsirSnapshot) {
            if (tafsirSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryTeal),
              );
            }
            if (tafsirSnapshot.hasError) {
              return ErrorPane(error: tafsirSnapshot.error.toString());
            }

            final tafsir = tafsirSnapshot.data;
            if (tafsir == null) {
              return const Center(child: Text('Data tafsir tidak ditemukan.'));
            }

            final filtered = _controller.filtered(tafsir.tafsir);

            return RefreshIndicator(
              color: primaryTeal,
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
                    return _TafsirHeader(
                      tafsir: tafsir,
                      surahList: surahList,
                      current: filtered.length,
                      selectedSurahNo: _controller.selectedSurahNo,
                      searchController: _searchController,
                      onSurahChanged: _controller.selectSurah,
                      onSearchChanged: _controller.setQuery,
                    );
                  }

                  final item = filtered[index - 1];
                  return _TafsirExpansionCard(tafsir: tafsir, item: item);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TafsirHeader extends StatelessWidget {
  final TafsirSurah tafsir;
  final List<Surah> surahList;
  final int current;
  final int selectedSurahNo;
  final TextEditingController searchController;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<String> onSearchChanged;

  const _TafsirHeader({
    required this.tafsir,
    required this.surahList,
    required this.current,
    required this.selectedSurahNo,
    required this.searchController,
    required this.onSurahChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSurah = surahList.where((surah) {
      return surah.nomor == selectedSurahNo;
    }).firstOrNull;

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
              colors: [Color(0xFF0F5A4E), Color(0xFF1A7F6D), Color(0xFF34A39B)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F5A4E).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tafsir Al Quran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${tafsir.namaLatin} - ${tafsir.arti}',
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.35,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  tafsir.deskripsi,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.42,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PillStat(label: 'Surah', value: '${tafsir.nomor}'),
                  _PillStat(label: 'Ayat', value: '${tafsir.jumlahAyat}'),
                  _PillStat(label: 'Tampil', value: '$current'),
                  _PillStat(label: 'Turun', value: tafsir.tempatTurun),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SurahPickerField(
          selectedSurah: selectedSurah,
          surahList: surahList,
          onChanged: onSurahChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari ayat atau isi tafsir...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF1A7F6D),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _SurahPickerField extends StatelessWidget {
  final Surah? selectedSurah;
  final List<Surah> surahList;
  final ValueChanged<int> onChanged;

  const _SurahPickerField({
    required this.selectedSurah,
    required this.surahList,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SurahPickerSheet(
          surahList: surahList,
          selectedSurahNo: selectedSurah?.nomor,
        );
      },
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah = selectedSurah;

    return InkWell(
      onTap: surahList.isEmpty ? null : () => _openPicker(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE6EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2B40).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                surah == null ? '-' : '${surah.nomor}',
                style: const TextStyle(
                  color: Color(0xFF1A7F6D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Surah',
                    style: TextStyle(
                      color: Color(0xFF6B7A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    surah == null
                        ? 'Data surah belum tersedia'
                        : '${surah.namaLatin} - ${surah.arti}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24344A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (surah != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${surah.tempatTurun} - ${surah.jumlahAyat} ayat',
                      style: const TextStyle(
                        color: Color(0xFFCBA052),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF1A7F6D),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahPickerSheet extends StatefulWidget {
  final List<Surah> surahList;
  final int? selectedSurahNo;

  const _SurahPickerSheet({
    required this.surahList,
    required this.selectedSurahNo,
  });

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.surahList
        : widget.surahList
              .where((surah) {
                final query = _query.toLowerCase();
                return surah.nomor.toString().contains(query) ||
                    surah.namaLatin.toLowerCase().contains(query) ||
                    surah.nama.toLowerCase().contains(query) ||
                    surah.arti.toLowerCase().contains(query);
              })
              .toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C7CF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Surah Tafsir',
                      style: TextStyle(
                        color: Color(0xFF24344A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, arti, atau nomor surah...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF1A7F6D),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final selected = surah.nomor == widget.selectedSurahNo;

                    return InkWell(
                      onTap: () => Navigator.pop(context, surah.nomor),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE8F4F1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1A7F6D)
                                : const Color(0xFFDCE6EC),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: selected
                                  ? const Color(0xFF1A7F6D)
                                  : const Color(0xFFE8F4F1),
                              child: Text(
                                '${surah.nomor}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1A7F6D),
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
                                    '${surah.namaLatin} - ${surah.arti}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF24344A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${surah.tempatTurun} - ${surah.jumlahAyat} ayat',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7A8A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              surah.nama,
                              style: const TextStyle(
                                color: Color(0xFF1A7F6D),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF1A7F6D),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TafsirExpansionCard extends StatelessWidget {
  final TafsirSurah tafsir;
  final TafsirAyat item;

  const _TafsirExpansionCard({required this.tafsir, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF1A7F6D),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8F4F1),
            child: Text(
              '${item.ayat}',
              style: const TextStyle(
                color: Color(0xFF1A7F6D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            'Tafsir Ayat ${item.ayat}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF24344A),
            ),
          ),
          subtitle: Text(
            tafsir.namaLatin,
            style: const TextStyle(
              color: Color(0xFFCBA052),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F7)),
            const SizedBox(height: 16),
            Text(
              item.teks,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.5,
                fontSize: 14,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
