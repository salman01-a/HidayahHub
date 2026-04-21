import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screen/splash_page.dart';
// import 'screen/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
    // const MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   home: HomePage(userName: "ini coba coba"),
    // ),
  );
}
