import 'package:flutter/material.dart';

enum HomeFeatureAction {
  bukaQuran,
  bukaDoa,
  terakhirDibaca,
  konversiWaktu,
  chatbot,
  zakatDonasi,
  jadwalDunia,
  masjidTerdekat,
  arahKiblat,
  shakeSurah,
  miniGames,
  notifSholat,
}

class HomeFeature {
  final String title;
  final IconData icon;
  final Color color;
  final HomeFeatureAction action;
  final bool availableNow;

  const HomeFeature({
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
    required this.availableNow,
  });
}
