import 'package:flutter/material.dart';

import '../../models/surah.dart';
import 'surah_detail_view.dart';

class ErrorPane extends StatelessWidget {
  final String error;

  const ErrorPane({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Terjadi kendala saat memuat data.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SurahCard extends StatelessWidget {
  final Surah surah;

  const SurahCard({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF7FAFC)],
        ),
        border: Border.all(color: const Color(0xFFDCE6EC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2B40).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SurahDetailView(surah: surah)),
          );
        },
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE4F2EC),
          child: Text(
            '${surah.nomor}',
            style: const TextStyle(
              color: Color(0xFF0A4B45),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          surah.namaLatin,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          '${surah.tempatTurun} - ${surah.jumlahAyat} ayat | ${surah.arti}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              surah.nama,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A8E9B)),
          ],
        ),
      ),
    );
  }
}
