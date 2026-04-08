import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green[700]!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Text(
                  'Selamat Datang di HidayahHub',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Input Username/Email
              Text(
                'Username atau Email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Masukkan username/email',
                  prefixIcon: Icon(Icons.email_outlined, color: primaryGreen),
                  // Border saat aktif (terfokus) menggunakan warna hijau
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                  // Border saat tidak aktif
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Password
              Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Masukkan password Anda',
                  prefixIcon: Icon(Icons.lock_outline, color: primaryGreen),
                  // Ikon untuk melihat password (visibility)
                  suffixIcon: Icon(
                    Icons.visibility_off_outlined,
                    color: primaryGreen.withOpacity(0.6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Lupa Password (Warna Hijau)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lupa Password?',
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Login (Full Width, Hijau)
              SizedBox(
                width: double.infinity,
                height: 55, // Tinggi tombol lebih nyaman ditekan
                child: ElevatedButton(
                  onPressed: () {
                    // Masukkan logika login Anda di sini
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryGreen, // Warna background tombol hijau
                    foregroundColor: Colors.white, // Warna teks putih
                    elevation: 5, // Berikan sedikit bayangan biar profesional
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MASUK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0, // Sedikit jarak antar huruf
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Daftar Sekarang",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
