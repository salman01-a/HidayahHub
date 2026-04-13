import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/doa.dart';
import '../../services/doa_service.dart';
import 'home_feature.dart';

class DashboardTab extends StatefulWidget {
  final List<HomeFeature> features;
  final ValueChanged<HomeFeature> onTapFeature;

  const DashboardTab({
    super.key,
    required this.features,
    required this.onTapFeature,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const prayerTimes = {
    'Subuh': TimeOfDay(hour: 4, minute: 45),
    'Dzuhur': TimeOfDay(hour: 12, minute: 8),
    'Ashar': TimeOfDay(hour: 15, minute: 25),
    'Maghrib': TimeOfDay(hour: 17, minute: 41),
    'Isya': TimeOfDay(hour: 19, minute: 10),
  };

  late final Timer _timer;
  DateTime _now = DateTime.now();

  late final Future<List<DoaItem>> _doaFuture;
  List<DoaItem> _allDoa = const [];
  DoaItem? _randomDoa;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _doaFuture = _loadDoa();
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

  void _pickRandomDoa() {
    if (_allDoa.isEmpty) return;
    setState(() => _randomDoa = _allDoa[Random().nextInt(_allDoa.length)]);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = _nextPrayer(_now);

    return RefreshIndicator(
      onRefresh: _loadDoa,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _prayerHeader(nextPrayer),
          const SizedBox(height: 16),
          const Text(
            'Fitur Home',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fitur pada navbar tidak ditampilkan ulang di sini.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _featureBubbleGrid(),
          const SizedBox(height: 18),
          _randomDoaCard(),
        ],
      ),
    );
  }

  Widget _prayerHeader((String, DateTime) nextPrayer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A6360), Color(0xFF129B8A), Color(0xFF65C9AF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF129B8A).withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(_now),
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrayerBubble(
                  title: 'Now',
                  prayer: _currentPrayer(_now),
                  value: _formatHm(_toDate(_now, prayerTimes[_currentPrayer(_now)]!)),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrayerBubble(
                  title: 'Next',
                  prayer: nextPrayer.$1,
                  value: 'in ${_countdown(_now, nextPrayer.$2)}',
                  icon: Icons.nights_stay_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureBubbleGrid() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.start,
      children: widget.features
          .map(
            (feature) => _FeatureBubble(
              feature: feature,
              onTap: () => widget.onTapFeature(feature),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _randomDoaCard() {
    return FutureBuilder<List<DoaItem>>(
      future: _doaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _randomDoa == null) {
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
            child: const Text('Gagal memuat doa random. Tarik ke bawah untuk mencoba lagi.'),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1ECEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFDFF3EE),
                    child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF0A6C5D)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Doa Random Hari Ini',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
                style: const TextStyle(fontSize: 24, height: 1.5, fontWeight: FontWeight.w500),
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
    for (final e in prayerTimes.entries) {
      final dt = _toDate(now, e.value);
      if (dt.isAfter(now)) return (e.key, dt);
    }
    return ('Subuh', _toDate(now.add(const Duration(days: 1)), prayerTimes['Subuh']!));
  }

  String _currentPrayer(DateTime now) {
    String current = 'Subuh';
    for (final e in prayerTimes.entries) {
      if (now.isAfter(_toDate(now, e.value))) current = e.key;
    }
    return current;
  }

  DateTime _toDate(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  String _countdown(DateTime now, DateTime next) {
    final d = next.difference(now);
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${weekdays[(dt.weekday + 6) % 7]}, ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  prayer,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _FeatureBubble extends StatelessWidget {
  final HomeFeature feature;
  final VoidCallback onTap;

  const _FeatureBubble({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: feature.color,
                  boxShadow: [
                    BoxShadow(
                      color: feature.color.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(feature.icon, color: Colors.white, size: 29),
              ),
              const SizedBox(height: 8),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                feature.availableNow ? 'Live' : 'Soon',
                style: TextStyle(
                  fontSize: 10,
                  color: feature.availableNow ? const Color(0xFF1D7A5E) : const Color(0xFFA16A1F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
