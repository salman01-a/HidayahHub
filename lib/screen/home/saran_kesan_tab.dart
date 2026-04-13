import 'package:flutter/material.dart';

class SaranKesanTab extends StatefulWidget {
  const SaranKesanTab({super.key});

  @override
  State<SaranKesanTab> createState() => _SaranKesanTabState();
}

class _SaranKesanTabState extends State<SaranKesanTab> {
  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();
  final _saranController = TextEditingController();
  final _kesanController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _kelasController.dispose();
    _saranController.dispose();
    _kesanController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_namaController.text.trim().isEmpty ||
        _saranController.text.trim().isEmpty ||
        _kesanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, saran, dan kesan wajib diisi')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terima kasih, saran dan kesan berhasil dikirim.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _saranController.clear();
    _kesanController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Saran dan Kesan Mata Kuliah TPM',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        _field('Nama', _namaController),
        const SizedBox(height: 10),
        _field('Kelas / NIM (opsional)', _kelasController),
        const SizedBox(height: 10),
        _field('Saran', _saranController, maxLines: 4),
        const SizedBox(height: 10),
        _field('Kesan', _kesanController, maxLines: 4),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6C5D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kirim'),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
