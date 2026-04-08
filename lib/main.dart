import 'package:flutter/material.dart';
import 'screen/login_page.dart';

void main() {
  // Tambahkan MaterialApp sebagai pembungkus utama
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()),
  );
}
