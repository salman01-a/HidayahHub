import 'package:flutter/material.dart';

import '../../controllers/quran_controller.dart';
import '../../models/surah.dart';
import 'shared_widgets.dart';

class QuranTab extends StatefulWidget {
  const QuranTab({super.key});

  @override
  State<QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<QuranTab> {
  late final QuranController _controller;

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
        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: surahList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => SurahCard(surah: surahList[index]),
          ),
        );
      },
    );
  }
}
