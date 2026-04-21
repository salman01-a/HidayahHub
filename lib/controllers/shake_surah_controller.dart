import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/surah.dart';
import '../services/equran_service.dart';

class ShakeSurahController extends ChangeNotifier {
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
  bool _disposed = false;

  Future<List<Surah>>? get surahFuture => _surahFuture;
  Surah? get pickedSurah => _pickedSurah;
  List<Surah> get history => List<Surah>.unmodifiable(_history);
  bool get isListening => _isListening;
  bool get isLocked => _isLocked;
  bool get sensorAvailable => _sensorAvailable;
  bool get shakePulse => _shakePulse;
  double get thresholdG => _thresholdG;
  int get shakeCount => _shakeCount;

  void initialize() {
    _surahFuture = EQuranService.instance.getSurahList();
    _startListening();
  }

  Future<void> refreshSurah() async {
    _surahFuture = EQuranService.instance.getSurahList();
    _pickedSurah = null;
    _shakeCount = 0;
    _history.clear();
    _safeNotify();
    await _surahFuture;
  }

  void setLock(bool value) {
    _isLocked = value;
    _safeNotify();
  }

  void setThreshold(double value) {
    _thresholdG = value;
    _safeNotify();
  }

  String? toggleListening() {
    if (!_sensorAvailable) {
      return 'Sensor belum aktif pada sesi ini. Lakukan full restart aplikasi.';
    }

    _isListening = !_isListening;
    _safeNotify();
    return null;
  }

  Future<void> manualRandomPick() async {
    final list = await _surahFuture;
    if (_disposed || list == null || list.isEmpty) return;
    _pickRandomSurah(list);
    _triggerShakeAnimation();
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
          if (_disposed || list == null || list.isEmpty) return;

          _shakeCount += 1;
          _safeNotify();
          _triggerShakeAnimation();

          if (_isLocked && _pickedSurah != null) {
            return;
          }

          _pickRandomSurah(list);
        },
        onError: (_) {
          if (_disposed) return;
          _sensorAvailable = false;
          _isListening = false;
          _safeNotify();
        },
        cancelOnError: false,
      );
    } on MissingPluginException {
      _sensorAvailable = false;
      _isListening = false;
      _safeNotify();
    } catch (_) {
      _sensorAvailable = false;
      _isListening = false;
      _safeNotify();
    }
  }

  void _triggerShakeAnimation() {
    if (_disposed) return;
    _shakePulse = true;
    _safeNotify();

    Future.delayed(const Duration(milliseconds: 180), () {
      if (_disposed) return;
      _shakePulse = false;
      _safeNotify();
    });
  }

  void _pickRandomSurah(List<Surah> list) {
    Surah selected = list[_random.nextInt(list.length)];
    if (_pickedSurah != null && list.length > 1) {
      while (selected.nomor == _pickedSurah!.nomor) {
        selected = list[_random.nextInt(list.length)];
      }
    }

    _pickedSurah = selected;
    _history.removeWhere((s) => s.nomor == selected.nomor);
    _history.insert(0, selected);
    if (_history.length > 5) {
      _history.removeRange(5, _history.length);
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _accelSub?.cancel();
    super.dispose();
  }
}
