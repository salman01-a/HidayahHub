class DoaItem {
  final int id;
  final String group;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final String reference;

  const DoaItem({
    required this.id,
    required this.group,
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.reference,
  });

  factory DoaItem.fromMap(Map<String, dynamic> map) {
    return DoaItem(
      id: map['id'] as int? ?? 0,
      group: map['grup'] as String? ?? 'Umum',
      title: map['nama'] as String? ?? 'Doa',
      arabic: map['ar'] as String? ?? '-',
      latin: map['tr'] as String? ?? '-',
      translation: map['idn'] as String? ?? '-',
      reference: map['tentang'] as String? ?? '-',
    );
  }
}
