import 'package:flutter/material.dart';

class SaranKesanController extends ChangeNotifier {
  final String kelas = "IF-E";
  final List<Map<String, String>> anggota = [
    {"nama": "Muhammad Syahrial Abidin", "nim": "123230027"},
    {"nama": "Reza Rasendriya Adi Putra", "nim": "123230030"},
  ];

  final String saran = 
      "Saran kami, mungkin ke depannya beban proyek bisa lebih diseimbangkan dengan waktu yang tersedia. Proyek TPM sangat menarik dan relevan, namun cukup sulit untuk diselesaikan secara maksimal dalam waktu yang terbatas, apalagi bersamaan dengan tugas dari mata kuliah lain.";

  final String kesan = 
      "Kesan kami, mata kuliah TPM ini cukup menantang dan kadang terasa cukup berat. Kami dituntut untuk memahami banyak hal dalam waktu singkat. Walaupun begitu, mata kuliah ini tetap memberikan pengalaman yang sangat berguna, terutama dalam melatih kemampuan berpikir dan praktik langsung.";
}