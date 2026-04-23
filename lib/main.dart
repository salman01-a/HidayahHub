import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hidayahhub/services/notification_service.dart';
import 'screen/splash_page.dart';
// import 'screen/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e) {
    debugPrint('Gagal memuat .env: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Inisialisasi notifikasi gagal: $e');
  }

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
  );
}
