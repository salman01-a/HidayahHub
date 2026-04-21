class MinigameQuestion {
  final String surahName;
  final String questionAyat;
  final List<String> options;
  final int correctAnswerIndex;

  MinigameQuestion({
    required this.surahName,
    required this.questionAyat,
    required this.options,
    required this.correctAnswerIndex,
  });
}

enum MinigameDifficulty {
  easy,
  medium,
  hard,
}

extension MinigameDifficultyX on MinigameDifficulty {
  String get label {
    switch (this) {
      case MinigameDifficulty.easy:
        return 'Mudah';
      case MinigameDifficulty.medium:
        return 'Sedang';
      case MinigameDifficulty.hard:
        return 'Hard';
    }
  }

  int get questionCount {
    switch (this) {
      case MinigameDifficulty.easy:
        return 5;
      case MinigameDifficulty.medium:
        return 8;
      case MinigameDifficulty.hard:
        return 10;
    }
  }

  int get optionCount {
    switch (this) {
      case MinigameDifficulty.easy:
        return 3;
      case MinigameDifficulty.medium:
        return 4;
      case MinigameDifficulty.hard:
        return 5;
    }
  }
}

class MinigameScoreHistory {
  final MinigameDifficulty difficulty;
  final int score;
  final int maxScore;
  final int totalQuestions;
  final DateTime playedAt;

  const MinigameScoreHistory({
    required this.difficulty,
    required this.score,
    required this.maxScore,
    required this.totalQuestions,
    required this.playedAt,
  });

  factory MinigameScoreHistory.fromMap(Map<String, dynamic> map) {
    final rawDifficulty = (map['difficulty'] as String?) ?? '';
    final parsedDifficulty = MinigameDifficulty.values.firstWhere(
      (difficulty) => difficulty.name == rawDifficulty,
      orElse: () => MinigameDifficulty.easy,
    );

    return MinigameScoreHistory(
      difficulty: parsedDifficulty,
      score: map['score'] as int? ?? 0,
      maxScore: map['maxScore'] as int? ?? 0,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      playedAt: DateTime.tryParse((map['playedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'difficulty': difficulty.name,
      'score': score,
      'maxScore': maxScore,
      'totalQuestions': totalQuestions,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}