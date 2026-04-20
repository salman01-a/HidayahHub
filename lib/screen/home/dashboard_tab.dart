import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/doa.dart';
import '../../services/doa_service.dart';
import '../../services/home_prayer_pref_service.dart';
import '../../services/shalat_service.dart';
import 'home_feature.dart';

class DashboardTab extends StatefulWidget {
  final List<HomeFeature> features;
  final ValueChanged<HomeFeature> onTapFeature;
  final String userName;

  const DashboardTab({
    super.key,
    required this.features,
    required this.onTapFeature,
    required this.userName,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
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

  static const List<_HighlightItem> _highlightItems = [
    _HighlightItem(
      title: 'Baca Alquran',
      description:
          'Baca ayat harian dan lanjutkan progres terakhirmu dengan nyaman.',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF0C4A8D), Color(0xFF1B69CC)],
    ),
    _HighlightItem(
      title: 'Baca Kumpulan Surah',
      description:
          'Temukan surah pilihan lengkap dengan tampilan yang lebih fokus.',
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF0A6B67), Color(0xFF26A7A0)],
    ),
    _HighlightItem(
      title: 'Mini Game',
      description:
          'Latih hafalan ayat dengan konsep permainan yang ringan dan seru.',
      icon: Icons.extension_rounded,
      colors: [Color(0xFF7A2A8E), Color(0xFFB348D9)],
    ),
    _HighlightItem(
      title: 'Tracking Masjid',
      description:
          'Pantau lokasi masjid terdekat dan rencanakan perjalanan ibadahmu.',
      icon: Icons.location_on_rounded,
      colors: [Color(0xFF9A3F16), Color(0xFFD96B2F)],
    ),
  ];

  late final Timer _clockTimer;
  Timer? _highlightTimer;

  DateTime _nowLocal = DateTime.now();

  late final Future<List<DoaItem>> _doaFuture;
  List<DoaItem> _allDoa = const [];
  DoaItem? _randomDoa;

  final PageController _highlightController = PageController(
    viewportFraction: 0.92,
  );
  int _highlightIndex = 0;

  Map<String, TimeOfDay> _prayerTimes = Map<String, TimeOfDay>.from(
    _defaultPrayerTimes,
  );
  String _activeZone = 'WIB';
  String _activeRegion = 'Pengaturan default';
  bool _loadingPrayerSetting = true;
  bool _showMoreFeatures = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _nowLocal = DateTime.now());
    });

    _startHighlightAutoSlide();
    _doaFuture = _loadDoa();
    _loadHomePrayerConfig();
  }

  void _startHighlightAutoSlide() {
    _highlightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_highlightController.hasClients) return;
      final next = (_highlightIndex + 1) % _highlightItems.length;
      _highlightController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadHomePrayerConfig() async {
    try {
      final pref = await HomePrayerPrefService.instance.load();
      if (pref == null) {
        if (!mounted) return;
        setState(() => _loadingPrayerSetting = false);
        return;
      }

      final zone = pref.zona.trim().isEmpty ? 'WIB' : pref.zona.trim();
      if (!mounted) return;
      setState(() {
        _activeZone = zone;
        _activeRegion = '${pref.kabkota}, ${pref.provinsi}';
        _loadingPrayerSetting = true;
      });

      final schedule = await ShalatService.instance.getJadwal(
        provinsi: pref.provinsi,
        kabkota: pref.kabkota,
        bulan: pref.bulan,
        tahun: pref.tahun,
      );

      if (!mounted) return;

      final zoneNow = _nowInZone(zone);
      final todayEntry = schedule.jadwal.firstWhere(
        (entry) => entry.tanggal == zoneNow.day,
        orElse: () => schedule.jadwal.first,
      );

      setState(() {
        _prayerTimes = {
          'Subuh': _parseTime(todayEntry.subuh),
          'Dzuhur': _parseTime(todayEntry.dzuhur),
          'Ashar': _parseTime(todayEntry.ashar),
          'Maghrib': _parseTime(todayEntry.maghrib),
          'Isya': _parseTime(todayEntry.isya),
        };
        _loadingPrayerSetting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrayerSetting = false);
    }
  }

  Future<List<DoaItem>> _loadDoa() async {
    final list = await DoaService.instance.getDoaList();
    if (mounted) {
      setState(() {
        _allDoa = list;
        _randomDoa = list.isEmpty ? null : list[Random().nextInt(list.length)];
      });
    }
    return list;
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([_loadDoa(), _loadHomePrayerConfig()]);
  }

  void _pickRandomDoa() {
    if (_allDoa.isEmpty) return;
    setState(() => _randomDoa = _allDoa[Random().nextInt(_allDoa.length)]);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _highlightTimer?.cancel();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoneNow = _nowInZone(_activeZone);
    final nextPrayer = _nextPrayer(zoneNow);
    final quickFeatures = widget.features;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _heroCard(nextPrayer, zoneNow),
          const SizedBox(height: 16),
          _sectionHeader(
            'Layanan Utama',
            'Akses fitur harian dalam satu sentuhan',
          ),
          const SizedBox(height: 10),
          _featureMenuSection(quickFeatures),
          const SizedBox(height: 16),
          _sectionHeader(
            'Highlight Pilihan',
            'Geser untuk melihat rekomendasi',
          ),
          const SizedBox(height: 10),
          _highlightSlider(),
          const SizedBox(height: 16),
          _sectionHeader(
            'Doa Hari Ini',
            'Temani aktivitasmu dengan doa terbaik',
          ),
          const SizedBox(height: 10),
          _randomDoaCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, DateTime) nextPrayer, DateTime zoneNow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4F73), Color(0xFF116E86), Color(0xFF34A39B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5E7D).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nikmati Perjalanan Ibadahmu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateCompact(zoneNow),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_formatHmWithDot(zoneNow)} ${_activeZone.trim()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatRegionLine(_activeRegion),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_loadingPrayerSetting)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Sinkronisasi jadwal dari Waktu & Sholat ID...',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrayerBubble(
                  title: 'Sedang Berlangsung',
                  prayer: _currentPrayer(zoneNow),
                  value: _formatHm(
                    _toDate(zoneNow, _prayerTimes[_currentPrayer(zoneNow)]!),
                  ),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrayerBubble(
                  title: 'Berikutnya',
                  prayer: nextPrayer.$1,
                  value: 'in ${_countdown(zoneNow, nextPrayer.$2)}',
                  icon: Icons.nights_stay_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF647377),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureMiniGrid(List<HomeFeature> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        mainAxisExtent: 102,
      ),
      itemBuilder: (context, index) {
        final feature = items[index];
        return _FeatureMiniCard(
          feature: feature,
          onTap: () => widget.onTapFeature(feature),
        );
      },
    );
  }

  Widget _featureMenuSection(List<HomeFeature> allItems) {
  final topItems = allItems.take(8).toList(growable: false);
  final moreItems = allItems.skip(8).toList(growable: false);

  return Column(
    children: [
      _featureMiniGrid(topItems),
      AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: _showMoreFeatures && moreItems.isNotEmpty
            ? Column(
                children: [
                  const SizedBox(height: 12),
                  _featureMiniGrid(moreItems),
                ],
              )
            : const SizedBox.shrink(),
      ),
      if (moreItems.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: () {
              setState(() => _showMoreFeatures = !_showMoreFeatures);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF24659B),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            icon: Icon(
              _showMoreFeatures
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            label: Text(_showMoreFeatures ? 'Tutup' : 'Lainnya'),
          ),
        ),
    ],
  );
}

  Widget _highlightSlider() {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _highlightController,
            itemCount: _highlightItems.length,
            onPageChanged: (index) => setState(() => _highlightIndex = index),
            itemBuilder: (context, index) {
              final item = _highlightItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.colors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Icon(item.icon, color: Colors.white, size: 23),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_highlightItems.length, (index) {
            final active = index == _highlightIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: active
                    ? const Color(0xFF1B6D94)
                    : const Color(0xFFCAD8E0),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _randomDoaCard() {
    return FutureBuilder<List<DoaItem>>(
      future: _doaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _randomDoa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 12),
                Text('Memuat doa random...'),
              ],
            ),
          );
        }

        if (snapshot.hasError && _randomDoa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Gagal memuat doa random. Tarik ke bawah untuk mencoba lagi.',
            ),
          );
        }

        final doa = _randomDoa;
        if (doa == null) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('Data doa belum tersedia.'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE1ECEA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF082B2A).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFDDF1EF),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF0A6C5D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Doa Random Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _pickRandomDoa,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh doa random',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                doa.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                doa.group,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                doa.arabic,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(doa.translation, style: const TextStyle(height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  (String, DateTime) _nextPrayer(DateTime now) {
    for (final e in _prayerTimes.entries) {
      final dt = _toDate(now, e.value);
      if (dt.isAfter(now)) return (e.key, dt);
    }
    return (
      'Subuh',
      _toDate(now.add(const Duration(days: 1)), _prayerTimes['Subuh']!),
    );
  }

  String _currentPrayer(DateTime now) {
    String current = 'Subuh';
    for (final e in _prayerTimes.entries) {
      if (now.isAfter(_toDate(now, e.value))) current = e.key;
    }
    return current;
  }

  DateTime _toDate(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  DateTime _nowInZone(String zone) {
    final targetMinutes = (_zoneOffsets[zone] ?? 7) * 60;
    final localMinutes = _nowLocal.timeZoneOffset.inMinutes;
    final diffMinutes = targetMinutes - localMinutes;
    return _nowLocal.add(Duration(minutes: diffMinutes));
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 12, minute: 0);
    final h = int.tryParse(parts[0]) ?? 12;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _countdown(DateTime now, DateTime next) {
    final d = next.difference(now);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
  }

  String _formatDateCompact(DateTime dt) {
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

  String _formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatHmWithDot(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String _formatRegionLine(String rawRegion) {
    return rawRegion
        .replaceAll('D.I.', 'D.I')
        .replaceAll('Kab. ', 'Kab.')
        .replaceAll('KAB. ', 'Kab.');
  }
}

class _PrayerBubble extends StatelessWidget {
  final String title;
  final String prayer;
  final String value;
  final IconData icon;

  const _PrayerBubble({
    required this.title,
    required this.prayer,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  prayer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final HomeFeature feature;
  final VoidCallback onTap;

  const _FeatureMiniCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: feature.color.withValues(alpha: 0.75),
                  width: 1.2,
                ),
              ),
              child: Icon(feature.icon, color: feature.color, size: 21),
            ),
            const SizedBox(height: 9),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.16,
                color: Color(0xFF24344A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;

  const _HighlightItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });
}
