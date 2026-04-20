import 'package:flutter/material.dart';

import 'home/dashboard_tab.dart';
import 'home/doa_tab.dart';
import 'home/home_feature.dart';
import 'home/profile_tab.dart';
import 'home/quran_tab.dart';
import 'home/search_surah_tab.dart';
import 'home/saran_kesan_tab.dart';
import 'home/tools_pages.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _navHome = 0;
  static const int _navLogout = 3;

  int _selectedNavIndex = _navHome;
  int _currentPage = 0;
  int _dashboardRefreshSignal = 0;

  late final List<HomeFeature> _homeOnlyFeatures = [
    const HomeFeature(
      title: 'Baca Al Quran',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3F95D0),
      action: HomeFeatureAction.bukaQuran,
      availableNow: true,
    ),
    const HomeFeature(
      title: 'Kumpulan Doa',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF66A64A),
      action: HomeFeatureAction.bukaDoa,
      availableNow: true,
    ),
    const HomeFeature(
      title: 'Cari Surah',
      icon: Icons.search_rounded,
      color: Color(0xFF6D72D7),
      action: HomeFeatureAction.cariSurah,
      availableNow: true,
    ),
    const HomeFeature(
      title: 'Waktu & Sholat ID',
      icon: Icons.schedule_rounded,
      color: Color(0xFFF0B64A),
      action: HomeFeatureAction.konversiWaktu,
      availableNow: true,
    ),
    const HomeFeature(
      title: 'Chatbot',
      icon: Icons.smart_toy_outlined,
      color: Color(0xFF5C78D9),
      action: HomeFeatureAction.chatbot,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Zakat & Donasi',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFF08B4A),
      action: HomeFeatureAction.zakatDonasi,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Cari Masjid',
      icon: Icons.location_on_outlined,
      color: Color(0xFF57B56D),
      action: HomeFeatureAction.masjidTerdekat,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Arah Kiblat',
      icon: Icons.explore_outlined,
      color: Color(0xFF7F72D8),
      action: HomeFeatureAction.arahKiblat,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Shake Surah',
      icon: Icons.vibration_rounded,
      color: Color(0xFF4B8AC2),
      action: HomeFeatureAction.shakeSurah,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Minigames Ayat',
      icon: Icons.extension_outlined,
      color: Color(0xFFD46879),
      action: HomeFeatureAction.miniGames,
      availableNow: false,
    ),
    const HomeFeature(
      title: 'Notif Sholat',
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF4BA890),
      action: HomeFeatureAction.notifSholat,
      availableNow: false,
    ),
  ];

  void _onHomeFeatureTap(HomeFeature feature) {
    switch (feature.action) {
      case HomeFeatureAction.bukaQuran:
        _openFeaturePage('Baca Al Quran', const QuranTab());
        break;
      case HomeFeatureAction.bukaDoa:
        _openFeaturePage('Kumpulan Doa', const DoaTab());
        break;
      case HomeFeatureAction.cariSurah:
        _openFeaturePage('Cari Surah', const SearchSurahTab());
        break;
      case HomeFeatureAction.konversiWaktu:
        Navigator.of(context)
            .push(
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 320),
                reverseTransitionDuration: const Duration(milliseconds: 260),
                pageBuilder: (_, __, ___) => const TimeConversionPage(),
                transitionsBuilder: (context, animation, secondary, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.06, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(slide),
                      child: child,
                    ),
                  );
                },
              ),
            )
            .then((_) {
              if (!mounted) return;
              setState(() => _dashboardRefreshSignal++);
            });
        break;
      case HomeFeatureAction.chatbot:
        _showFeatureInfo(
          'Chatbot',
          'Siapkan endpoint AI/chat service lalu hubungkan ke halaman chat.',
        );
        break;
      case HomeFeatureAction.zakatDonasi:
        _showFeatureInfo(
          'Zakat & Donasi',
          'Tambahkan kalkulator zakat dan integrasi payment gateway.',
        );
        break;
      case HomeFeatureAction.jadwalDunia:
        _showFeatureInfo(
          'Info',
          'Fitur ini sudah dipadukan ke menu Waktu & Sholat ID.',
        );
        break;
      case HomeFeatureAction.masjidTerdekat:
        _showFeatureInfo(
          'Cari Masjid Terdekat',
          'Butuh izin lokasi dan integrasi map service.',
        );
        break;
      case HomeFeatureAction.arahKiblat:
        _showFeatureInfo(
          'Penunjuk Arah Kiblat',
          'Butuh sensor kompas, lokasi, dan kalibrasi perangkat.',
        );
        break;
      case HomeFeatureAction.shakeSurah:
        _showFeatureInfo(
          'Shake Surah',
          'Butuh plugin gyroscope untuk mendeteksi gesture shake.',
        );
        break;
      case HomeFeatureAction.miniGames:
        _showFeatureInfo(
          'Minigames Sambung Ayat',
          'Siapkan bank soal ayat dan mode skor.',
        );
        break;
      case HomeFeatureAction.notifSholat:
        _showFeatureInfo(
          'Notifikasi Pengingat Sholat',
          'Butuh local notifications dan penjadwalan alarm.',
        );
        break;
    }
  }

  void _openFeaturePage(String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: child,
          backgroundColor: const Color(0xFFF4F7F8),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      setState(() => _selectedNavIndex = _currentPage);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showFeatureInfo(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status: dalam roadmap.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F6D5F),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF3F6FA);

    final pages = <Widget>[
      DashboardTab(
        key: ValueKey('dashboard-$_dashboardRefreshSignal'),
        features: _homeOnlyFeatures,
        onTapFeature: _onHomeFeatureTap,
        userName: widget.userName,
      ),
      ProfileTab(userName: widget.userName),
      const SaranKesanTab(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 14,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1F9),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1F5577),
                size: 20,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello ${widget.userName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6A7987),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16354A),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showFeatureInfo(
              'Notifikasi',
              'Panel notifikasi akan dihubungkan ke pengingat sholat.',
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1B4D6A),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: _currentPage, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) {
          if (index == _navLogout) {
            setState(() => _selectedNavIndex = _navLogout);
            _handleLogout();
            return;
          }
          setState(() {
            _selectedNavIndex = index;
            _currentPage = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD8ECE7),
        surfaceTintColor: Colors.white,
        elevation: 4,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFFDFF3EE),
              child: Icon(Icons.person_outline, size: 16),
            ),
            selectedIcon: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF0A6C5D),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.feedback_outlined),
            selectedIcon: Icon(Icons.feedback_rounded),
            label: 'Saran TPM',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout_outlined),
            selectedIcon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
