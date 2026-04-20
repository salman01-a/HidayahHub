import 'package:flutter/material.dart';

import '../screen/home/home_feature.dart';

class HomeController extends ChangeNotifier {
  static const int navHome = 0;
  static const int navLogout = 3;

  int selectedNavIndex = navHome;
  int currentPage = 0;
  int dashboardRefreshSignal = 0;

  final List<HomeFeature> homeOnlyFeatures = const [
    HomeFeature(
      title: 'Baca Al Quran',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3F95D0),
      action: HomeFeatureAction.bukaQuran,
      availableNow: true,
    ),
    HomeFeature(
      title: 'Kumpulan Doa',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF66A64A),
      action: HomeFeatureAction.bukaDoa,
      availableNow: true,
    ),
    HomeFeature(
      title: 'Cari Surah',
      icon: Icons.search_rounded,
      color: Color(0xFF6D72D7),
      action: HomeFeatureAction.cariSurah,
      availableNow: true,
    ),
    HomeFeature(
      title: 'Waktu & Sholat ID',
      icon: Icons.schedule_rounded,
      color: Color(0xFFF0B64A),
      action: HomeFeatureAction.konversiWaktu,
      availableNow: true,
    ),
    HomeFeature(
      title: 'Chatbot',
      icon: Icons.smart_toy_outlined,
      color: Color(0xFF5C78D9),
      action: HomeFeatureAction.chatbot,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Zakat & Donasi',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFF08B4A),
      action: HomeFeatureAction.zakatDonasi,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Cari Masjid',
      icon: Icons.location_on_outlined,
      color: Color(0xFF57B56D),
      action: HomeFeatureAction.masjidTerdekat,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Arah Kiblat',
      icon: Icons.explore_outlined,
      color: Color(0xFF7F72D8),
      action: HomeFeatureAction.arahKiblat,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Shake Surah',
      icon: Icons.vibration_rounded,
      color: Color(0xFF4B8AC2),
      action: HomeFeatureAction.shakeSurah,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Minigames Ayat',
      icon: Icons.extension_outlined,
      color: Color(0xFFD46879),
      action: HomeFeatureAction.miniGames,
      availableNow: false,
    ),
    HomeFeature(
      title: 'Notif Sholat',
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF4BA890),
      action: HomeFeatureAction.notifSholat,
      availableNow: false,
    ),
  ];

  void refreshDashboardSignal() {
    dashboardRefreshSignal++;
    notifyListeners();
  }

  void selectDestination(int index) {
    selectedNavIndex = index;
    currentPage = index;
    notifyListeners();
  }

  void setLogoutSelected() {
    selectedNavIndex = navLogout;
    notifyListeners();
  }

  void resetSelectedToCurrent() {
    selectedNavIndex = currentPage;
    notifyListeners();
  }
}
