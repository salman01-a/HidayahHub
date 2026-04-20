class SurahDetail {
  final int nomor;
  final String nama;
  final String namaLatin;
  final String arti;
  final int jumlahAyat;
  final String tempatTurun;
  final String deskripsi;
  final List<SurahAyat> ayat;

  const SurahDetail({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.arti,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.deskripsi,
    required this.ayat,
  });

  factory SurahDetail.fromMap(Map<String, dynamic> map) {
    final ayatRaw = map['ayat'];
    final ayatList = ayatRaw is List
        ? ayatRaw
              .whereType<Map<String, dynamic>>()
              .map(SurahAyat.fromMap)
              .toList(growable: false)
        : const <SurahAyat>[];

    return SurahDetail(
      nomor: map['nomor'] as int? ?? 0,
      nama: map['nama'] as String? ?? '-',
      namaLatin: map['namaLatin'] as String? ?? '-',
      arti: map['arti'] as String? ?? '-',
      jumlahAyat: map['jumlahAyat'] as int? ?? 0,
      tempatTurun: map['tempatTurun'] as String? ?? '-',
      deskripsi: map['deskripsi'] as String? ?? '-',
      ayat: ayatList,
    );
  }
}

class SurahAyat {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final Map<String, String> audio;

  const SurahAyat({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audio,
  });

  String? get preferredAudioUrl {
    return audio['05'];
  }

  factory SurahAyat.fromMap(Map<String, dynamic> map) {
    final audioRaw = map['audio'];
    final parsedAudio = <String, String>{};

    if (audioRaw is Map) {
      audioRaw.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          parsedAudio['$key'] = value;
        }
      });
    } else if (audioRaw is String && audioRaw.isNotEmpty) {
      parsedAudio['01'] = audioRaw;
    }

    return SurahAyat(
      nomorAyat: map['nomorAyat'] as int? ?? 0,
      teksArab: map['teksArab'] as String? ?? '-',
      teksLatin: map['teksLatin'] as String? ?? '-',
      teksIndonesia: map['teksIndonesia'] as String? ?? '-',
      audio: parsedAudio,
    );
  }
}
