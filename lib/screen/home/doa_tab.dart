import 'package:flutter/material.dart';

import '../../models/doa.dart';
import '../../services/doa_service.dart';
import 'shared_widgets.dart';

class DoaTab extends StatefulWidget {
  const DoaTab({super.key});

  @override
  State<DoaTab> createState() => _DoaTabState();
}

class _DoaTabState extends State<DoaTab> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<DoaItem>> _doaFuture;

  @override
  void initState() {
    super.initState();
    _doaFuture = DoaService.instance.getDoaList();
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
              hintText: 'Cari doa atau grup doa...',
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
          child: FutureBuilder<List<DoaItem>>(
            future: _doaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorPane(error: snapshot.error.toString());
              }

              final query = _searchController.text.trim().toLowerCase();
              final allDoa = snapshot.data ?? const <DoaItem>[];
              final items = query.isEmpty
                  ? allDoa
                  : allDoa
                        .where(
                          (e) =>
                              e.title.toLowerCase().contains(query) ||
                              e.group.toLowerCase().contains(query) ||
                              e.translation.toLowerCase().contains(query),
                        )
                        .toList(growable: false);

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _doaFuture = DoaService.instance.getDoaList());
                  await _doaFuture;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doa = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        title: Text(
                          doa.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: Text(
                          doa.group,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        children: [
                          Text(
                            doa.arabic,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, height: 1.6, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Text(doa.latin, style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 8),
                          Text(doa.translation),
                          const SizedBox(height: 8),
                          Text(
                            doa.reference,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
