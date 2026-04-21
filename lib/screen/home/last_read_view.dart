import 'package:flutter/material.dart';

import '../../controllers/last_read_controller.dart';
import 'surah_detail_view.dart';

class LastReadView extends StatefulWidget {
  const LastReadView({super.key});

  @override
  State<LastReadView> createState() => _LastReadViewState();
}

class _LastReadViewState extends State<LastReadView> {
  late final LastReadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LastReadController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteBookmark(LastReadItem item) async {
    final message = await _controller.deleteBookmark(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LastReadItem>>(
      future: _controller.itemsFuture,
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
                    'Gagal memuat data terakhir dibaca.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _controller.refresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data ?? const <LastReadItem>[];
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Belum ada data terakhir dibaca.\nBuka surah lalu tandai ayat sebagai terakhir dibaca.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8EE)),
                ),
                child: ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurahDetailView(surah: item.surah),
                      ),
                    );
                    if (!mounted) return;
                    await _controller.refresh();
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE4F2EC),
                    child: Text(
                      '${item.surah.nomor}',
                      style: const TextStyle(
                        color: Color(0xFF0A4B45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    item.surah.namaLatin,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Ayat terakhir: ${item.ayat} • ${item.surah.arti}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Hapus bookmark',
                    onPressed: () => _deleteBookmark(item),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
