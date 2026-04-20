import 'package:flutter/material.dart';

import '../../controllers/saran_kesan_controller.dart';

class SaranKesanView extends StatefulWidget {
  const SaranKesanView({super.key});

  @override
  State<SaranKesanView> createState() => _SaranKesanViewState();
}

class _SaranKesanViewState extends State<SaranKesanView> {
  late final SaranKesanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SaranKesanController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final validation = _controller.validate();
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terima kasih, saran dan kesan berhasil dikirim.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _controller.clearAfterSubmit();
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
        _field('Nama', _controller.namaController),
        const SizedBox(height: 10),
        _field('Kelas / NIM (opsional)', _controller.kelasController),
        const SizedBox(height: 10),
        _field('Saran', _controller.saranController, maxLines: 4),
        const SizedBox(height: 10),
        _field('Kesan', _controller.kesanController, maxLines: 4),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A6C5D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
