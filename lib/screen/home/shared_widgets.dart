import 'package:flutter/material.dart';

import '../../models/surah.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDDF1EB),
          child: Text(
            '${surah.nomor}',
            style: const TextStyle(color: Color(0xFF0A4B45)),
          ),
        ),
        title: Text(
          surah.namaLatin,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${surah.tempatTurun} - ${surah.jumlahAyat} ayat | ${surah.arti}',
        ),
        trailing: Text(
          surah.nama,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
