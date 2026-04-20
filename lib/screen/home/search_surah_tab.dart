import 'package:flutter/material.dart';

import '../../controllers/search_surah_controller.dart';
import '../../models/surah.dart';
import 'shared_widgets.dart';

class SearchSurahTab extends StatefulWidget {
  const SearchSurahTab({super.key});

  @override
  State<SearchSurahTab> createState() => _SearchSurahTabState();
}

class _SearchSurahTabState extends State<SearchSurahTab> {
  late final SearchSurahController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SearchSurahController();
    _controller.addListener(_onControllerChanged);
    _searchController.addListener(
      () => _controller.setQuery(_searchController.text),
    );
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
            future: _controller.surahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorPane(error: snapshot.error.toString());
              }

              final all = snapshot.data ?? const <Surah>[];
              final list = _controller.filtered(all);

              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: list.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      SurahCard(surah: list[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
