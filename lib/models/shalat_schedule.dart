class PrayerTimeEntry {
  final int tanggal;
  final String hari;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  const PrayerTimeEntry({
    required this.tanggal,
    required this.hari,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory PrayerTimeEntry.fromMap(Map<String, dynamic> map) {
    return PrayerTimeEntry(
      tanggal: map['tanggal'] as int? ?? 0,
      hari: map['hari'] as String? ?? '-',
      imsak: map['imsak'] as String? ?? '-',
      subuh: map['subuh'] as String? ?? '-',
      terbit: map['terbit'] as String? ?? '-',
      dhuha: map['dhuha'] as String? ?? '-',
      dzuhur: map['dzuhur'] as String? ?? '-',
      ashar: map['ashar'] as String? ?? '-',
      maghrib: map['maghrib'] as String? ?? '-',
      isya: map['isya'] as String? ?? '-',
    );
  }
}

class MonthlyShalatSchedule {
  final String provinsi;
  final String kabkota;
  final int bulan;
  final int tahun;
  final String bulanNama;
  final List<PrayerTimeEntry> jadwal;

  const MonthlyShalatSchedule({
    required this.provinsi,
    required this.kabkota,
    required this.bulan,
    required this.tahun,
    required this.bulanNama,
    required this.jadwal,
  });

  factory MonthlyShalatSchedule.fromMap(Map<String, dynamic> map) {
    final rawList = map['jadwal'] as List<dynamic>? ?? const [];
    return MonthlyShalatSchedule(
      provinsi: map['provinsi'] as String? ?? '-',
      kabkota: map['kabkota'] as String? ?? '-',
      bulan: map['bulan'] as int? ?? 0,
      tahun: map['tahun'] as int? ?? 0,
      bulanNama: map['bulan_nama'] as String? ?? '-',
      jadwal: rawList
          .whereType<Map<String, dynamic>>()
          .map(PrayerTimeEntry.fromMap)
          .toList(growable: false),
    );
  }
}
