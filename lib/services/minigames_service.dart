import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/minigames.dart';
import '../models/surah_detail.dart';
import 'equran_service.dart';
import 'session_service.dart';

class MinigameService {
  static const String _historyKeyPrefix = 'minigame_score_history_v1';

  final Random _random = Random();
  final Map<int, SurahDetail> _detailCache = <int, SurahDetail>{};

  Future<List<MinigameQuestion>> getQuestions(MinigameDifficulty difficulty) async {
    final questions = <MinigameQuestion>[];
    final usedQuestionSignatures = <String>{};
    final candidateSurah = _candidateSurahNumbers(difficulty);
    final maxAttempt = difficulty.questionCount * 20;

    int attempt = 0;
    while (questions.length < difficulty.questionCount && attempt < maxAttempt) {
      attempt++;
      final surahNumber = candidateSurah[_random.nextInt(candidateSurah.length)];
      final detail = await _getSurahDetailCached(surahNumber);
      if (detail.ayat.length < 2) {
        continue;
      }

      final q = _buildQuestion(detail, difficulty);
      if (q == null) {
        continue;
      }

      final signature = '${detail.nomor}:${q.questionAyat}';
      if (usedQuestionSignatures.contains(signature)) {
        continue;
      }

      usedQuestionSignatures.add(signature);
      questions.add(q);
    }

    if (questions.isEmpty) {
      throw Exception('Soal dinamis belum berhasil dimuat. Coba lagi sebentar.');
    }

    questions.shuffle(_random);
    return questions;
  }

  Future<List<MinigameScoreHistory>> loadScoreHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveHistoryKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <MinigameScoreHistory>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <MinigameScoreHistory>[];
    }

    final history = decoded
        .whereType<Map<String, dynamic>>()
        .map(MinigameScoreHistory.fromMap)
        .toList(growable: false)
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return history;
  }

  Future<void> saveScoreHistory(MinigameScoreHistory item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadScoreHistory();
    final next = <MinigameScoreHistory>[item, ...current]
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    final trimmed = next.take(20).map((e) => e.toMap()).toList(growable: false);
    final key = await _resolveHistoryKey();
    await prefs.setString(key, jsonEncode(trimmed));
  }

  Future<String> _resolveHistoryKey() async {
    final email = await SessionService.instance.getLastEmail();
    final normalized = (email ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return '${_historyKeyPrefix}_guest';
    }

    final safeEmail = normalized.replaceAll(RegExp(r'[^a-z0-9@._-]'), '_');
    return '${_historyKeyPrefix}_$safeEmail';
  }

  Future<SurahDetail> _getSurahDetailCached(int surahNumber) async {
    final cached = _detailCache[surahNumber];
    if (cached != null) {
      return cached;
    }

    final detail = await EQuranService.instance.getSurahDetail(surahNumber);
    _detailCache[surahNumber] = detail;
    return detail;
  }

  List<int> _candidateSurahNumbers(MinigameDifficulty difficulty) {
    switch (difficulty) {
      case MinigameDifficulty.easy:
        return List<int>.generate(114 - 93 + 1, (index) => index + 93);
      case MinigameDifficulty.medium:
        return List<int>.generate(114 - 78 + 1, (index) => index + 78);
      case MinigameDifficulty.hard:
        return List<int>.generate(114, (index) => index + 1);
    }
  }

  MinigameQuestion? _buildQuestion(SurahDetail detail, MinigameDifficulty difficulty) {
    if (detail.ayat.length < 2) {
      return null;
    }

    final baseIndex = _random.nextInt(detail.ayat.length - 1);
    final currentAyat = detail.ayat[baseIndex];
    final correctAyat = detail.ayat[baseIndex + 1];

    final correctText = _formatAyat(correctAyat);
    final optionSet = <String>{correctText};

    final localDistractors = detail.ayat
        .asMap()
        .entries
        .where((entry) => entry.key != baseIndex + 1)
        .map((entry) => _formatAyat(entry.value))
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: true)
      ..shuffle(_random);

    for (final candidate in localDistractors) {
      if (optionSet.length >= difficulty.optionCount) {
        break;
      }
      optionSet.add(candidate);
    }

    if (optionSet.length < difficulty.optionCount) {
      return null;
    }

    final options = optionSet.toList(growable: true)..shuffle(_random);
    final correctIndex = options.indexOf(correctText);

    if (correctIndex < 0) {
      return null;
    }

    return MinigameQuestion(
      surahName: detail.namaLatin,
      questionAyat: _formatAyat(currentAyat),
      options: options,
      correctAnswerIndex: correctIndex,
    );
  }

  String _formatAyat(SurahAyat ayat) {
    final arab = ayat.teksArab.trim();
    final latin = ayat.teksLatin.trim();
    if (latin.isEmpty || latin == '-') {
      return arab;
    }
    return '$arab\n($latin)';
  }
}
