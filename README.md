Hidayah Hub - Asisten Spiritual Digital

**Hidayah Hub** adalah aplikasi mobile berbasis Flutter yang dirancang sebagai asisten spiritual digital terpadu. Aplikasi ini menyatukan berbagai kebutuhan ibadah esensial umat Islam ke dalam satu platform, mulai dari Al-Quran, jadwal sholat, hingga asisten berbasis AI.

Proyek ini disusun sebagai Tugas Akhir mata kuliah **Teknologi Pemrograman Mobile** di Universitas Pembangunan Nasional "Veteran" Yogyakarta.

## 👥 Anggota Kelompok
- **Salman Faris** (123230024) - IF-A
- **Reza Rasendriya Adi Putra** (123230030) - IF-A

## 🚀 Fitur Utama

### 🔐 Autentikasi & Keamanan
- **Login & Register**: Sistem pendaftaran akun dengan enkripsi kata sandi menggunakan algoritma **SHA-256**.
- **Biometric Auth**: Akses cepat dan aman menggunakan pemindai sidik jari atau wajah (Local Auth).
- **Session Management**: Menggunakan `SharedPreferences` agar pengguna tetap masuk tanpa perlu login berulang.

### 📖 Ibadah & Edukasi
- **Al-Quran Digital**: Akses 114 surah lengkap dengan terjemahan dan audio murottal (API e-Quran).
- **Kumpulan Doa**: Doa-doa harian esensial dengan fitur pencarian cepat.
- **Jadwal Sholat**: Waktu sholat otomatis sesuai lokasi pengguna dengan tampilan jam digital multi-zona (WIB, WITA, WIT).
- **Kalkulator Zakat**: Perhitungan zakat maal otomatis dengan konversi mata uang dunia (Exchange Rate API).

### 🤖 Kecerdasan Buatan (AI)
- **Chatbot Islami**: Asisten pintar berbasis **Google Gemini AI** yang siap menjawab pertanyaan seputar hukum Islam dan sejarah secara interaktif.

### 🧭 Sensor Perangkat & LBS
- **Arah Kiblat**: Penunjuk kiblat presisi menggunakan sensor *Magnetometer* dan koordinat GPS.
- **Shake Surah**: Fitur interaktif untuk mendapatkan rekomendasi surah acak hanya dengan menggoyangkan ponsel (*Accelerometer*).
- **Pencarian Masjid**: Melacak masjid terdekat dan memberikan panduan rute navigasi menggunakan **Google Maps API**.

### 🎮 Hiburan & Notifikasi
- **Minigame Sambung Ayat**: Game edukasi untuk melatih hafalan dengan sistem *High Score* lokal (SQLite).
- **Alarm Notifikasi**: Pengingat otomatis waktu sholat yang tetap berjalan di latar belakang (*Local Notifications*).

## 🛠️ Teknologi yang Digunakan
- **Framework**: [Flutter](https://flutter.dev/)
- **Bahasa**: [Dart](https://dart.dev/)
- **Database Lokal**: [SQLite](https://pub.dev/packages/sqflite) (sqflite)
- **Penyimpanan Key-Value**: [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **State Management**: ChangeNotifier / Provider
- **API Eksternal**:
  - [Equran.id API](https://equran.id/apidev/v2) (Quran & Jadwal)
  - [Exchange Rate API](https://api.exchangerate-api.com/v4/latest/IDR) (Currency)
  - [Google Gemini AI API](https://ai.google.dev/) (Generative AI)
  - [Google Maps Platform](https://developers.google.com/maps) (LBS)
