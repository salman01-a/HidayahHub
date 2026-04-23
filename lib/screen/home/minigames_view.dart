// File: lib/views/home/minigame_view.dart

import 'package:flutter/material.dart';
import '../../controllers/minigame_controller.dart';
import '../../models/minigames.dart';

class MinigameView extends StatefulWidget {
  const MinigameView({super.key});

  @override
  State<MinigameView> createState() => _MinigameViewState();
}

class _MinigameViewState extends State<MinigameView> {
  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _deepTeal = Color(0xFF0F5A4E);
  static const Color _bg = Color(0xFFF8FAFB);
  static const double _answerCardHeight = 96;

  late final MinigameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MinigameController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _bg, body: _buildBody());
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryTeal),
      );
    }

    if (!_controller.isGameStarted) {
      return _buildStartScreen();
    }

    if (_controller.isGameOver) {
      return _buildGameOverScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryTeal, _deepTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minigame Sambung Ayat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pilih tingkat kesulitan lalu uji hafalanmu dengan soal ayat acak dari API Quran.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tingkat Kesulitan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MinigameDifficulty.values
                  .map((difficulty) {
                    final isSelected =
                        _controller.selectedDifficulty == difficulty;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text('${difficulty.label}'),
                      onSelected: (_) => _controller.setDifficulty(difficulty),
                      selectedColor: const Color(0xFFD6F2EC),
                      side: BorderSide(
                        color: isSelected ? _primaryTeal : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? _deepTeal : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
            if (_controller.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEAEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5A5A5)),
                ),
                child: Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: Color(0xFF9A2525)),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _controller.startGame,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text(
                  'Mulai Main',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildScoreHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final question = _controller.currentQuestion;
    if (question == null) {
      return const Center(child: Text('Soal belum tersedia.'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Status (Skor & Progress)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soal ${_controller.currentIndex + 1}/${_controller.totalQuestions}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Skor: ${_controller.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Kartu Pertanyaan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Surah ${question.surahName} • ${_controller.selectedDifficulty.label}',
                    style: const TextStyle(
                      color: Color(0xFFCBA052),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.questionAyat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _deepTeal,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Apa lanjutan ayat di atas?',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pilihan Jawaban
            Column(
              children: [
                for (var i = 0; i < question.options.length; i++) ...[
                  _buildAnswerOption(question, i),
                  if (i < question.options.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(MinigameQuestion question, int index) {
    final isSelected = _controller.selectedAnswerIndex == index;
    final isCorrectAnswer = index == question.correctAnswerIndex;

    Color btnColor = Colors.white;
    Color textColor = Colors.black87;
    Color borderColor = Colors.grey.shade300;

    if (_controller.isAnswerChecked) {
      if (isCorrectAnswer) {
        btnColor = const Color(0xFFE8F8F5);
        textColor = const Color(0xFF1A7F6D);
        borderColor = const Color(0xFF1A7F6D);
      } else if (isSelected && !isCorrectAnswer) {
        btnColor = const Color(0xFFFDEDEC);
        textColor = const Color(0xFFC0392B);
        borderColor = const Color(0xFFC0392B);
      }
    }

    return InkWell(
      onTap: () => _controller.submitAnswer(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _answerCardHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Text(
          question.options[index],
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFCBA052),
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              'Masya Allah!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _deepTeal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mode ${_controller.selectedDifficulty.label} selesai.\nSkor akhir kamu:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_controller.score}/${_controller.maxScore}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: _primaryTeal,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _controller.restartGame,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Main Lagi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _controller.restartGame,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Kembali ke Menu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deepTeal,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHistoryCard() {
    final history = _controller.history;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Skor',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Text(
              'Belum ada riwayat permainan.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...history.take(8).map((item) {
              final date = item.playedAt;
              final dateLabel =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.difficulty.label} • $dateLabel',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${item.score}/${item.maxScore}',
                      style: const TextStyle(
                        color: _primaryTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
