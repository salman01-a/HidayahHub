import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/home_controller.dart';
import 'home/dashboard_view.dart';
import 'home/doa_view.dart';
import 'home/home_feature.dart';
import 'home/profile_view.dart';
import 'home/quran_view.dart';
import 'home/last_read_view.dart';
import 'home/nearby_mosque_view.dart';
import 'home/saran_kesan_view.dart';
import 'home/shake_surah_view.dart';
import 'home/time_conversion_view.dart';
import 'home/qibla_view.dart';
import 'login_page.dart';
import 'home/chatbot_view.dart';
import 'home/minigames_view.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _sessionLoggedInKey = 'session_logged_in';
  static const String _sessionUserNameKey = 'session_user_name';

  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.addListener(_onControllerChanged);
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

  void _onHomeFeatureTap(HomeFeature feature) {
    switch (feature.action) {
      case HomeFeatureAction.bukaQuran:
        _openFeaturePage('Baca Al Quran', const QuranView());
        break;
      case HomeFeatureAction.bukaDoa:
        _openFeaturePage('Kumpulan Doa', const DoaView());
        break;
      case HomeFeatureAction.terakhirDibaca:
        _openFeaturePage('Terakhir Dibaca', const LastReadView());
        break;
      case HomeFeatureAction.konversiWaktu:
        Navigator.of(context)
            .push(
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 320),
                reverseTransitionDuration: const Duration(milliseconds: 260),
                pageBuilder: (_, __, ___) => const TimeConversionView(),
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
              _controller.refreshDashboardSignal();
            });
        break;
      case HomeFeatureAction.chatbot:
        // _showFeatureInfo(
        //   'Chatbot',
        //   'Siapkan endpoint AI/chat service lalu hubungkan ke halaman chat.',
        // );
        _openFeaturePage('Chatbot', const ChatbotView());
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
        _openFeaturePage('Cari Masjid Terdekat', const NearbyMosqueView());
        break;
      case HomeFeatureAction.arahKiblat:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QiblaView()));
        break;
      case HomeFeatureAction.shakeSurah:
        _openFeaturePage('Shake Surah', const ShakeSurahView());
        break;
      case HomeFeatureAction.miniGames:
        // _showFeatureInfo(
        //   'Minigames Sambung Ayat',
        //   'Siapkan bank soal ayat dan mode skor.',
        // );
        _openFeaturePage('Minigames Sambung Ayat', const MinigameView());
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
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(
              // color: Color(0xFF1A7F6D),
            ),
            title: Text(
              title,
              style: const TextStyle(
                // color: Color(0xFF0F5A4E), // Warna text: deepTeal
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
          ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFE8F4F1), // backgroundStart
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Color(0xFF1A7F6D), // primaryTeal
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Keluar Akun',
              style: TextStyle(
                color: Color(0xFF0F5A4E), // deepTeal
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari Hidayah Hub? Anda harus login kembali untuk masuk.',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A7F6D), // primaryTeal
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF1A7F6D).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      _controller.resetSelectedToCurrent();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionLoggedInKey);
    await prefs.remove(_sessionUserNameKey);

    if (!mounted) return;

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
      DashboardView(
        key: ValueKey('dashboard-${_controller.dashboardRefreshSignal}'),
        features: _controller.homeOnlyFeatures,
        onTapFeature: _onHomeFeatureTap,
        userName: widget.userName,
      ),
      ProfileView(userName: widget.userName),
      const SaranKesanView(),
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
      body: IndexedStack(index: _controller.currentPage, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _controller.selectedNavIndex,
        onDestinationSelected: (index) {
          if (index == HomeController.navLogout) {
            _controller.setLogoutSelected();
            _handleLogout();
            return;
          }
          _controller.selectDestination(index);
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
