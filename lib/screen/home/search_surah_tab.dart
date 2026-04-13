import 'package:flutter/material.dart';

import '../../models/surah.dart';
import '../../services/equran_service.dart';
import 'shared_widgets.dart';

class SearchSurahTab extends StatefulWidget {
  const SearchSurahTab({super.key});

  @override
  State<SearchSurahTab> createState() => _SearchSurahTabState();
}

class _SearchSurahTabState extends State<SearchSurahTab> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Surah>> _surahFuture;

  @override
  void initState() {
    super.initState();
    _surahFuture = EQuranService.instance.getSurahList();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari surah (nama latin/arab/arti/nomor)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Surah>>(
            future: _surahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorPane(error: snapshot.error.toString());
              }

              final query = _searchController.text.trim().toLowerCase();
              final all = snapshot.data ?? const <Surah>[];
              final list = query.isEmpty
                  ? all
                  : all
                        .where(
                          (s) =>
                              s.namaLatin.toLowerCase().contains(query) ||
                              s.nama.toLowerCase().contains(query) ||
                              s.arti.toLowerCase().contains(query) ||
                              '${s.nomor}'.contains(query),
                        )
                        .toList(growable: false);

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: list.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => SurahCard(surah: list[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
