import 'package:flutter/material.dart';

import '../../models/shalat_schedule.dart';
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
  String? _error;

  List<String> _provinsi = const [];
  List<String> _kabkota = const [];
  String? _selectedProvinsi;
  String? _selectedKabkota;
  int _selectedBulan = DateTime.now().month;
  MonthlyShalatSchedule? _schedule;

  String _baseZone = 'WIB';
  TimeOfDay _baseTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _initShalatData();
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

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF071029),
      appBar: AppBar(
        title: const Text('Waktu & Jadwal Sholat ID'),
        backgroundColor: const Color(0xFF071029),
        foregroundColor: Colors.white,
        surfaceTintColor: const Color(0xFF071029),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1738),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C335F)),
      ),
      child: const Text(
        'Konsep terpadu: jadwal sholat Indonesia (berdasarkan provinsi/kabkota) + konversi waktu lintas zona untuk kebutuhan ibadah dan perjalanan.',
        style: TextStyle(color: Colors.white70, height: 1.4),
      ),
    );
  }

  Widget _buildSectionSwitch() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Jadwal Sholat Indonesia'),
            selected: _sectionIndex == 0,
            onSelected: (_) => setState(() => _sectionIndex = 0),
            labelStyle: TextStyle(
              color: _sectionIndex == 0
                  ? const Color(0xFF081B38)
                  : Colors.white,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: const Color(0xFF0F2147),
            selectedColor: const Color(0xFF23D3C6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChoiceChip(
            label: const Text('Konversi Waktu'),
            selected: _sectionIndex == 1,
            onSelected: (_) => setState(() => _sectionIndex = 1),
            labelStyle: TextStyle(
              color: _sectionIndex == 1
                  ? const Color(0xFF081B38)
                  : Colors.white,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: const Color(0xFF0F2147),
            selectedColor: const Color(0xFF23D3C6),
          ),
        ),
      ],
    );
  }

  Widget _buildShalatSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1738),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1C335F)),
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
                decoration: const InputDecoration(
                  labelText: 'Provinsi',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2C4E86)),
                  ),
                ),
                dropdownColor: Color(0xFF0B1738),
                style: const TextStyle(color: Colors.white),
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
                decoration: const InputDecoration(
                  labelText: 'Kabupaten/Kota',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2C4E86)),
                  ),
                ),
                dropdownColor: Color(0xFF0B1738),
                style: const TextStyle(color: Colors.white),
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
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2C4E86)),
                  ),
                ),
                dropdownColor: Color(0xFF0B1738),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingCities || _loadingSchedule)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1430),
              borderRadius: BorderRadius.circular(12),
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
        color: const Color(0xFF0B1738),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C335F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal ${schedule.bulanNama}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${schedule.kabkota}, ${schedule.provinsi} · $_fixedYear',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              dataTextStyle: const TextStyle(color: Colors.white70),
              headingRowColor: WidgetStateProperty.all(const Color(0xFF102754)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF0B1738)),
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
        color: const Color(0xFF0B1738),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C335F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konversi Waktu Lintas Zona',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: waktu default diambil dari Subuh hari pertama jadwal terpilih supaya langsung nyambung ke konteks ibadah.',
            style: TextStyle(color: Colors.white70),
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
            decoration: const InputDecoration(
              labelText: 'Zona waktu asal',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2C4E86)),
              ),
            ),
            dropdownColor: Color(0xFF0B1738),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Waktu asal'),
            subtitle: Text(
              _formatTOD(_baseTime),
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: OutlinedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _baseTime,
                );
                if (picked != null) setState(() => _baseTime = picked);
              },
              child: const Text('Pilih'),
            ),
            textColor: Colors.white,
          ),
          const SizedBox(height: 6),
          ..._zones.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF102754),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    _convert(entry.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF23D3C6),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  String _convert(int targetOffset) {
    final baseOffset = _zones[_baseZone] ?? 7;
    final utc = DateTime.utc(
      2026,
      1,
      1,
      _baseTime.hour - baseOffset,
      _baseTime.minute,
    );
    final converted = utc.add(Duration(hours: targetOffset));
    final h = converted.hour.toString().padLeft(2, '0');
    final m = converted.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
