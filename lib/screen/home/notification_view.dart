import 'package:flutter/material.dart';
import 'package:hidayahhub/services/notification_service.dart';
import '../../controllers/dashboard_controller.dart';

class PrayerNotificationView extends StatefulWidget {
  final DashboardController controller;

  const PrayerNotificationView({super.key, required this.controller});

  @override
  State<PrayerNotificationView> createState() => _PrayerNotificationViewState();
}

class _PrayerNotificationViewState extends State<PrayerNotificationView> {
  // Fungsi pendengar agar UI update saat controller berubah
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Daftarkan listener saat halaman dibuka
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    // Hapus listener saat halaman ditutup biar nggak memory leak
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktifkan fitur ini agar kamu selalu diingatkan saat waktu sholat tiba.',
              style: TextStyle(color: Color(0xFF647377), height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE1ECEA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                secondary: CircleAvatar(
                  backgroundColor: widget.controller.isNotifSholatActive
                      ? const Color(0xFFDDF1EF)
                      : Colors.grey.shade100,
                  child: Icon(
                    widget.controller.isNotifSholatActive
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: widget.controller.isNotifSholatActive
                        ? const Color(0xFF0A6C5D)
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Pengingat Waktu Sholat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF24344A),
                  ),
                ),
                subtitle: const Text('Subuh, Dzuhur, Ashar, Maghrib, Isya'),
                activeColor: const Color(0xFF1A7F6D),
                value: widget.controller.isNotifSholatActive,
                onChanged: (val) {
                  widget.controller.toggleSemuaNotif(val);
                  if (val) {
                    NotificationService.instance.showTestNotification();
                  }
                  // 3. (Opsional) Tetap kasih SnackBar kecil di dalam app
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'Notifikasi diaktifkan' : 'Notifikasi dimatikan',
                      ),
                      backgroundColor: val
                          ? const Color(0xFF1A7F6D)
                          : Colors.grey.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
