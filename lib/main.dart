import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ini coba coba dulu, nanti kalau sudah bisa baru dihapus di simpan di .env kalo bisa
  await Supabase.initialize(
    url: "https://czrrnknutaqqsvxozqam.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6cnJua251dGFxcXN2eG96cWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MjU2MDUsImV4cCI6MjA5MTIwMTYwNX0.B3zUmESP5vXI7okO_1Nxl_qSmcoKTgMTQVDyFAarerk ",
  );
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()),
  );
}
