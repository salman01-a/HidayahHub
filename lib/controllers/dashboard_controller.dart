import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/doa.dart';
import '../services/doa_service.dart';
import '../services/home_prayer_pref_service.dart';
import '../services/shalat_service.dart';
import '../screen/home/home_feature.dart';

class DashboardHighlightItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;

  const DashboardHighlightItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });
}

class DashboardController extends ChangeNotifier {
  static const Map<String, TimeOfDay> _defaultPrayerTimes = {
    'Subuh': TimeOfDay(hour: 4, minute: 45),
    'Dzuhur': TimeOfDay(hour: 12, minute: 8),
    'Ashar': TimeOfDay(hour: 15, minute: 25),
    'Maghrib': TimeOfDay(hour: 17, minute: 41),
    'Isya': TimeOfDay(hour: 19, minute: 10),
  };

  static const Map<String, int> _zoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  static const List<DashboardHighlightItem> highlightItems = [
    DashboardHighlightItem(
      title: 'Baca Alquran',
      description:
          'Baca ayat harian dan lanjutkan progres terakhirmu dengan nyaman.',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF0C4A8D), Color(0xFF1B69CC)],
    ),
    DashboardHighlightItem(
      title: 'Baca Kumpulan Surah',
      description:
          'Temukan surah pilihan lengkap dengan tampilan yang lebih fokus.',
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF0A6B67), Color(0xFF26A7A0)],
    ),
    DashboardHighlightItem(
      title: 'Mini Game',
      description:
          'Latih hafalan ayat dengan konsep permainan yang ringan dan seru.',
      icon: Icons.extension_rounded,
      colors: [Color(0xFF7A2A8E), Color(0xFFB348D9)],
    ),
    DashboardHighlightItem(
      title: 'Tracking Masjid',
      description:
          'Pantau lokasi masjid terdekat dan rencanakan perjalanan ibadahmu.',
      icon: Icons.location_on_rounded,
      colors: [Color(0xFF9A3F16), Color(0xFFD96B2F)],
    ),
  ];

  Timer? _clockTimer;

  DateTime nowLocal = DateTime.now();
  List<DoaItem> allDoa = const [];
  DoaItem? randomDoa;

  Map<String, TimeOfDay> prayerTimes = Map<String, TimeOfDay>.from(
    _defaultPrayerTimes,
  );
  String activeZone = 'WIB';
  String activeRegion = 'Pengaturan default';
  bool loadingPrayerSetting = true;
  bool showMoreFeatures = false;
  int highlightIndex = 0;

  Future<List<DoaItem>>? _doaFuture;

  Future<List<DoaItem>> get doaFuture {
    _doaFuture ??= loadDoa();
    return _doaFuture!;
  }

  void initialize() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      nowLocal = DateTime.now();
      notifyListeners();
    });
    _doaFuture = loadDoa();
    loadHomePrayerConfig();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void setHighlightIndex(int index) {
    highlightIndex = index;
    notifyListeners();
  }

  void toggleMoreFeatures() {
    showMoreFeatures = !showMoreFeatures;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    await Future.wait<void>([
      _safeLoadDoa(),
      _safeLoadHomePrayerConfig(),
    ]);
  }

  Future<void> _safeLoadDoa() async {
    try {
      await loadDoa().timeout(const Duration(seconds: 15));
    } catch (_) {
    }
  }

  Future<void> _safeLoadHomePrayerConfig() async {
    try {
      await loadHomePrayerConfig().timeout(const Duration(seconds: 20));
    } catch (_) {
    }
  }

  Future<List<DoaItem>> loadDoa() async {
    final list = await DoaService.instance.getDoaList();
    allDoa = list;
    randomDoa = list.isEmpty ? null : list[Random().nextInt(list.length)];
    notifyListeners();
    return list;
  }

  void pickRandomDoa() {
    if (allDoa.isEmpty) return;
    randomDoa = allDoa[Random().nextInt(allDoa.length)];
    notifyListeners();
  }

  Future<void> loadHomePrayerConfig() async {
    try {
      final pref = await HomePrayerPrefService.instance.load();
      if (pref == null) {
        loadingPrayerSetting = false;
        notifyListeners();
        return;
      }

      final zone = pref.zona.trim().isEmpty ? 'WIB' : pref.zona.trim();
      activeZone = zone;
      activeRegion = '${pref.kabkota}, ${pref.provinsi}';
      loadingPrayerSetting = true;
      notifyListeners();

      final schedule = await ShalatService.instance.getJadwal(
        provinsi: pref.provinsi,
        kabkota: pref.kabkota,
        bulan: pref.bulan,
        tahun: pref.tahun,
      );

      final zoneNow = nowInZone(zone);
      final todayEntry = schedule.jadwal.firstWhere(
        (entry) => entry.tanggal == zoneNow.day,
        orElse: () => schedule.jadwal.first,
      );

      prayerTimes = {
        'Subuh': parseTime(todayEntry.subuh),
        'Dzuhur': parseTime(todayEntry.dzuhur),
        'Ashar': parseTime(todayEntry.ashar),
        'Maghrib': parseTime(todayEntry.maghrib),
        'Isya': parseTime(todayEntry.isya),
      };
    } catch (_) {
      // Keep previous values.
    } finally {
      loadingPrayerSetting = false;
      notifyListeners();
    }
  }

  List<HomeFeature> topFeatures(List<HomeFeature> allItems) {
    return allItems.take(8).toList(growable: false);
  }

  List<HomeFeature> moreFeatures(List<HomeFeature> allItems) {
    return allItems.skip(8).toList(growable: false);
  }

  DateTime nowInZone(String zone) {
    final targetMinutes = (_zoneOffsets[zone] ?? 7) * 60;
    final localMinutes = nowLocal.timeZoneOffset.inMinutes;
    final diffMinutes = targetMinutes - localMinutes;
    return nowLocal.add(Duration(minutes: diffMinutes));
  }

  (String, DateTime) nextPrayer(DateTime now) {
    for (final e in prayerTimes.entries) {
      final dt = toDate(now, e.value);
      if (dt.isAfter(now)) return (e.key, dt);
    }
    return (
      'Subuh',
      toDate(now.add(const Duration(days: 1)), prayerTimes['Subuh']!),
    );
  }

  String currentPrayer(DateTime now) {
    String current = 'Subuh';
    for (final e in prayerTimes.entries) {
      if (now.isAfter(toDate(now, e.value))) current = e.key;
    }
    return current;
  }

  DateTime toDate(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  TimeOfDay parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 12, minute: 0);
    final h = int.tryParse(parts[0]) ?? 12;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String countdown(DateTime now, DateTime next) {
    final d = next.difference(now);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
  }

  String formatDateCompact(DateTime dt) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
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
    return '${weekdays[(dt.weekday + 6) % 7]},${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String formatHmWithDot(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String formatRegionLine(String rawRegion) {
    return rawRegion
        .replaceAll('D.I.', 'D.I')
        .replaceAll('Kab. ', 'Kab.')
        .replaceAll('KAB. ', 'Kab.');
  }
}
