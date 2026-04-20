import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/shalat_schedule.dart';
import '../../services/home_prayer_pref_service.dart';
import '../../services/shalat_service.dart';

class TimeConversionPage extends StatefulWidget {
  const TimeConversionPage({super.key});

  @override
  State<TimeConversionPage> createState() => _TimeConversionPageState();
}

class _TimeConversionPageState extends State<TimeConversionPage> {
  static const int _fixedYear = 2026;
  static const Map<String, int> _zones = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  int _sectionIndex = 0;

  bool _loadingInitial = true;
  bool _loadingCities = false;
  bool _loadingSchedule = false;
  bool _savingHomeSetting = false;
  String? _error;
  DateTime _nowLocal = DateTime.now();
  Timer? _clockTimer;

  List<String> _provinsi = const [];
  List<String> _kabkota = const [];
  String? _selectedProvinsi;
  String? _selectedKabkota;
  int _selectedBulan = DateTime.now().month;
  MonthlyShalatSchedule? _schedule;

  String _baseZone = 'WIB';
  TimeOfDay _baseTime = const TimeOfDay(hour: 12, minute: 0);
  bool _usePickedTimeForPreview = false;

  static const _bg = Color(0xFFF4F7FC);
  static const _card = Colors.white;
  static const _primary = Color(0xFF1A73E8);
  static const _accent = Color(0xFF1EC7B7);
  static const _border = Color(0xFFD7E2F2);
  static const _textMain = Color(0xFF1D2D45);
  static const _textSub = Color(0xFF5C6E89);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _nowLocal = DateTime.now());
    });
    _initShalatData();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initShalatData() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
    });

    try {
      final provinces = await ShalatService.instance.getProvinsi();
      if (provinces.isEmpty) {
        throw Exception('Daftar provinsi kosong');
      }

      final selectedProv = provinces.first;
      final cities = await ShalatService.instance.getKabkota(selectedProv);
      final selectedCity = cities.isNotEmpty ? cities.first : null;

      MonthlyShalatSchedule? schedule;
      if (selectedCity != null) {
        schedule = await ShalatService.instance.getJadwal(
          provinsi: selectedProv,
          kabkota: selectedCity,
          bulan: _selectedBulan,
          tahun: _fixedYear,
        );
      }

      if (!mounted) return;
      setState(() {
        _provinsi = provinces;
        _kabkota = cities;
        _selectedProvinsi = selectedProv;
        _selectedKabkota = selectedCity;
        _schedule = schedule;
        _baseZone = _inferIndonesiaZone(selectedProv);
        if (schedule != null && schedule.jadwal.isNotEmpty) {
          _baseTime = _parseTime(schedule.jadwal.first.subuh);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingInitial = false);
      }
    }
  }

  Future<void> _onProvinsiChanged(String value) async {
    setState(() {
      _selectedProvinsi = value;
      _selectedKabkota = null;
      _kabkota = const [];
      _loadingCities = true;
      _error = null;
      _baseZone = _inferIndonesiaZone(value);
    });

    try {
      final cities = await ShalatService.instance.getKabkota(value);
      if (!mounted) return;
      setState(() {
        _kabkota = cities;
        _selectedKabkota = cities.isNotEmpty ? cities.first : null;
      });
      await _fetchSchedule();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _fetchSchedule() async {
    if (_selectedProvinsi == null || _selectedKabkota == null) return;

    setState(() {
      _loadingSchedule = true;
      _error = null;
    });

    try {
      final schedule = await ShalatService.instance.getJadwal(
        provinsi: _selectedProvinsi!,
        kabkota: _selectedKabkota!,
        bulan: _selectedBulan,
        tahun: _fixedYear,
      );

      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        if (schedule.jadwal.isNotEmpty) {
          _baseTime = _parseTime(schedule.jadwal.first.subuh);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _setAsHomePrayerSource() async {
    if (_selectedProvinsi == null || _selectedKabkota == null) return;

    final canContinue = await _confirmTimezoneMismatch();
    if (!canContinue) return;

    setState(() => _savingHomeSetting = true);
    try {
      await HomePrayerPrefService.instance.save(
        HomePrayerPreference(
          provinsi: _selectedProvinsi!,
          kabkota: _selectedKabkota!,
          bulan: _selectedBulan,
          tahun: _fixedYear,
          zona: _baseZone,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zona $_baseZone berhasil disimpan ke Home Page.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan pengaturan Home Page.')),
      );
    } finally {
      if (mounted) setState(() => _savingHomeSetting = false);
    }
  }

  Future<bool> _confirmTimezoneMismatch() async {
    final prov = _selectedProvinsi;
    if (prov == null) return true;

    final expectedZone = _inferIndonesiaZone(prov);
    if (expectedZone == _baseZone) return true;

    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Zona Waktu'),
          content: Text(
            'Lokasi $prov umumnya berada di zona $expectedZone, tetapi Anda memilih $_baseZone. Lanjutkan menyimpan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    return decision == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial) {
      return Scaffold(
        body: Container(
          color: _bg,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 26),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF1A73E8)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat jadwal sholat...',
                    style: TextStyle(
                      color: Color(0xFF1D2D45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Waktu & Jadwal Sholat ID'),
        backgroundColor: Colors.white,
        foregroundColor: _textMain,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConceptCard(),
          const SizedBox(height: 12),
          _buildSectionSwitch(),
          const SizedBox(height: 12),
          if (_sectionIndex == 0)
            _buildShalatSection()
          else
            _buildConversionSection(),
        ],
      ),
    );
  }

  Widget _buildConceptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Color(0xFFF5F9FF)],
        ),
        border: Border.all(color: _border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.travel_explore_rounded, color: Color(0xFF1A73E8)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Konsep terpadu: jadwal sholat Indonesia + konversi zona waktu realtime untuk kebutuhan ibadah dan perjalanan.',
              style: TextStyle(color: Color(0xFF1D2D45), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSectionButton('Jadwal Sholat Indonesia', 0)),
          const SizedBox(width: 6),
          Expanded(child: _buildSectionButton('Konversi Waktu', 1)),
        ],
      ),
    );
  }

  Widget _buildSectionButton(String label, int idx) {
    final selected = _sectionIndex == idx;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _sectionIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? const Color(0xFF25D7CF) : Colors.transparent,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFF08335F) : _textSub,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSub),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FBFF),
    );
  }

  Widget _buildShalatSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedProvinsi,
                items: _provinsi
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    _onProvinsiChanged(value);
                  }
                },
                decoration: _inputDecoration('Provinsi'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: _textMain),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedKabkota,
                items: _kabkota
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(growable: false),
                onChanged: _loadingCities
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedKabkota = value);
                          _fetchSchedule();
                        }
                      },
                decoration: _inputDecoration('Kabupaten/Kota'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: _textMain),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedBulan,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_bulanNama(i + 1)),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedBulan = value);
                    _fetchSchedule();
                  }
                },
                decoration: _inputDecoration('Bulan'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: _textMain),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingCities || _loadingSchedule)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation(_primary),
              ),
            ),
          ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF6B6BE)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF7A7A)),
            ),
          ),
        if (_schedule != null && !_loadingSchedule)
          _buildScheduleTable(_schedule!),
      ],
    );
  }

  Widget _buildScheduleTable(MonthlyShalatSchedule schedule) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal ${schedule.bulanNama}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${schedule.kabkota}, ${schedule.provinsi} · $_fixedYear',
            style: const TextStyle(color: _textSub),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textMain,
              ),
              dataTextStyle: const TextStyle(color: _textSub),
              headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF1FF)),
              dataRowColor: WidgetStateProperty.all(Colors.white),
              columns: const [
                DataColumn(label: Text('Tgl')),
                DataColumn(label: Text('Hari')),
                DataColumn(label: Text('Subuh')),
                DataColumn(label: Text('Dzuhur')),
                DataColumn(label: Text('Ashar')),
                DataColumn(label: Text('Maghrib')),
                DataColumn(label: Text('Isya')),
              ],
              rows: schedule.jadwal
                  .map(
                    (e) => DataRow(
                      cells: [
                        DataCell(Text('${e.tanggal}')),
                        DataCell(Text(e.hari)),
                        DataCell(Text(e.subuh)),
                        DataCell(Text(e.dzuhur)),
                        DataCell(Text(e.ashar)),
                        DataCell(Text(e.maghrib)),
                        DataCell(Text(e.isya)),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konversi Waktu Lintas Zona',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Konversi realtime antar zona. Tombol Pilih Waktu hanya untuk preview, sedangkan Simpan ke HomePage hanya menerapkan zona.',
            style: TextStyle(color: _textSub),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _baseZone,
            items: _zones.keys
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) setState(() => _baseZone = value);
            },
            decoration: _inputDecoration('Zona acuan untuk HomePage'),
            dropdownColor: Colors.white,
            style: const TextStyle(color: _textMain),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _baseTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _baseTime = picked;
                        _usePickedTimeForPreview = true;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textMain,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text(
                    _usePickedTimeForPreview
                        ? 'Pilih Waktu (${_formatTOD(_baseTime)})'
                        : 'Pilih Waktu',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      (_selectedProvinsi == null ||
                          _selectedKabkota == null ||
                          _savingHomeSetting)
                      ? null
                      : _setAsHomePrayerSource,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF07343C),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _savingHomeSetting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.home_rounded),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _usePickedTimeForPreview
                ? 'Mode preview aktif. HomePage tetap memakai jam realtime zona $_baseZone.'
                : 'Mode realtime aktif. HomePage akan mengikuti realtime zona $_baseZone.',
            style: const TextStyle(color: Color(0xFF9BC0EA), fontSize: 12),
          ),
          const SizedBox(height: 10),
          ..._zones.keys.map((zoneName) {
            final realtime = _formatDateTimeShort(_nowInZone(zoneName));
            final preview = _convert(zoneName);
            final zoneSelected = zoneName == _baseZone;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: zoneSelected
                    ? const Color(0xFFE2F8F6)
                    : const Color(0xFFF2F6FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: zoneSelected ? const Color(0xFF9FE7DF) : _border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      zoneName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _textMain,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        realtime,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _primary,
                        ),
                      ),
                      if (_usePickedTimeForPreview)
                        Text(
                          'Preview: $preview',
                          style: const TextStyle(fontSize: 11, color: _textSub),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _inferIndonesiaZone(String provinsi) {
    final p = provinsi.toLowerCase();
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

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 12, minute: 0);
    final h = int.tryParse(parts[0]) ?? 12;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _convert(String targetZone) {
    final targetOffset = _zones[targetZone] ?? 7;
    final baseOffset = _zones[_baseZone] ?? 7;
    final utc = DateTime.utc(
      _nowLocal.year,
      _nowLocal.month,
      _nowLocal.day,
      _baseTime.hour - baseOffset,
      _baseTime.minute,
    );
    final converted = utc.add(Duration(hours: targetOffset));
    final h = converted.hour.toString().padLeft(2, '0');
    final m = converted.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime _nowInZone(String zone) {
    final offset = _zones[zone] ?? 7;
    return _nowLocal.toUtc().add(Duration(hours: offset));
  }

  String _formatDateTimeShort(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTOD(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _bulanNama(int bulan) {
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
