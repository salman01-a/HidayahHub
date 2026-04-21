import 'package:flutter/material.dart';

class SaranKesanController extends ChangeNotifier {
  final String kelas = "IF-A";
  final List<Map<String, String>> anggota = [
    {"nama": "Salman Faris", "nim": "123230024"},
    {"nama": "Reza Rasendriya Adi Putra", "nim": "123230030"},
  ];

  final String saran = 
      "Saran kami untuk mata kuliah TPM adalah agar terus mengedepankan proyek berbasis studi kasus nyata seperti ini. Integrasi dengan API eksternal dan manajemen state sangat membantu kami dalam mempersiapkan diri ke industri.";

  final String kesan = 
      "Belajar di mata kuliah TPM sangat menantang namun memberikan kepuasan tersendiri. Kami belajar bagaimana membangun aplikasi yang tidak hanya fungsional secara teknis, tapi juga memiliki estetika UI/UX yang baik dan nyaman digunakan.";
}