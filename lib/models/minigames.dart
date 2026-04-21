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