import 'package:flutter/material.dart';

import '../../models/surah.dart';
import '../../services/equran_service.dart';
import 'shared_widgets.dart';

class QuranTab extends StatelessWidget {
  const QuranTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: EQuranService.instance.getSurahList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorPane(error: snapshot.error.toString());
        }

        final surahList = snapshot.data ?? const <Surah>[];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: surahList.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => SurahCard(surah: surahList[index]),
        );
      },
    );
  }
}
