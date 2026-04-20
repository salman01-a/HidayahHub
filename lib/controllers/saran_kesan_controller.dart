import 'package:flutter/material.dart';

class SaranKesanController extends ChangeNotifier {
  final namaController = TextEditingController();
  final kelasController = TextEditingController();
  final saranController = TextEditingController();
  final kesanController = TextEditingController();

  String? validate() {
    if (namaController.text.trim().isEmpty ||
        saranController.text.trim().isEmpty ||
        kesanController.text.trim().isEmpty) {
      return 'Nama, saran, dan kesan wajib diisi';
    }
    return null;
  }

  void clearAfterSubmit() {
    saranController.clear();
    kesanController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    namaController.dispose();
    kelasController.dispose();
    saranController.dispose();
    kesanController.dispose();
    super.dispose();
  }
}
