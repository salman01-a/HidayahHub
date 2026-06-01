class HadithBook {
  final String id;
  final String name;
  final int available;

  const HadithBook({
    required this.id,
    required this.name,
    required this.available,
  });

  factory HadithBook.fromMap(Map<String, dynamic> map) {
    return HadithBook(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Kitab Hadis',
      available: (map['available'] as num?)?.toInt() ?? 0,
    );
  }
}

class Hadith {
  final int number;
  final String arabic;
  final String translation;

  const Hadith({
    required this.number,
    required this.arabic,
    required this.translation,
  });

  factory Hadith.fromMap(Map<String, dynamic> map) {
    return Hadith(
      number: (map['number'] as num?)?.toInt() ?? 0,
      arabic: map['arab'] as String? ?? '-',
      translation: map['id'] as String? ?? '-',
    );
  }
}

class HadithPage {
  final String bookId;
  final String bookName;
  final int available;
  final int requested;
  final List<Hadith> hadiths;

  const HadithPage({
    required this.bookId,
    required this.bookName,
    required this.available,
    required this.requested,
    required this.hadiths,
  });

  factory HadithPage.fromMap(Map<String, dynamic> map) {
    final rawHadiths = map['hadiths'];

    return HadithPage(
      bookId: map['id'] as String? ?? '',
      bookName: map['name'] as String? ?? 'Kitab Hadis',
      available: (map['available'] as num?)?.toInt() ?? 0,
      requested: (map['requested'] as num?)?.toInt() ?? 0,
      hadiths: rawHadiths is List
          ? rawHadiths
                .whereType<Map<String, dynamic>>()
                .map(Hadith.fromMap)
                .toList(growable: false)
          : const <Hadith>[],
    );
  }
}
