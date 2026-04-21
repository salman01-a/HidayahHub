// File: lib/views/home/minigame_view.dart

import 'package:flutter/material.dart';
import '../../controllers/minigame_controller.dart';

class MinigameView extends StatefulWidget {
  const MinigameView({super.key});

  @override
  State<MinigameView> createState() => _MinigameViewState();
}

class _MinigameViewState extends State<MinigameView> {
  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _deepTeal = Color(0xFF0F5A4E);
  static const Color _bg = Color(0xFFF8FAFB);

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
    return Scaffold(
      backgroundColor: _bg,
      body: _controller.isGameOver ? _buildGameOverScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    final question = _controller.currentQuestion;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status (Skor & Progress)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${_controller.currentIndex + 1}/${_controller.totalQuestions}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Skor: ${_controller.score}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Kartu Pertanyaan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Surah ${question.surahName}',
                  style: const TextStyle(color: Color(0xFFCBA052), fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  question.questionAyat,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _deepTeal, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Apa lanjutan ayat di atas?',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pilihan Jawaban
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final isSelected = _controller.selectedAnswerIndex == index;
                final isCorrectAnswer = index == question.correctAnswerIndex;
                
                // Menentukan warna tombol setelah dijawab
                Color btnColor = Colors.white;
                Color textColor = Colors.black87;
                Color borderColor = Colors.grey.shade300;

                if (_controller.isAnswerChecked) {
                  if (isCorrectAnswer) {
                    btnColor = const Color(0xFFE8F8F5); // Hijau
                    textColor = const Color(0xFF1A7F6D);
                    borderColor = const Color(0xFF1A7F6D);
                  } else if (isSelected && !isCorrectAnswer) {
                    btnColor = const Color(0xFFFDEDEC); // Merah
                    textColor = const Color(0xFFC0392B);
                    borderColor = const Color(0xFFC0392B);
                  }
                }

                return InkWell(
                  onTap: () => _controller.submitAnswer(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                    ),
                    child: Text(
                      question.options[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFCBA052), size: 100),
            const SizedBox(height: 24),
            const Text(
              'Masya Allah!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _deepTeal),
            ),
            const SizedBox(height: 12),
            Text(
              'Kamu berhasil menyelesaikan kuis.\nSkor akhir kamu:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              '${_controller.score}',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: _primaryTeal),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _controller.restartGame,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Main Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}