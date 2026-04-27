# Perubahan Enkripsi Username (XOR Cipher)

## Ringkasan
Perubahan ini menerapkan enkripsi username dengan metode XOR Cipher pada proses:
1. Pembuatan akun (register)
2. Perubahan username (update profile)

Dengan perubahan ini, nilai username yang disimpan ke database tidak lagi plaintext.

## Detail Perubahan

### 1) Enkripsi/dekripsi username di model user
File: `lib/models/user.dart`

Perubahan yang dilakukan:
- Menambahkan prefix penanda data terenkripsi XOR: `xor:`
- Menambahkan key XOR statis aplikasi: `HidayahHub2026`
- Menambahkan fungsi:
  - `encodeName(String rawName)` untuk mengenkripsi username sebelum simpan
  - `decodeName(String storedName)` untuk dekripsi username saat dibaca
  - `_xorTransform(List<int> source, List<int> key)` sebagai mesin XOR byte-level
- Mengubah penyimpanan map user:
  - Sebelumnya: `name` disimpan apa adanya
  - Sekarang: `name` disimpan hasil `encodeName(name)` dalam format `xor:<base64url-payload>`
- Mengubah pembacaan map user:
  - Sebelumnya: `name` dibaca langsung
  - Sekarang: `name` dibaca dengan `decodeName(...)` (XOR + plaintext lama)

Catatan kompatibilitas:
- Jika data lama masih plaintext (tanpa prefix), sistem juga tetap bisa membaca username.

### 2) Validasi username unik pada database helper
File: `lib/services/db_helper.dart`

Perubahan yang dilakukan:
- Method `isNameTaken` kini membaca semua username dari database lalu membandingkan hasil `decodeName(...)`.
- Dengan cara ini, validasi duplikasi tetap akurat untuk:
  - plaintext lama
  - format baru XOR (`xor:`)

Tujuan:
- Menjaga validasi "username sudah digunakan" tetap benar untuk data lama dan data baru.

## Dampak ke Fitur
- Register akun baru: username tersimpan dalam bentuk terenkripsi XOR.
- Update profile (ubah username): username baru tersimpan terenkripsi XOR.
- Login dan tampilan nama pengguna: tetap normal karena sistem melakukan dekripsi saat membaca data user.

## Status Verifikasi Alur

### Register
- Input username dari halaman register dikirim ke `AuthController.register(...)`.
- Controller membuat `UserModel.create(...)`, lalu disimpan lewat `DBHelper.insertUser(...)`.
- Saat proses simpan, `UserModel.toMap()` otomatis memanggil `encodeName(...)`.
- Hasil: username tersimpan terenkripsi di kolom `users.name`.

### Ubah Username di Menu Profile
- Input username dari halaman edit profile dikirim ke `AuthController.updateProfile(...)`.
- Controller membuat objek `UserModel(...)`, lalu update lewat `DBHelper.updateUser(...)`.
- Saat proses update, `UserModel.toMap()` otomatis memanggil `encodeName(...)`.
- Hasil: username baru juga tersimpan terenkripsi di kolom `users.name`.

### Pembacaan Data User
- Saat data user diambil dari database, `UserModel.fromMap()` otomatis memanggil `decodeName(...)`.
- Hasil: aplikasi tetap menampilkan username asli (plaintext) di UI.

## Contoh Konsep
- Username input: `reza123`
- Tersimpan di DB: `xor:OQwTFgRPQ1I=` (contoh payload terenkripsi + base64url)
- Saat dibaca aplikasi: kembali menjadi `reza123`

## Batasan Keamanan
- XOR Cipher dengan key statis masih termasuk enkripsi sederhana dan tidak cocok untuk keamanan tingkat tinggi/produksi.
- Perubahan ini cocok untuk memenuhi kebutuhan tugas akademik yang secara eksplisit meminta implementasi enkripsi.

## Pembaruan dari Versi Sebelumnya
- Implementasi aktif saat ini hanya XOR, sehingga alur enkripsi lebih konsisten dan sederhana.
