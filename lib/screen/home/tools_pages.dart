import 'package:flutter/material.dart';

import '../../controllers/time_conversion_controller.dart';
import '../../models/shalat_schedule.dart';

class TimeConversionPage extends StatefulWidget {
  const TimeConversionPage({super.key});

  @override
  State<TimeConversionPage> createState() => _TimeConversionPageState();
}

class _TimeConversionPageState extends State<TimeConversionPage> {
  static const _bg = Color(0xFFF4F7FC);
  static const _card = Colors.white;
  static const _primary = Color(0xFF1A73E8);
  static const _accent = Color(0xFF1EC7B7);
  static const _border = Color(0xFFD7E2F2);
  static const _textMain = Color(0xFF1D2D45);
  static const _textSub = Color(0xFF5C6E89);

  late final TimeConversionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeConversionController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveToHome() async {
    if (_controller.selectedProvinsi == null ||
        _controller.selectedKabkota == null) {
      return;
    }

    final confirmed = await _confirmTimezoneMismatch();
    if (!confirmed) return;

    await _controller.saveHomePrayerSource();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zona ${_controller.baseZone} berhasil disimpan ke Home Page.',
        ),
      ),
    );
  }

  Future<bool> _confirmTimezoneMismatch() async {
    final prov = _controller.selectedProvinsi;
    if (prov == null) return true;

    final expectedZone = _controller.inferIndonesiaZone(prov);
    if (expectedZone == _controller.baseZone) return true;

    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Zona Waktu'),
          content: Text(
            'Lokasi $prov umumnya berada di zona $expectedZone, tetapi Anda memilih ${_controller.baseZone}. Lanjutkan menyimpan?',
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
    if (_controller.loadingInitial) {
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
          if (_controller.sectionIndex == 0)
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
    final selected = _controller.sectionIndex == idx;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _controller.setSectionIndex(idx),
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
                initialValue: _controller.selectedProvinsi,
                items: _controller.provinsi
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    _controller.onProvinsiChanged(value);
                  }
                },
                decoration: _inputDecoration('Provinsi'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: _textMain),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _controller.selectedKabkota,
                items: _controller.kabkota
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(growable: false),
                onChanged: _controller.loadingCities
                    ? null
                    : (value) {
                        if (value != null) {
                          _controller.onKabkotaChanged(value);
                        }
                      },
                decoration: _inputDecoration('Kabupaten/Kota'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: _textMain),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _controller.selectedBulan,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_controller.bulanNama(i + 1)),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    _controller.onBulanChanged(value);
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
        if (_controller.loadingCities || _controller.loadingSchedule)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primary),
              ),
            ),
          ),
        if (_controller.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF6B6BE)),
            ),
            child: Text(
              _controller.error!,
              style: const TextStyle(color: Color(0xFFFF7A7A)),
            ),
          ),
        if (_controller.schedule != null && !_controller.loadingSchedule)
          _buildScheduleTable(_controller.schedule!),
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
            '${schedule.kabkota}, ${schedule.provinsi} · ${TimeConversionController.fixedYear}',
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
            initialValue: _controller.baseZone,
            items: TimeConversionController.zones.keys
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) _controller.setBaseZone(value);
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
                      initialTime: _controller.baseTime,
                    );
                    if (picked != null) {
                      _controller.setPickedTime(picked);
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
                    _controller.usePickedTimeForPreview
                        ? 'Pilih Waktu (${_controller.formatTOD(_controller.baseTime)})'
                        : 'Pilih Waktu',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      (_controller.selectedProvinsi == null ||
                          _controller.selectedKabkota == null ||
                          _controller.savingHomeSetting)
                      ? null
                      : _saveToHome,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF07343C),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _controller.savingHomeSetting
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
            _controller.usePickedTimeForPreview
                ? 'Mode preview aktif. HomePage tetap memakai jam realtime zona ${_controller.baseZone}.'
                : 'Mode realtime aktif. HomePage akan mengikuti realtime zona ${_controller.baseZone}.',
            style: const TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...TimeConversionController.zones.keys.map((zoneName) {
            final realtime = _controller.formatDateTimeShort(
              _controller.nowInZone(zoneName),
            );
            final preview = _controller.convert(zoneName);
            final zoneSelected = zoneName == _controller.baseZone;
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
                      if (_controller.usePickedTimeForPreview)
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
}
