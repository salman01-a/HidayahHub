import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../models/surah.dart';
import '../../services/equran_service.dart';
import 'shared_widgets.dart';

class ShakeSurahView extends StatefulWidget {
  const ShakeSurahView({super.key});

  @override
  State<ShakeSurahView> createState() => _ShakeSurahViewState();
}

class _ShakeSurahViewState extends State<ShakeSurahView> {
  static const double _gravity = 9.80665;
  static const double _defaultThresholdG = 2.4;
  static const Duration _cooldown = Duration(milliseconds: 900);

  final Random _random = Random();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Future<List<Surah>>? _surahFuture;

  Surah? _pickedSurah;
  final List<Surah> _history = <Surah>[];
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isListening = true;
  bool _isLocked = false;
  bool _sensorAvailable = true;
  bool _shakePulse = false;
  double _thresholdG = _defaultThresholdG;
  int _shakeCount = 0;

  @override
  void initState() {
    super.initState();
    _surahFuture = EQuranService.instance.getSurahList();
    _startListening();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _startListening() {
    _accelSub?.cancel();
    try {
      _accelSub = accelerometerEvents.listen(
        (event) async {
          if (!_isListening) return;

          final gX = event.x / _gravity;
          final gY = event.y / _gravity;
          final gZ = event.z / _gravity;
          final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

          if (gForce < _thresholdG) return;

          final now = DateTime.now();
          if (now.difference(_lastShakeAt) < _cooldown) return;
          _lastShakeAt = now;

          final list = await _surahFuture;
          if (!mounted || list == null || list.isEmpty) return;

          setState(() {
            _shakeCount += 1;
          });
          _triggerShakeAnimation();

          if (_isLocked && _pickedSurah != null) {
            return;
          }

          _pickRandomSurah(list);
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _sensorAvailable = false;
            _isListening = false;
          });
        },
        cancelOnError: false,
      );
    } on MissingPluginException {
      setState(() {
        _sensorAvailable = false;
        _isListening = false;
      });
    } catch (_) {
      setState(() {
        _sensorAvailable = false;
        _isListening = false;
      });
    }
  }

  void _triggerShakeAnimation() {
    if (!mounted) return;
    setState(() {
      _shakePulse = true;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _shakePulse = false;
      });
    });
  }

  void _pickRandomSurah(List<Surah> list) {
    Surah selected = list[_random.nextInt(list.length)];
    if (_pickedSurah != null && list.length > 1) {
      while (selected.nomor == _pickedSurah!.nomor) {
        selected = list[_random.nextInt(list.length)];
      }
    }

    setState(() {
      _pickedSurah = selected;
      _history.removeWhere((s) => s.nomor == selected.nomor);
      _history.insert(0, selected);
      if (_history.length > 5) {
        _history.removeRange(5, _history.length);
      }
    });
  }

  void _toggleListening() {
    if (!_sensorAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sensor belum aktif pada sesi ini. Lakukan full restart aplikasi.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isListening = !_isListening;
    });
  }

  Future<void> _manualRandomPick() async {
    final list = await _surahFuture;
    if (!mounted || list == null || list.isEmpty) return;
    _pickRandomSurah(list);
    _triggerShakeAnimation();
  }

  Future<void> _refreshSurah() async {
    setState(() {
      _surahFuture = EQuranService.instance.getSurahList();
      _pickedSurah = null;
      _shakeCount = 0;
      _history.clear();
    });
    await _surahFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: _surahFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorPane(error: snapshot.error.toString());
        }

        final surahList = snapshot.data ?? const <Surah>[];
        return RefreshIndicator(
          onRefresh: _refreshSurah,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _HeroShakeCard(
                listening: _isListening,
                locked: _isLocked,
                sensorAvailable: _sensorAvailable,
                shakeCount: _shakeCount,
                thresholdG: _thresholdG,
                onToggle: _toggleListening,
                onRandomNow: _manualRandomPick,
                onLockToggle: (value) => setState(() => _isLocked = value),
                onThresholdChanged: (value) =>
                    setState(() => _thresholdG = value),
              ),
              const SizedBox(height: 14),
              if (_pickedSurah == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8EE)),
                  ),
                  child: Text(
                    !_sensorAvailable
                        ? 'Sensor belum tersedia pada sesi ini.\nLakukan full restart aplikasi, lalu buka menu Shake Surah kembali.'
                        : surahList.isEmpty
                        ? 'Data surah belum tersedia.'
                        : 'Goyangkan HP untuk memilih surah secara acak.\n\nTips: jika terlalu sensitif, naikkan slider sensitivitas.',
                    style: const TextStyle(height: 1.4),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surah Terpilih',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: _shakePulse ? 1.035 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _shakePulse
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2EA5A0,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : const [],
                        ),
                        child: SurahCard(surah: _pickedSurah!),
                      ),
                    ),
                  ],
                ),
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Riwayat 5 Hasil Terakhir',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 10),
                ..._history.map(
                  (surah) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurahCard(surah: surah),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroShakeCard extends StatelessWidget {
  final bool listening;
  final bool locked;
  final bool sensorAvailable;
  final int shakeCount;
  final double thresholdG;
  final VoidCallback onToggle;
  final VoidCallback onRandomNow;
  final ValueChanged<bool> onLockToggle;
  final ValueChanged<double> onThresholdChanged;

  const _HeroShakeCard({
    required this.listening,
    required this.locked,
    required this.sensorAvailable,
    required this.shakeCount,
    required this.thresholdG,
    required this.onToggle,
    required this.onRandomNow,
    required this.onLockToggle,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF204D7A), Color(0xFF1A7F8A), Color(0xFF37A477)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154462).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shake Surah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            !sensorAvailable
                ? 'Sensor tidak aktif saat ini. Gunakan Acak Lagi atau lakukan full restart app.'
                : listening
                ? 'Mode aktif. Goyangkan perangkat untuk memilih surah random.'
                : 'Mode jeda. Aktifkan kembali untuk deteksi shake.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusPill(
                label: listening ? 'Listening' : 'Paused',
                icon: listening ? Icons.sensors : Icons.pause_circle,
              ),
              const SizedBox(width: 8),
              _StatusPill(label: 'Shake: $shakeCount', icon: Icons.vibration),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3249),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  listening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(listening ? 'Pause' : 'Aktifkan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRandomNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3249),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('Acak Lagi'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lock hasil (shake tidak mengubah surah)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: locked,
                onChanged: onLockToggle,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF0A3249),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Sensitivitas Shake',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SliderTheme(
            data: const SliderThemeData(
              thumbColor: Colors.white,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white38,
            ),
            child: Slider(
              min: 1.6,
              max: 3.2,
              value: thresholdG,
              onChanged: onThresholdChanged,
            ),
          ),
          Text(
            'Threshold: ${thresholdG.toStringAsFixed(2)}g',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
