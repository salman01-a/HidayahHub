import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hidayahhub/services/notification_service.dart';
import 'screen/splash_page.dart';
// import 'screen/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.initialize();
  // Load file .env
  await dotenv.load(fileName: '.env', isOptional: true);

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
    // const MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   home: HomePage(userName: "ini coba coba"),
    // ),
  );
}
