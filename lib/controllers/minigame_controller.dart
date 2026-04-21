import 'package:flutter/material.dart';
import '../models/minigames.dart';
import '../services/minigames_service.dart';

class MinigameController extends ChangeNotifier {
  final MinigameService _service = MinigameService();
  bool _disposed = false;

  List<MinigameQuestion> _questions = [];
  List<MinigameScoreHistory> _history = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameStarted = false;
  bool _isGameOver = false;
  bool _isLoading = false;
  String? _errorMessage;
  MinigameDifficulty _selectedDifficulty = MinigameDifficulty.easy;

  int? _selectedAnswerIndex;
  bool _isAnswerChecked = false;

  MinigameController() {
    _loadHistory();
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

  void _resetRoundState() {
    _currentIndex = 0;
    _score = 0;
    _isGameOver = false;
    _selectedAnswerIndex = null;
    _isAnswerChecked = false;
  }

  Future<void> _loadHistory() async {
    try {
      _history = await _service.loadScoreHistory();
    } catch (_) {
      _history = <MinigameScoreHistory>[];
    }
    _safeNotify();
  }

  MinigameQuestion? get currentQuestion {
    if (_questions.isEmpty || _currentIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentIndex];
  }
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  int get score => _score;
  int get maxScore => totalQuestions * 10;
  bool get isGameStarted => _isGameStarted;
  bool get isGameOver => _isGameOver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MinigameDifficulty get selectedDifficulty => _selectedDifficulty;
  List<MinigameScoreHistory> get history => List<MinigameScoreHistory>.unmodifiable(_history);
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerChecked => _isAnswerChecked;

  void setDifficulty(MinigameDifficulty difficulty) {
    if (_isLoading || _isGameStarted) {
      return;
    }
    _selectedDifficulty = difficulty;
    _safeNotify();
  }

  Future<void> startGame([MinigameDifficulty? difficulty]) async {
    if (_isLoading) {
      return;
    }

    if (difficulty != null) {
      _selectedDifficulty = difficulty;
    }

    _isLoading = true;
    _errorMessage = null;
    _isGameStarted = false;
    _resetRoundState();
    _safeNotify();

    try {
      final questions = await _service.getQuestions(_selectedDifficulty);
      _questions = questions;
      _isGameStarted = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _questions = <MinigameQuestion>[];
      _isGameStarted = false;
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> submitAnswer(int index) async {
    if (_disposed) return;
    if (!_isGameStarted || _isGameOver || _questions.isEmpty) return;
    if (_isAnswerChecked) return; // Cegah double tap

    final question = currentQuestion;
    if (question == null) return;

    _selectedAnswerIndex = index;
    _isAnswerChecked = true;

    if (index == question.correctAnswerIndex) {
      _score += 10;
    }

    _safeNotify();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (_disposed) return;

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
    } else {
      _isGameOver = true;
      await _saveScoreToHistory();
    }

    _safeNotify();
  }

  Future<void> _saveScoreToHistory() async {
    final historyItem = MinigameScoreHistory(
      difficulty: _selectedDifficulty,
      score: _score,
      maxScore: maxScore,
      totalQuestions: totalQuestions,
      playedAt: DateTime.now(),
    );

    await _service.saveScoreHistory(historyItem);
    _history = await _service.loadScoreHistory();
  }

  void restartGame() {
    _isGameStarted = false;
    _isGameOver = false;
    _resetRoundState();
    _safeNotify();
  }
}
