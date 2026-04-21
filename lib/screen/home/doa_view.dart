import 'package:flutter/material.dart';

import '../../controllers/doa_controller.dart';
import '../../models/doa.dart';
import 'shared_widgets.dart';

class DoaView extends StatefulWidget {
  const DoaView({super.key});

  @override
  State<DoaView> createState() => _DoaViewState();
}

class _DoaViewState extends State<DoaView> {
  late final DoaController _controller;
  final TextEditingController _searchController = TextEditingController();

  // Palette Hidayah Hub
  static const Color primaryTeal = Color(0xFF1A7F6D);

  @override
  void initState() {
    super.initState();
    _controller = DoaController();
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
    return FutureBuilder<List<DoaItem>>(
      future: _controller.doaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryTeal),
          );
        }
        if (snapshot.hasError) {
          return ErrorPane(error: snapshot.error.toString());
        }

        final allDoa = snapshot.data ?? const <DoaItem>[];
        final filtered = _controller.filtered(allDoa);

        return RefreshIndicator(
          color: primaryTeal,
          onRefresh: () async {
            await _controller.refresh();
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: filtered.length + 1,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 12)
                : const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _DoaHeader(
                  total: allDoa.length,
                  current: filtered.length,
                  searchController: _searchController,
                  onChanged: _controller.setQuery,
                );
              }

              final doa = filtered[index - 1];
              return _DoaExpansionCard(doa: doa);
            },
          ),
        );
      },
    );
  }
}

class _DoaHeader extends StatelessWidget {
  final int total;
  final int current;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;

  const _DoaHeader({
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
                color: const Color(0xFF0F5A4E).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kumpulan Doa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Temukan doa-doa harian untuk menemani aktivitas ibadahmu.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _PillStat(label: 'Total Doa', value: '$total'),
                  const SizedBox(width: 8),
                  _PillStat(label: 'Tampil', value: '$current'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Cari doa atau kategori...',
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

class _DoaExpansionCard extends StatelessWidget {
  final DoaItem doa;

  const _DoaExpansionCard({required this.doa});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFF1A7F6D),
            ),
          ),
          title: Text(
            doa.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF24344A),
            ),
          ),
          subtitle: Text(
            doa.group,
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
              doa.arabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              doa.latin,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doa.translation,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              doa.reference,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
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
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
