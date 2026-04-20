import 'dart:async';

import 'package:flutter/material.dart';

import '../models/shalat_schedule.dart';
import '../services/home_prayer_pref_service.dart';
import '../services/shalat_service.dart';

class TimeConversionController extends ChangeNotifier {
  static const int fixedYear = 2026;
  static const Map<String, int> zones = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  int sectionIndex = 0;

  bool loadingInitial = true;
  bool loadingCities = false;
  bool loadingSchedule = false;
  bool savingHomeSetting = false;
  String? error;

  DateTime nowLocal = DateTime.now();
  Timer? _clockTimer;

  List<String> provinsi = const [];
  List<String> kabkota = const [];
  String? selectedProvinsi;
  String? selectedKabkota;
  int selectedBulan = DateTime.now().month;
  MonthlyShalatSchedule? schedule;

  String baseZone = 'WIB';
  TimeOfDay baseTime = const TimeOfDay(hour: 12, minute: 0);
  bool usePickedTimeForPreview = false;

  void initialize() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      nowLocal = DateTime.now();
      notifyListeners();
    });
    _initShalatData();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void setSectionIndex(int idx) {
    if (sectionIndex == idx) return;
    sectionIndex = idx;
    notifyListeners();
  }

  Future<void> _initShalatData() async {
    loadingInitial = true;
    error = null;
    notifyListeners();

    try {
      final provinces = await ShalatService.instance.getProvinsi();
      if (provinces.isEmpty) {
        throw Exception('Daftar provinsi kosong');
      }

      final selectedProv = provinces.first;
      final cities = await ShalatService.instance.getKabkota(selectedProv);
      final selectedCity = cities.isNotEmpty ? cities.first : null;

      MonthlyShalatSchedule? fetchedSchedule;
      if (selectedCity != null) {
        fetchedSchedule = await ShalatService.instance.getJadwal(
          provinsi: selectedProv,
          kabkota: selectedCity,
          bulan: selectedBulan,
          tahun: fixedYear,
        );
      }

      provinsi = provinces;
      kabkota = cities;
      selectedProvinsi = selectedProv;
      selectedKabkota = selectedCity;
      schedule = fetchedSchedule;
      baseZone = inferIndonesiaZone(selectedProv);
      if (fetchedSchedule != null && fetchedSchedule.jadwal.isNotEmpty) {
        baseTime = parseTime(fetchedSchedule.jadwal.first.subuh);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> onProvinsiChanged(String value) async {
    selectedProvinsi = value;
    selectedKabkota = null;
    kabkota = const [];
    loadingCities = true;
    error = null;
    baseZone = inferIndonesiaZone(value);
    notifyListeners();

    try {
      final cities = await ShalatService.instance.getKabkota(value);
      kabkota = cities;
      selectedKabkota = cities.isNotEmpty ? cities.first : null;
      await fetchSchedule();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingCities = false;
      notifyListeners();
    }
  }

  Future<void> onKabkotaChanged(String value) async {
    selectedKabkota = value;
    notifyListeners();
    await fetchSchedule();
  }

  Future<void> onBulanChanged(int value) async {
    selectedBulan = value;
    notifyListeners();
    await fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    if (selectedProvinsi == null || selectedKabkota == null) return;

    loadingSchedule = true;
    error = null;
    notifyListeners();

    try {
      final fetched = await ShalatService.instance.getJadwal(
        provinsi: selectedProvinsi!,
        kabkota: selectedKabkota!,
        bulan: selectedBulan,
        tahun: fixedYear,
      );

      schedule = fetched;
      if (fetched.jadwal.isNotEmpty) {
        baseTime = parseTime(fetched.jadwal.first.subuh);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loadingSchedule = false;
      notifyListeners();
    }
  }

  void setBaseZone(String zone) {
    baseZone = zone;
    notifyListeners();
  }

  void setPickedTime(TimeOfDay picked) {
    baseTime = picked;
    usePickedTimeForPreview = true;
    notifyListeners();
  }

  Future<void> saveHomePrayerSource() async {
    if (selectedProvinsi == null || selectedKabkota == null) return;

    savingHomeSetting = true;
    notifyListeners();

    try {
      await HomePrayerPrefService.instance.save(
        HomePrayerPreference(
          provinsi: selectedProvinsi!,
          kabkota: selectedKabkota!,
          bulan: selectedBulan,
          tahun: fixedYear,
          zona: baseZone,
        ),
      );
    } finally {
      savingHomeSetting = false;
      notifyListeners();
    }
  }

  String inferIndonesiaZone(String prov) {
    final p = prov.toLowerCase();
    if (p.contains('papua') || p.contains('maluku')) return 'WIT';
    if (p.contains('bali') ||
        p.contains('nusa tenggara') ||
        p.contains('sulawesi') ||
        p.contains('kalimantan timur') ||
        p.contains('kalimantan utara')) {
      return 'WITA';
    }
    return 'WIB';
  }

  TimeOfDay parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 12, minute: 0);
    final h = int.tryParse(parts[0]) ?? 12;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String convert(String targetZone) {
    final targetOffset = zones[targetZone] ?? 7;
    final baseOffset = zones[baseZone] ?? 7;
    final utc = DateTime.utc(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      baseTime.hour - baseOffset,
      baseTime.minute,
    );
    final converted = utc.add(Duration(hours: targetOffset));
    final h = converted.hour.toString().padLeft(2, '0');
    final m = converted.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime nowInZone(String zone) {
    final offset = zones[zone] ?? 7;
    return nowLocal.toUtc().add(Duration(hours: offset));
  }

  String formatDateTimeShort(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String formatTOD(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String bulanNama(int bulan) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return names[(bulan - 1).clamp(0, 11)];
  }
}
