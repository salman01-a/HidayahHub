import 'package:flutter/material.dart';
import 'screen/splash_page.dart';
import 'screen/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ini di ubah dlu bntar buat gw run di chrome dlu
    // const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(userName: "ini coba coba"),
    ),
  );
}
