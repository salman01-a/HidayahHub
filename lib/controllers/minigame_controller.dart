import 'package:flutter/material.dart';
import '../models/minigames.dart';
import '../services/minigames_service.dart';

class MinigameController extends ChangeNotifier {
  final MinigameService _service = MinigameService();
  bool _disposed = false;

  List<MinigameQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameOver = false;

  // State untuk animasi benar/salah
  int? _selectedAnswerIndex;
  bool _isAnswerChecked = false;

  MinigameController() {
    _initGame();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _initGame() {
    _questions = _service.getQuestions();
    _questions.shuffle(); // Acak urutan soal
    _currentIndex = 0;
    _score = 0;
    _isGameOver = false;
    _selectedAnswerIndex = null;
    _isAnswerChecked = false;
    _safeNotify();
  }

  // Getters
  MinigameQuestion get currentQuestion => _questions[_currentIndex];
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerChecked => _isAnswerChecked;

  // Fungsi saat user milih jawaban
  Future<void> submitAnswer(int index) async {
    if (_disposed) return;
    if (_isAnswerChecked) return; // Cegah double tap

    _selectedAnswerIndex = index;
    _isAnswerChecked = true;

    // Cek jawaban
    if (index == currentQuestion.correctAnswerIndex) {
      _score += 10; // Tambah poin kalau benar
    }

    _safeNotify();

    // Jeda 1.2 detik biar user bisa lihat warnanya (hijau/merah)
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_disposed) return;

    // Lanjut ke soal berikutnya atau akhiri game
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
    } else {
      _isGameOver = true;
    }

    _safeNotify();
  }

  void restartGame() {
    _initGame();
  }
}
