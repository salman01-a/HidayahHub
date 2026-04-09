import 'package:flutter/material.dart';
import 'screen/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
  );
}
