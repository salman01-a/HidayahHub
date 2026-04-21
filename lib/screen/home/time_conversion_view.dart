import 'package:flutter/material.dart';

import '../../controllers/time_conversion_controller.dart';
import '../../models/shalat_schedule.dart';

class TimeConversionView extends StatefulWidget {
  const TimeConversionView({super.key});

  @override
  State<TimeConversionView> createState() => _TimeConversionViewState();
}

class _TimeConversionViewState extends State<TimeConversionView> {
  // Palet Warna Hidayah Hub
  static const _bg = Color(0xFFF8FAFB);
  static const _card = Colors.white;
  static const _primaryTeal = Color(0xFF1A7F6D);
  static const _deepTeal = Color(0xFF0F5A4E);
  static const _accentGold = Color(0xFFCBA052);
  static const _border = Color(0xFFE8F4F1);
  static const _textSub = Color(0xFF6A7987);

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
        backgroundColor: _deepTeal,
        behavior: SnackBarBehavior.floating,
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Zona Waktu',
            style: TextStyle(color: _deepTeal, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Lokasi $prov umumnya berada di zona $expectedZone, tetapi Anda memilih ${_controller.baseZone}. Lanjutkan menyimpan?',
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(color: _textSub, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ya, Simpan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
        backgroundColor: _bg,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation(_primaryTeal),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Memuat jadwal sholat...',
                  style: TextStyle(
                    color: _deepTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Waktu & Jadwal Sholat ID',
          style: TextStyle(
            color: _deepTeal,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryTeal),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildConceptCard(),
          const SizedBox(height: 16),
          _buildSectionSwitch(),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F4F1), Color(0xFFF8FAFB)],
        ),
        border: Border.all(color: const Color(0xFFD8ECE7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.travel_explore_rounded, color: _primaryTeal, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Konsep terpadu: jadwal sholat Indonesia + konversi zona waktu realtime untuk kebutuhan ibadah dan perjalanan.',
              style: TextStyle(
                color: _deepTeal,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSectionButton('Jadwal Indonesia', 0)),
          const SizedBox(width: 6),
          Expanded(child: _buildSectionButton('Konversi Waktu', 1)),
        ],
      ),
    );
  }

  Widget _buildSectionButton(String label, int idx) {
    final selected = _controller.sectionIndex == idx;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _controller.setSectionIndex(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? _primaryTeal : Colors.transparent,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : _textSub,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSub, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryTeal, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildShalatSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _controller.selectedProvinsi,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primaryTeal,
                ),
                items: _controller.provinsi
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    _controller.onProvinsiChanged(value);
                  }
                },
                decoration: _inputDecoration('Pilih Provinsi'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _controller.selectedKabkota,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primaryTeal,
                ),
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
                decoration: _inputDecoration('Pilih Kabupaten/Kota'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _controller.selectedBulan,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _primaryTeal,
                ),
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
                decoration: _inputDecoration('Pilih Bulan'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_controller.loadingCities || _controller.loadingSchedule)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primaryTeal),
              ),
            ),
          ),
        if (_controller.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF6B6BE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF7A7A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _controller.error!,
                    style: const TextStyle(
                      color: Color(0xFFFF7A7A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal ${schedule.bulanNama}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: _deepTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${schedule.kabkota}, ${schedule.provinsi} • ${TimeConversionController.fixedYear}',
            style: const TextStyle(
              color: _accentGold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable(
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                dataTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                headingRowColor: WidgetStateProperty.all(_primaryTeal),
                dataRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFB)),
                dividerThickness: 0.5,
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
                          DataCell(
                            Text(
                              '${e.tanggal}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildConversionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konversi Lintas Zona',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: _deepTeal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Konversi realtime antar zona. Tombol Pilih Waktu hanya untuk preview, sedangkan Simpan ke HomePage hanya menerapkan zona.',
            style: TextStyle(color: _textSub, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _controller.baseZone,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _primaryTeal,
            ),
            items: TimeConversionController.zones.keys
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) _controller.setBaseZone(value);
            },
            decoration: _inputDecoration('Zona acuan untuk HomePage'),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _controller.baseTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _primaryTeal,
                              onPrimary: Colors.white,
                              onSurface: _deepTeal,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      _controller.setPickedTime(picked);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepTeal,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text(
                    _controller.usePickedTimeForPreview
                        ? 'Preview: ${_controller.formatTOD(_controller.baseTime)}'
                        : 'Pilih Waktu',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      (_controller.selectedProvinsi == null ||
                          _controller.selectedKabkota == null ||
                          _controller.savingHomeSetting)
                      ? null
                      : _saveToHome,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _controller.savingHomeSetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.home_rounded),
                  label: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _controller.usePickedTimeForPreview
                ? 'Mode preview aktif. HomePage tetap memakai jam realtime zona ${_controller.baseZone}.'
                : 'Mode realtime aktif. HomePage akan mengikuti realtime zona ${_controller.baseZone}.',
            style: const TextStyle(
              color: _accentGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...TimeConversionController.zones.keys.map((zoneName) {
            final realtime = _controller.formatDateTimeShort(
              _controller.nowInZone(zoneName),
            );
            final preview = _controller.convert(zoneName);
            final zoneSelected = zoneName == _controller.baseZone;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: zoneSelected ? const Color(0xFFE8F4F1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: zoneSelected
                      ? _primaryTeal.withOpacity(0.5)
                      : Colors.grey.shade200,
                  width: zoneSelected ? 1.5 : 1,
                ),
                boxShadow: zoneSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      zoneName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: zoneSelected ? _deepTeal : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        realtime,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: zoneSelected ? _primaryTeal : _deepTeal,
                          fontSize: 14,
                        ),
                      ),
                      if (_controller.usePickedTimeForPreview) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Preview: $preview',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
