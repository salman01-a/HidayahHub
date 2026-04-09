import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screen/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On desktop (Windows / macOS / Linux) initialize sqflite ffi.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage()),
  );
}
