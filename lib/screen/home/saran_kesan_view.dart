import 'package:flutter/material.dart';
import '../../controllers/saran_kesan_controller.dart';

class SaranKesanView extends StatefulWidget {
  const SaranKesanView({super.key});

  @override
  State<SaranKesanView> createState() => _SaranKesanViewState();
}

class _SaranKesanViewState extends State<SaranKesanView> {
  late final SaranKesanController _controller;

  static const Color _deepTeal = Color(0xFF0F5A4E); 
  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _accentGold = Color(0xFFCBA052);
  static const Color _bg = Color(0xFFF6F9FA);

  @override
  void initState() {
    super.initState();
    _controller = SaranKesanController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 22),

          _sectionHeader("Anggota Kelompok", "Mahasiswa Informatika Kelas ${_controller.kelas}"),
          const SizedBox(height: 12),
          _buildMemberCard(),
          const SizedBox(height: 24),

          _sectionHeader("Ulasan Mata Kuliah", "Refleksi untuk pengembangan kurikulum"),
          const SizedBox(height: 12),
          _buildContentCard(
            title: "Saran Pengembangan",
            content: _controller.saran,
            icon: Icons.tips_and_updates_rounded,
            color: _primaryTeal,
          ),
          const SizedBox(height: 16),
          _buildContentCard(
            title: "Kesan Belajar",
            content: _controller.kesan,
            icon: Icons.volunteer_activism_rounded,
            color: _accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,//
          colors: [_deepTeal, _primaryTeal, Color(0xFF35A598)], 
        ),
        boxShadow: [
          BoxShadow(
            color: _deepTeal.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Proyek',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'Saran & Kesan TPM',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Hasil kolaborasi dan refleksi akhir untuk mata kuliah Teknologi Pemrograman Mobile.',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 19, 
            color: _deepTeal 
          )
        ),
        const SizedBox(height: 2),
        Text(
          subtitle, 
          style: const TextStyle(color: Color(0xFF647377), fontSize: 13, fontWeight: FontWeight.w500)
        ),
      ],
    );
  }

  Widget _buildMemberCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _controller.anggota.asMap().entries.map((entry) {
          final m = entry.value;
          final isLast = entry.key == _controller.anggota.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4F1), 
                        borderRadius: BorderRadius.circular(14)
                      ),
                      child: const Icon(Icons.person_rounded, color: _primaryTeal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['nama']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF24344A))),
                          const SizedBox(height: 2),
                          Text("NIM ${m['nim']!}", style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 20, color: Color(0xFFF1F4F8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(fontSize: 14.5, height: 1.7, color: Color(0xFF455A64), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}