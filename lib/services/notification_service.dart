import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/minigames.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_logo'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _notificationsPlugin.initialize(settings: initSettings);
  }

  // Fungsi untuk menjadwalkan 5 waktu sholat sekaligus
  Future<void> schedulePrayerNotifications({
    required Map<String, TimeOfDay> prayerTimes,
    required DateTime nowLocal,
  }) async {
    await _notificationsPlugin.cancelAll();

    const platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'sholat_channel',
        'Pengingat Sholat',
        channelDescription: 'Notifikasi waktu sholat HidayahHub',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF1A7F6D),
        icon: 'ic_stat_logo',
      ),
      iOS: DarwinNotificationDetails(),
    );

    prayerTimes.forEach((name, time) async {
      final prayerDt = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
        time.hour,
        time.minute,
      );

      if (prayerDt.isAfter(nowLocal)) {
        await _notificationsPlugin.zonedSchedule(
          id: name.hashCode,
          title: 'Waktunya Sholat $name',
          body: 'Mari tunaikan ibadah sholat $name tepat waktu.',
          scheduledDate: tz.TZDateTime.from(prayerDt, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    });
  }

  // Fungsi khusus untuk mematikan semua notifikasi
  Future<void> cancelAllNotif() async {
    await _notificationsPlugin.cancelAll();
  }

  // Fungsi untuk memunculkan notifikasi instan untuk pengetesan
  Future<void> showTestNotification() async {
    const platformDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifikasi',
        channelDescription: 'Channel untuk tes fitur notifikasi',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF1A7F6D),
        icon: 'ic_stat_logo', // Pastikan ikon ini terdaftar
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Tembak notifikasi instan sekarang juga
    await _notificationsPlugin.show(
      id: 999,
      title: 'Alhamdulillah 🕌',
      body: 'Pengingat waktu sholat HidayahHub berhasil diaktifkan!',
      notificationDetails: platformDetails,
    );
  }

  Future<void> showMinigameHighScoreNotification({
    required MinigameDifficulty difficulty,
    required int score,
    required int maxScore,
  }) async {
    final platformDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'minigame_channel',
        'Notifikasi Minigame',
        channelDescription: 'Notifikasi rekor minigame HidayahHub',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF1A7F6D),
        icon: 'ic_stat_logo',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: 2000 + difficulty.index,
      title: 'Rekor Baru Minigame ${difficulty.label}',
      body: 'Masya Allah! Skor tertinggi kamu sekarang $score/$maxScore.',
      notificationDetails: platformDetails,
    );
  }

  Future<void> requestPermission() async {
    // Khusus Android 13 ke atas
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin
          .requestExactAlarmsPermission(); // Wajib buat alarm jadwal sholat
    }

    // Khusus iOS
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
}
