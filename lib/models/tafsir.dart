class TafsirSurah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final String arti;
  final int jumlahAyat;
  final String tempatTurun;
  final String deskripsi;
  final List<TafsirAyat> tafsir;

  const TafsirSurah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.arti,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.deskripsi,
    required this.tafsir,
  });

  factory TafsirSurah.fromMap(Map<String, dynamic> map) {
    final tafsirRaw = map['tafsir'];
    final tafsirList = tafsirRaw is List
        ? tafsirRaw
              .whereType<Map<String, dynamic>>()
              .map(TafsirAyat.fromMap)
              .toList(growable: false)
        : const <TafsirAyat>[];

    return TafsirSurah(
      nomor: map['nomor'] as int? ?? 0,
      nama: map['nama'] as String? ?? '-',
      namaLatin: map['namaLatin'] as String? ?? '-',
      arti: map['arti'] as String? ?? '-',
      jumlahAyat: map['jumlahAyat'] as int? ?? 0,
      tempatTurun: map['tempatTurun'] as String? ?? '-',
      deskripsi: _plainText(map['deskripsi'] as String? ?? '-'),
      tafsir: tafsirList,
    );
  }

  static String _plainText(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }
}

class TafsirAyat {
  final int ayat;
  final String teks;

  const TafsirAyat({required this.ayat, required this.teks});

  factory TafsirAyat.fromMap(Map<String, dynamic> map) {
    return TafsirAyat(
      ayat: map['ayat'] as int? ?? 0,
      teks: map['teks'] as String? ?? '-',
    );
  }
}
