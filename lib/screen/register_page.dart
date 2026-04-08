import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green[700]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Daftar Akun Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const Text(
                'Mulai perjalanan tadarus dan hafalan Anda hari ini.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Input Nama Lengkap
              _buildInputField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline,
                color: primaryGreen,
              ),
              const SizedBox(height: 20),

              // Input Email
              _buildInputField(
                label: 'Email',
                hint: 'Masukkan email aktif',
                icon: Icons.email_outlined,
                color: primaryGreen,
              ),
              const SizedBox(height: 20),

              // Input Password
              _buildInputField(
                label: 'Password',
                hint: 'Buat password minimal 6 karakter',
                icon: Icons.lock_outline,
                color: primaryGreen,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // Input Konfirmasi Password
              _buildInputField(
                label: 'Konfirmasi Password',
                hint: 'Ulangi password Anda',
                icon: Icons.lock_reset_outlined,
                color: primaryGreen,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Logika pendaftaran
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'DAFTAR SEKARANG',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Navigasi ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah punya akun?"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Masuk",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk merapikan kode TextField agar tidak duplikat
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: color),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
