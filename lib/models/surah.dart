class Surah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final String arti;
  final int jumlahAyat;
  final String tempatTurun;

  const Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.arti,
    required this.jumlahAyat,
    required this.tempatTurun,
  });

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      nomor: map['nomor'] as int? ?? 0,
      nama: map['nama'] as String? ?? '-',
      namaLatin: map['namaLatin'] as String? ?? '-',
      arti: map['arti'] as String? ?? '-',
      jumlahAyat: map['jumlahAyat'] as int? ?? 0,
      tempatTurun: map['tempatTurun'] as String? ?? '-',
    );
  }
}
